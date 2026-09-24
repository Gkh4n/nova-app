from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.reaction import ReactionCounts, ReactionType
from app.schemas.user import UserPublic


class PostCreate(BaseModel):
    content: str = Field(min_length=1, max_length=500)
    is_anonymous: bool = False


class FeedPost(BaseModel):
    id: int
    content: str
    is_anonymous: bool
    is_mine: bool
    can_reveal: bool
    created_at: datetime
    reveal_count: int
    reaction_counts: ReactionCounts
    viewer_reaction: ReactionType | None = None
    comment_count: int
    daily_question_text: str | None = None
    saved_by_me: bool = False
    save_count: int = 0
    topics: list[str] = []


class RevealResponse(BaseModel):
    post_id: int
    anonymous: bool
    author: UserPublic | None = None


class SaveState(BaseModel):
    post_id: int
    saved: bool
    save_count: int
