from datetime import date, datetime, timezone

from sqlalchemy import Date, DateTime, ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.database.base import Base


class DailyQuestion(Base):
    __tablename__ = "daily_questions"

    id: Mapped[int] = mapped_column(primary_key=True)
    question_date: Mapped[date] = mapped_column(Date, unique=True, index=True)
    text: Mapped[str] = mapped_column(String(280))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )


class DailyQuestionAnswer(Base):
    __tablename__ = "daily_question_answers"
    __table_args__ = (
        UniqueConstraint("question_id", "user_id", name="uq_daily_question_user"),
        UniqueConstraint("post_id", name="uq_daily_question_post"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    question_id: Mapped[int] = mapped_column(
        ForeignKey("daily_questions.id", ondelete="CASCADE"), index=True
    )
    post_id: Mapped[int] = mapped_column(ForeignKey("posts.id", ondelete="CASCADE"), index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
