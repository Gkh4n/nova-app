from typing import Literal

from pydantic import BaseModel

ReactionType = Literal["felt", "thought", "funny"]


class ReactionRequest(BaseModel):
    reaction_type: ReactionType


class ReactionCounts(BaseModel):
    felt: int = 0
    thought: int = 0
    funny: int = 0


class ReactionSummary(BaseModel):
    counts: ReactionCounts
    viewer_reaction: ReactionType | None = None
