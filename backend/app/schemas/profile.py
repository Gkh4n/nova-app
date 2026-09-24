from datetime import datetime

from pydantic import BaseModel


class ProfilePost(BaseModel):
    id: int
    content: str
    is_anonymous: bool
    created_at: datetime
    reaction_count: int
    comment_count: int
    save_count: int = 0


class UserProfile(BaseModel):
    id: int
    username: str
    display_name: str
    bio: str
    created_at: datetime
    post_count: int
    reactions_received: int
    followed_by_me: bool
    blocked_by_me: bool = False
    is_me: bool
    recent_posts: list[ProfilePost]
