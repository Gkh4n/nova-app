from datetime import datetime, timezone

from sqlalchemy import DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base import Base


class IdentityReveal(Base):
    __tablename__ = "identity_reveals"
    __table_args__ = (UniqueConstraint("viewer_id", "post_id", name="uq_reveal_viewer_post"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    viewer_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    post_id: Mapped[int] = mapped_column(ForeignKey("posts.id", ondelete="CASCADE"), index=True)
    revealed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    post = relationship("Post", back_populates="reveals")
