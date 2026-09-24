from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.api.v1.endpoints.notifications import create_notification
from app.database.models.block import Block
from app.database.models.follow import Follow
from app.database.models.user import User
from app.database.session import get_db
from app.schemas.follow import FollowState

router = APIRouter(prefix="/users", tags=["follows"])


@router.put("/{username}/follow", response_model=FollowState)
def toggle_follow(username: str, current_user: Annotated[User, Depends(get_current_user)], db: Annotated[Session, Depends(get_db)]):
    target = db.scalar(select(User).where(User.username == username.strip().lower(), User.is_active.is_(True)))
    if target is None:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
    if target.id == current_user.id:
        raise HTTPException(status_code=422, detail="Kendini takip edemezsin")
    any_block = db.scalar(select(Block.id).where(((Block.blocker_id == current_user.id) & (Block.blocked_id == target.id)) | ((Block.blocker_id == target.id) & (Block.blocked_id == current_user.id))))
    if any_block is not None:
        raise HTTPException(status_code=422, detail="Engellenmiş kullanıcıyla takip ilişkisi kurulamaz")
    existing = db.scalar(select(Follow).where(Follow.follower_id == current_user.id, Follow.followed_id == target.id))
    if existing is not None:
        db.delete(existing); db.commit(); return FollowState(username=target.username, following=False)
    db.add(Follow(follower_id=current_user.id, followed_id=target.id))
    create_notification(db, recipient_id=target.id, actor_id=current_user.id, kind="follow")
    db.commit()
    return FollowState(username=target.username, following=True)
