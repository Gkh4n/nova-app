from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.algorithms.feed_ranker import rank_posts
from app.api.deps import get_current_user
from app.api.v1.endpoints.notifications import create_notification
from app.database.models.bookmark import Bookmark
from app.database.models.comment import Comment
from app.database.models.daily_question import DailyQuestion, DailyQuestionAnswer
from app.database.models.identity_reveal import IdentityReveal
from app.database.models.post import Post
from app.database.models.post_impression import PostImpression
from app.database.models.reaction import Reaction
from app.database.models.user import User
from app.database.session import get_db
from app.schemas.post import FeedPost, PostCreate, RevealResponse, SaveState
from app.schemas.reaction import ReactionCounts
from app.schemas.user import UserPublic
from app.services.analytics_service import log_event
from app.services.post_service import delete_post_graph
from app.services.safety_service import blocked_user_ids
from app.services.topic_service import post_topics, sync_post_topics

router = APIRouter(tags=["posts"])


def _reaction_counts(db: Session, post_id: int) -> ReactionCounts:
    rows = db.execute(
        select(Reaction.reaction_type, func.count(Reaction.id)).where(Reaction.post_id == post_id).group_by(Reaction.reaction_type)
    ).all()
    counts = {"felt": 0, "thought": 0, "funny": 0}
    for reaction_type, count in rows:
        if reaction_type in counts:
            counts[reaction_type] = int(count)
    return ReactionCounts(**counts)


def _question_text(db: Session, post_id: int) -> str | None:
    return db.scalar(
        select(DailyQuestion.text)
        .join(DailyQuestionAnswer, DailyQuestionAnswer.question_id == DailyQuestion.id)
        .where(DailyQuestionAnswer.post_id == post_id)
    )


def to_feed_post(db: Session, post: Post, viewer_id: int | None = None) -> FeedPost:
    reveal_count = int(db.scalar(select(func.count(IdentityReveal.id)).where(IdentityReveal.post_id == post.id)) or 0)
    comment_count = int(db.scalar(select(func.count(Comment.id)).where(Comment.post_id == post.id)) or 0)
    save_count = int(db.scalar(select(func.count(Bookmark.id)).where(Bookmark.post_id == post.id)) or 0)
    viewer_reaction = None
    saved = False
    if viewer_id is not None:
        viewer_reaction = db.scalar(select(Reaction.reaction_type).where(Reaction.post_id == post.id, Reaction.user_id == viewer_id))
        saved = db.scalar(select(Bookmark.id).where(Bookmark.post_id == post.id, Bookmark.user_id == viewer_id)) is not None
    is_mine = viewer_id is not None and viewer_id == post.author_id
    return FeedPost(
        id=post.id,
        content=post.content,
        is_anonymous=post.is_anonymous,
        is_mine=is_mine,
        can_reveal=not post.is_anonymous and not is_mine,
        created_at=post.created_at,
        reveal_count=reveal_count,
        reaction_counts=_reaction_counts(db, post.id),
        viewer_reaction=viewer_reaction,
        comment_count=comment_count,
        daily_question_text=_question_text(db, post.id),
        saved_by_me=saved,
        save_count=save_count,
        topics=post_topics(db, post.id),
    )


@router.get("/feed", response_model=list[FeedPost])
def feed(current_user: Annotated[User, Depends(get_current_user)], db: Annotated[Session, Depends(get_db)]):
    blocked = blocked_user_ids(db, current_user.id)
    query = select(Post).order_by(Post.created_at.desc()).limit(200)
    if blocked:
        query = query.where(Post.author_id.notin_(blocked))
    candidates = list(db.scalars(query).all())
    posts = rank_posts(db, candidates, current_user.id)[:50]
    for post in posts:
        exists = db.scalar(select(PostImpression.id).where(PostImpression.user_id == current_user.id, PostImpression.post_id == post.id))
        if exists is None:
            db.add(PostImpression(user_id=current_user.id, post_id=post.id))
    log_event(db, current_user.id, "feed_open", metadata={"count": len(posts)})
    db.commit()
    return [to_feed_post(db, post, current_user.id) for post in posts]


