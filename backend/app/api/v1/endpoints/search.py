from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.api.v1.endpoints.posts import to_feed_post
from app.database.models.post import Post
from app.database.models.topic import PostTopic, Topic
from app.database.models.user import User
from app.database.session import get_db
from app.schemas.search import SearchResponse, TopicResult
from app.schemas.user import UserPublic
from app.services.analytics_service import log_event
from app.services.safety_service import blocked_user_ids

router = APIRouter(tags=["search"])


@router.get("/search", response_model=SearchResponse)
def search(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    q: str = Query(min_length=1, max_length=80),
):
    term = q.strip().lower()
    blocked = blocked_user_ids(db, current_user.id)
    user_query = select(User).where(User.is_active.is_(True), or_(func.lower(User.username).contains(term), func.lower(User.display_name).contains(term)))
    if blocked:
        user_query = user_query.where(User.id.notin_(blocked))
    users = list(db.scalars(user_query.order_by(User.username.asc()).limit(12)).all())

    post_query = select(Post).where(func.lower(Post.content).contains(term))
    if blocked:
        post_query = post_query.where(Post.author_id.notin_(blocked))
    posts = list(db.scalars(post_query.order_by(Post.created_at.desc()).limit(20)).all())

    topic_rows = db.execute(
        select(Topic.name, func.count(PostTopic.id))
        .join(PostTopic, PostTopic.topic_id == Topic.id)
        .where(func.lower(Topic.name).contains(term))
        .group_by(Topic.id, Topic.name)
        .order_by(func.count(PostTopic.id).desc())
        .limit(12)
    ).all()
    log_event(db, current_user.id, "search", metadata={"query": term[:80]})
    db.commit()
    return SearchResponse(
        users=[UserPublic.model_validate(u) for u in users],
        posts=[to_feed_post(db, p, current_user.id) for p in posts],
        topics=[TopicResult(name=name, post_count=int(count)) for name, count in topic_rows],
    )
