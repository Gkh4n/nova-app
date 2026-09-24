from datetime import datetime

from pydantic import BaseModel

from app.schemas.user import UserPublic


class NotificationPublic(BaseModel):
    id: int
    kind: str
    message: str
    is_read: bool
    created_at: datetime
    post_id: int | None = None
    actor: UserPublic | None = None
