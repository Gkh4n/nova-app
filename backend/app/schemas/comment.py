from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.user import UserPublic


class CommentCreate(BaseModel):
    content: str = Field(min_length=1, max_length=500)
    parent_id: int | None = None


class CommentPublic(BaseModel):
    id: int
    post_id: int
    content: str
    parent_id: int | None
    created_at: datetime
    author: UserPublic
    like_count: int
    liked_by_me: bool
