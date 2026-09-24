from pydantic import BaseModel

from app.schemas.post import FeedPost


class ExploreResponse(BaseModel):
    trending: list[FeedPost]
    thoughtful: list[FeedPost]
    discussed: list[FeedPost]
    fresh: list[FeedPost]
