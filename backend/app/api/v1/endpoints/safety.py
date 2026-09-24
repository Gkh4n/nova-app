from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import delete, or_, select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.database.models.block import Block
from app.database.models.follow import Follow
from app.database.models.report import Report
from app.database.models.user import User
from app.database.session import get_db
from app.schemas.safety import BlockState, ReportCreate, ReportResponse
from app.services.analytics_service import log_event

router = APIRouter(tags=["safety"])


@router.put("/users/{username}/block", response_model=BlockState)
def toggle_block(username: str, current_user: Annotated[User, Depends(get_current_user)], db: Annotated[Session, Depends(get_db)]):
    target = db.scalar(select(User).where(User.username == username.strip().lower(), User.is_active.is_(True)))
    if target is None:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
    if target.id == current_user.id:
        raise HTTPException(status_code=422, detail="Kendini engelleyemezsin")
    row = db.scalar(select(Block).where(Block.blocker_id == current_user.id, Block.blocked_id == target.id))
    if row is not None:
        db.delete(row)
        db.commit()
        return BlockState(username=target.username, blocked=False)
    db.add(Block(blocker_id=current_user.id, blocked_id=target.id))
    db.execute(delete(Follow).where(or_(
        (Follow.follower_id == current_user.id) & (Follow.followed_id == target.id),
        (Follow.follower_id == target.id) & (Follow.followed_id == current_user.id),
    )))
    log_event(db, current_user.id, "user_block", metadata={"target_user_id": target.id})
    db.commit()
    return BlockState(username=target.username, blocked=True)


@router.post("/reports", response_model=ReportResponse, status_code=status.HTTP_201_CREATED)
def report(payload: ReportCreate, current_user: Annotated[User, Depends(get_current_user)], db: Annotated[Session, Depends(get_db)]):
    row = Report(
        reporter_id=current_user.id,
        target_type=payload.target_type,
        target_id=payload.target_id,
        reason=payload.reason.strip(),
        details=payload.details.strip(),
    )
    db.add(row)
    db.flush()
    log_event(db, current_user.id, "report_create", metadata={"target_type": payload.target_type, "target_id": payload.target_id})
    db.commit()
    return ReportResponse(id=row.id, status=row.status)
