from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.database.models.analytics_event import AnalyticsEvent
from app.database.models.bookmark import Bookmark
from app.database.models.identity_reveal import IdentityReveal
from app.database.models.post import Post
from app.database.models.reaction import Reaction
from app.database.models.user import User
from app.database.session import get_db
from app.schemas.analytics import AnalyticsEventCreate, AnalyticsSummary
from app.services.analytics_service import log_event

router = APIRouter(prefix="/analytics", tags=["analytics"])


@router.post("/event")
def event(payload: AnalyticsEventCreate, current_user: Annotated[User, Depends(get_current_user)], db: Annotated[Session, Depends(get_db)]):
    log_event(db, current_user.id, payload.event_name, post_id=payload.post_id, metadata=payload.metadata)
    db.commit()
    return {"logged": True}


@router.get("/me", response_model=AnalyticsSummary)
def summary(current_user: Annotated[User, Depends(get_current_user)], db: Annotated[Session, Depends(get_db)]):
    posts_created = int(db.scalar(select(func.count(Post.id)).where(Post.author_id == current_user.id)) or 0)
    reactions_received = int(db.scalar(select(func.count(Reaction.id)).join(Post, Reaction.post_id == Post.id).where(Post.author_id == current_user.id)) or 0)
    reveals_received = int(db.scalar(select(func.count(IdentityReveal.id)).join(Post, IdentityReveal.post_id == Post.id).where(Post.author_id == current_user.id)) or 0)
    saves_received = int(db.scalar(select(func.count(Bookmark.id)).join(Post, Bookmark.post_id == Post.id).where(Post.author_id == current_user.id)) or 0)
    profile_visits = int(db.scalar(select(func.count(AnalyticsEvent.id)).where(AnalyticsEvent.event_name == "profile_visit", AnalyticsEvent.metadata_json.contains(f'"target_user_id": {current_user.id}'))) or 0)
    return AnalyticsSummary(
        posts_created=posts_created,
        reactions_received=reactions_received,
        reveals_received=reveals_received,
        saves_received=saves_received,
        profile_visits=profile_visits,
    )
