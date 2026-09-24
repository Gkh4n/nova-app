from pydantic import BaseModel, Field


class AnalyticsEventCreate(BaseModel):
    event_name: str = Field(min_length=2, max_length=64)
    post_id: int | None = None
    metadata: dict[str, str | int | float | bool | None] = {}


class AnalyticsSummary(BaseModel):
    posts_created: int
    reactions_received: int
    reveals_received: int
    saves_received: int
    profile_visits: int
