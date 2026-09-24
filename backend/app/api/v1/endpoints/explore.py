from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.algorithms.feed_ranker import rank_posts
from app.api.deps import get_current_user
from app.api.v1.endpoints.posts import to_feed_post
from app.database.models.comment import Comment
from app.database.models.post import Post
from app.database.models.reaction import Reaction
from app.database.models.user import User
from app.database.session import get_db
from app.schemas.explore import ExploreResponse
from app.services.safety_service import blocked_user_ids

router = APIRouter(tags=["explore"])


@router.get("/explore", response_model=ExploreResponse)
def explore(current_user: Annotated[User, Depends(get_current_user)], db: Annotated[Session, Depends(get_db)]):
    blocked = blocked_user_ids(db, current_user.id)
    query = select(Post).order_by(Post.created_at.desc()).limit(200)
    if blocked: query = query.where(Post.author_id.notin_(blocked))
    posts = list(db.scalars(query).all())
    trending = rank_posts(db, posts, current_user.id)[:20]
    thoughtful = sorted(posts, key=lambda p: int(db.scalar(select(func.count(Reaction.id)).where(Reaction.post_id == p.id, Reaction.reaction_type == "thought")) or 0), reverse=True)[:20]
    discussed = sorted(posts, key=lambda p: int(db.scalar(select(func.count(Comment.id)).where(Comment.post_id == p.id)) or 0), reverse=True)[:20]
    fresh = posts[:20]
    return ExploreResponse(
        trending=[to_feed_post(db, p, current_user.id) for p in trending],
        thoughtful=[to_feed_post(db, p, current_user.id) for p in thoughtful],
        discussed=[to_feed_post(db, p, current_user.id) for p in discussed],
        fresh=[to_feed_post(db, p, current_user.id) for p in fresh],
    )
