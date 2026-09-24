from pydantic import BaseModel

from app.schemas.post import FeedPost
from app.schemas.user import UserPublic


class TopicResult(BaseModel):
    name: str
    post_count: int


class SearchResponse(BaseModel):
    users: list[UserPublic]
    posts: list[FeedPost]
    topics: list[TopicResult]
