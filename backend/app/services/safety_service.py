from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.database.models.block import Block


def blocked_user_ids(db: Session, user_id: int) -> set[int]:
    rows = db.execute(
        select(Block.blocker_id, Block.blocked_id).where(
            or_(Block.blocker_id == user_id, Block.blocked_id == user_id)
        )
    ).all()
    result: set[int] = set()
    for blocker_id, blocked_id in rows:
        result.add(blocked_id if blocker_id == user_id else blocker_id)
    return result


def blocked_by_me(db: Session, user_id: int, other_id: int) -> bool:
    return db.scalar(
        select(Block.id).where(Block.blocker_id == user_id, Block.blocked_id == other_id)
    ) is not None
