from pydantic import BaseModel


class FollowState(BaseModel):
    username: str
    following: bool
