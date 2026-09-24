from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import delete, func, or_, select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.database.models.analytics_event import AnalyticsEvent
from app.database.models.block import Block
from app.database.models.bookmark import Bookmark
from app.database.models.comment import Comment
from app.database.models.comment_like import CommentLike
from app.database.models.daily_question import DailyQuestionAnswer
from app.database.models.follow import Follow
from app.database.models.identity_reveal import IdentityReveal
from app.database.models.notification import Notification
from app.database.models.password_reset import PasswordReset
from app.database.models.post import Post
from app.database.models.post_impression import PostImpression
from app.database.models.reaction import Reaction
from app.database.models.report import Report
from app.database.models.user import User
from app.database.session import get_db
from app.schemas.profile import ProfilePost, UserProfile
from app.schemas.user import ProfileUpdate, UserMe
from app.services.analytics_service import log_event
from app.services.post_service import delete_post_graph
from app.services.safety_service import blocked_by_me

router = APIRouter(prefix="/users", tags=["users"])


@router.patch("/me", response_model=UserMe)
def update_me(payload: ProfileUpdate, current_user: Annotated[User, Depends(get_current_user)], db: Annotated[Session, Depends(get_db)]):
    if payload.display_name is not None:
        display_name = payload.display_name.strip()
        if not display_name:
            raise HTTPException(status_code=422, detail="Görünen ad boş olamaz")
        current_user.display_name = display_name
    if payload.bio is not None:
        current_user.bio = payload.bio.strip()
    db.add(current_user)
    db.commit()
    db.refresh(current_user)
    return current_user


@router.delete("/me")
def delete_my_account(current_user: Annotated[User, Depends(get_current_user)], db: Annotated[Session, Depends(get_db)]):
    user_id = current_user.id
    posts = list(db.scalars(select(Post).where(Post.author_id == user_id)).all())
    for post in posts:
        delete_post_graph(db, post)
    authored_comment_ids = list(db.scalars(select(Comment.id).where(Comment.author_id == user_id)).all())
    if authored_comment_ids:
        db.execute(delete(CommentLike).where(CommentLike.comment_id.in_(authored_comment_ids)))
    db.execute(delete(CommentLike).where(CommentLike.user_id == user_id))
    db.execute(delete(Comment).where(Comment.author_id == user_id))
    db.execute(delete(Reaction).where(Reaction.user_id == user_id))
    db.execute(delete(IdentityReveal).where(IdentityReveal.viewer_id == user_id))
    db.execute(delete(DailyQuestionAnswer).where(DailyQuestionAnswer.user_id == user_id))
    db.execute(delete(Follow).where(or_(Follow.follower_id == user_id, Follow.followed_id == user_id)))
    db.execute(delete(Notification).where(or_(Notification.recipient_id == user_id, Notification.actor_id == user_id)))
    db.execute(delete(Bookmark).where(Bookmark.user_id == user_id))
    db.execute(delete(Block).where(or_(Block.blocker_id == user_id, Block.blocked_id == user_id)))
    db.execute(delete(Report).where(Report.reporter_id == user_id))
    db.execute(delete(PostImpression).where(PostImpression.user_id == user_id))
    db.execute(delete(AnalyticsEvent).where(AnalyticsEvent.user_id == user_id))
    db.execute(delete(PasswordReset).where(PasswordReset.user_id == user_id))
    db.delete(current_user)
    db.commit()
    return {"deleted": True}


@router.get("/{username}", response_model=UserProfile)
def profile(username: str, current_user: Annotated[User, Depends(get_current_user)], db: Annotated[Session, Depends(get_db)]):
    user = db.scalar(select(User).where(User.username == username.strip().lower(), User.is_active.is_(True)))
    if user is None:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
    blocked_by_target = db.scalar(select(Block.id).where(Block.blocker_id == user.id, Block.blocked_id == current_user.id)) is not None
    if blocked_by_target:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")

    is_me = current_user.id == user.id
    visibility_filter = True if is_me else Post.is_anonymous.is_(False)
    post_count = int(db.scalar(select(func.count(Post.id)).where(Post.author_id == user.id, visibility_filter)) or 0)
    reactions_received = int(db.scalar(select(func.count(Reaction.id)).join(Post, Reaction.post_id == Post.id).where(Post.author_id == user.id, visibility_filter)) or 0)
    followed_by_me = False
    if not is_me:
        followed_by_me = db.scalar(select(Follow.id).where(Follow.follower_id == current_user.id, Follow.followed_id == user.id)) is not None
        log_event(db, current_user.id, "profile_visit", metadata={"target_user_id": user.id})

    post_query = select(Post).where(Post.author_id == user.id)
    if not is_me:
        post_query = post_query.where(Post.is_anonymous.is_(False))
    posts = db.scalars(post_query.order_by(Post.created_at.desc()).limit(50)).all()
    recent_posts: list[ProfilePost] = []
    for post in posts:
        reaction_count = int(db.scalar(select(func.count(Reaction.id)).where(Reaction.post_id == post.id)) or 0)
        comment_count = int(db.scalar(select(func.count(Comment.id)).where(Comment.post_id == post.id)) or 0)
        save_count = int(db.scalar(select(func.count(Bookmark.id)).where(Bookmark.post_id == post.id)) or 0)
        recent_posts.append(ProfilePost(id=post.id, content=post.content, is_anonymous=post.is_anonymous, created_at=post.created_at, reaction_count=reaction_count, comment_count=comment_count, save_count=save_count))
    db.commit()
    return UserProfile(
        id=user.id,
        username=user.username,
        display_name=user.display_name,
        bio=user.bio or "",
        created_at=user.created_at,
        post_count=post_count,
        reactions_received=reactions_received,
        followed_by_me=followed_by_me,
        blocked_by_me=blocked_by_me(db, current_user.id, user.id) if not is_me else False,
        is_me=is_me,
        recent_posts=recent_posts,
    )
