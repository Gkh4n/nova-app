from datetime import date

from pydantic import BaseModel, Field

from app.schemas.post import FeedPost


class DailyQuestionPublic(BaseModel):
    id: int
    question_date: date
    text: str
    answer_count: int
    answered_by_me: bool


class DailyQuestionAnswerCreate(BaseModel):
    content: str = Field(min_length=1, max_length=500)
    is_anonymous: bool = False


class DailyQuestionAnswerResponse(BaseModel):
    question: DailyQuestionPublic
    post: FeedPost
