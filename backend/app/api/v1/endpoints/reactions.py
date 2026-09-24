from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.api.v1.endpoints.notifications import create_notification
from app.api.v1.endpoints.posts import _reaction_counts
from app.database.models.post import Post
from app.database.models.reaction import Reaction
from app.database.models.user import User
from app.database.session import get_db
from app.schemas.reaction import ReactionRequest, ReactionSummary

router = APIRouter(tags=["reactions"])


@router.put("/posts/{post_id}/reaction", response_model=ReactionSummary)
def set_reaction(
    post_id: int,
    payload: ReactionRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    post = db.get(Post, post_id)
    if post is None:
        raise HTTPException(status_code=404, detail="Paylaşım bulunamadı")

    reaction = db.scalar(
        select(Reaction).where(Reaction.user_id == current_user.id, Reaction.post_id == post_id)
    )
    if reaction is None:
        reaction = Reaction(user_id=current_user.id, post_id=post_id, reaction_type=payload.reaction_type)
        db.add(reaction)
        create_notification(
            db,
            recipient_id=post.author_id,
            actor_id=current_user.id,
            post_id=post.id,
            kind="reaction",
        )
    elif reaction.reaction_type == payload.reaction_type:
        db.delete(reaction)
        db.commit()
        return ReactionSummary(counts=_reaction_counts(db, post_id), viewer_reaction=None)
    else:
        reaction.reaction_type = payload.reaction_type

    db.commit()
    return ReactionSummary(counts=_reaction_counts(db, post_id), viewer_reaction=payload.reaction_type)
