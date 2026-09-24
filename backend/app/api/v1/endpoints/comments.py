from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.api.v1.endpoints.notifications import create_notification
from app.database.models.comment import Comment
from app.database.models.comment_like import CommentLike
from app.database.models.post import Post
from app.database.models.user import User
from app.database.session import get_db
from app.schemas.comment import CommentCreate, CommentPublic
from app.schemas.user import UserPublic
from app.services.safety_service import blocked_user_ids

router = APIRouter(tags=["comments"])


def _to_public(db: Session, comment: Comment, viewer_id: int) -> CommentPublic:
    author = db.get(User, comment.author_id)
    if author is None:
        raise HTTPException(status_code=404, detail="Yorum yazarı bulunamadı")
    like_count = int(db.scalar(select(func.count(CommentLike.id)).where(CommentLike.comment_id == comment.id)) or 0)
    liked = db.scalar(select(CommentLike.id).where(CommentLike.comment_id == comment.id, CommentLike.user_id == viewer_id)) is not None
    return CommentPublic(id=comment.id, post_id=comment.post_id, content=comment.content, parent_id=comment.parent_id, created_at=comment.created_at, author=UserPublic.model_validate(author), like_count=like_count, liked_by_me=liked)


@router.get("/posts/{post_id}/comments", response_model=list[CommentPublic])
def list_comments(post_id: int, current_user: Annotated[User, Depends(get_current_user)], db: Annotated[Session, Depends(get_db)]):
    if db.get(Post, post_id) is None:
        raise HTTPException(status_code=404, detail="Paylaşım bulunamadı")
    blocked = blocked_user_ids(db, current_user.id)
    query = select(Comment).where(Comment.post_id == post_id)
    if blocked:
        query = query.where(Comment.author_id.notin_(blocked))
    comments = db.scalars(query.order_by(Comment.created_at.asc())).all()
    return [_to_public(db, comment, current_user.id) for comment in comments]


@router.post("/posts/{post_id}/comments", response_model=CommentPublic, status_code=status.HTTP_201_CREATED)
def create_comment(post_id: int, payload: CommentCreate, current_user: Annotated[User, Depends(get_current_user)], db: Annotated[Session, Depends(get_db)]):
    post = db.get(Post, post_id)
    if post is None or post.author_id in blocked_user_ids(db, current_user.id):
        raise HTTPException(status_code=404, detail="Paylaşım bulunamadı")
    content = payload.content.strip()
    if not content:
        raise HTTPException(status_code=422, detail="Yorum boş olamaz")
    recipient_id = post.author_id; kind = "comment"
    if payload.parent_id is not None:
        parent = db.get(Comment, payload.parent_id)
        if parent is None or parent.post_id != post_id:
            raise HTTPException(status_code=404, detail="Yanıtlanan yorum bulunamadı")
        if parent.parent_id is not None:
            raise HTTPException(status_code=422, detail="Yalnızca tek seviyeli yanıt destekleniyor")
        recipient_id = parent.author_id; kind = "reply"
    comment = Comment(post_id=post_id, author_id=current_user.id, parent_id=payload.parent_id, content=content)
    db.add(comment); db.flush()
    create_notification(db, recipient_id=recipient_id, actor_id=current_user.id, post_id=post.id, kind=kind)
    db.commit(); db.refresh(comment)
    return _to_public(db, comment, current_user.id)


@router.put("/comments/{comment_id}/like", response_model=CommentPublic)
def toggle_comment_like(comment_id: int, current_user: Annotated[User, Depends(get_current_user)], db: Annotated[Session, Depends(get_db)]):
    comment = db.get(Comment, comment_id)
    if comment is None or comment.author_id in blocked_user_ids(db, current_user.id):
        raise HTTPException(status_code=404, detail="Yorum bulunamadı")
    like = db.scalar(select(CommentLike).where(CommentLike.comment_id == comment_id, CommentLike.user_id == current_user.id))
    if like is None: db.add(CommentLike(comment_id=comment_id, user_id=current_user.id))
    else: db.delete(like)
    db.commit(); return _to_public(db, comment, current_user.id)