@router.post("/posts", response_model=FeedPost, status_code=status.HTTP_201_CREATED)
def create_post(payload: PostCreate, current_user: Annotated[User, Depends(get_current_user)], db: Annotated[Session, Depends(get_db)]):
    content = payload.content.strip()
    if not content:
        raise HTTPException(status_code=422, detail="İçerik boş olamaz")
    post = Post(author_id=current_user.id, content=content, is_anonymous=payload.is_anonymous)
    db.add(post)
    db.flush()
    sync_post_topics(db, post.id, content)
    log_event(db, current_user.id, "post_create", post_id=post.id, metadata={"anonymous": payload.is_anonymous})
    db.commit()
    db.refresh(post)
    return to_feed_post(db, post, current_user.id)


@router.delete("/posts/{post_id}")
def delete_post(post_id: int, current_user: Annotated[User, Depends(get_current_user)], db: Annotated[Session, Depends(get_db)]):
    post = db.get(Post, post_id)
    if post is None:
        raise HTTPException(status_code=404, detail="Paylaşım bulunamadı")
    if post.author_id != current_user.id:
        raise HTTPException(status_code=403, detail="Bu paylaşımı yalnızca sahibi silebilir")
    delete_post_graph(db, post)
    db.commit()
    return {"deleted": True, "post_id": post_id}


@router.post("/posts/{post_id}/reveal", response_model=RevealResponse)
def reveal_post_author(post_id: int, current_user: Annotated[User, Depends(get_current_user)], db: Annotated[Session, Depends(get_db)]):
    post = db.get(Post, post_id)
    if post is None:
        raise HTTPException(status_code=404, detail="Paylaşım bulunamadı")
    if post.author_id in blocked_user_ids(db, current_user.id):
        raise HTTPException(status_code=404, detail="Paylaşım bulunamadı")
    if post.is_anonymous:
        return RevealResponse(post_id=post.id, anonymous=True, author=None)
    reveal = db.scalar(select(IdentityReveal).where(IdentityReveal.viewer_id == current_user.id, IdentityReveal.post_id == post.id))
    if reveal is None and current_user.id != post.author_id:
        db.add(IdentityReveal(viewer_id=current_user.id, post_id=post.id))
        create_notification(db, recipient_id=post.author_id, actor_id=current_user.id, post_id=post.id, kind="reveal")
        log_event(db, current_user.id, "identity_reveal", post_id=post.id)
        db.commit()
    author = db.get(User, post.author_id)
    return RevealResponse(post_id=post.id, anonymous=False, author=UserPublic.model_validate(author) if author else None)


@router.put("/posts/{post_id}/save", response_model=SaveState)
def toggle_save(post_id: int, current_user: Annotated[User, Depends(get_current_user)], db: Annotated[Session, Depends(get_db)]):
    post = db.get(Post, post_id)
    if post is None or post.author_id in blocked_user_ids(db, current_user.id):
        raise HTTPException(status_code=404, detail="Paylaşım bulunamadı")
    row = db.scalar(select(Bookmark).where(Bookmark.user_id == current_user.id, Bookmark.post_id == post.id))
    if row is None:
        db.add(Bookmark(user_id=current_user.id, post_id=post.id))
        saved = True
        log_event(db, current_user.id, "post_save", post_id=post.id)
    else:
        db.delete(row)
        saved = False
    db.commit()
    count = int(db.scalar(select(func.count(Bookmark.id)).where(Bookmark.post_id == post.id)) or 0)
    return SaveState(post_id=post.id, saved=saved, save_count=count)


@router.get("/users/me/saved", response_model=list[FeedPost])
def saved_posts(current_user: Annotated[User, Depends(get_current_user)], db: Annotated[Session, Depends(get_db)]):
    blocked = blocked_user_ids(db, current_user.id)
    query = select(Post).join(Bookmark, Bookmark.post_id == Post.id).where(Bookmark.user_id == current_user.id).order_by(Bookmark.created_at.desc())
    if blocked:
        query = query.where(Post.author_id.notin_(blocked))
    return [to_feed_post(db, p, current_user.id) for p in db.scalars(query.limit(100)).all()]
