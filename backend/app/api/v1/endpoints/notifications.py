from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.database.models.notification import Notification
from app.database.models.user import User
from app.database.session import get_db
from app.schemas.notification import NotificationPublic
from app.schemas.user import UserPublic
from app.services.safety_service import blocked_user_ids

router = APIRouter(prefix="/notifications", tags=["notifications"])


def create_notification(db: Session, *, recipient_id: int, kind: str, actor_id: int | None = None, post_id: int | None = None) -> None:
    if actor_id is not None and actor_id == recipient_id:
        return
    db.add(Notification(recipient_id=recipient_id, actor_id=actor_id, post_id=post_id, kind=kind))


def _message(kind: str, actor: User | None) -> str:
    name = f"@{actor.username}" if actor is not None else "Birisi"
    return {
        "reaction": f"{name} düşüncene tepki verdi.",
        "comment": f"{name} düşüncene yorum yaptı.",
        "reply": f"{name} yorumuna yanıt verdi.",
        "reveal": f"{name} düşüncenin sahibini merak etti.",
        "follow": f"{name} seni takip etmeye başladı.",
        "save": f"{name} düşünceni kaydetti.",
    }.get(kind, "NOVA'da yeni bir etkileşimin var.")


@router.get("", response_model=list[NotificationPublic])
def list_notifications(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    blocked = blocked_user_ids(db, current_user.id)
    rows = db.scalars(
        select(Notification)
        .where(Notification.recipient_id == current_user.id)
        .order_by(Notification.created_at.desc())
        .limit(60)
    ).all()
    result: list[NotificationPublic] = []
    for row in rows:
        if row.actor_id in blocked:
            continue
        actor = db.get(User, row.actor_id) if row.actor_id else None
        result.append(
            NotificationPublic(
                id=row.id,
                kind=row.kind,
                message=_message(row.kind, actor),
                is_read=row.is_read,
                created_at=row.created_at,
                post_id=row.post_id,
                actor=UserPublic.model_validate(actor) if actor else None,
            )
        )
    return result


@router.put("/read-all")
def mark_all_read(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    db.execute(
        update(Notification)
        .where(Notification.recipient_id == current_user.id)
        .values(is_read=True)
    )
    db.commit()
    return {"updated": True}


@router.put("/{notification_id}/read", response_model=NotificationPublic)
def mark_read(
    notification_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    row = db.get(Notification, notification_id)
    if row is None or row.recipient_id != current_user.id:
        raise HTTPException(status_code=404, detail="Bildirim bulunamadı")
    row.is_read = True
    db.commit()
    db.refresh(row)
    actor = db.get(User, row.actor_id) if row.actor_id else None
    return NotificationPublic(
        id=row.id,
        kind=row.kind,
        message=_message(row.kind, actor),
        is_read=row.is_read,
        created_at=row.created_at,
        post_id=row.post_id,
        actor=UserPublic.model_validate(actor) if actor else None,
    )
