from dataclasses import dataclass
from datetime import datetime, timezone

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.database.models.bookmark import Bookmark
from app.database.models.comment import Comment
from app.database.models.follow import Follow
from app.database.models.identity_reveal import IdentityReveal
from app.database.models.post import Post
from app.database.models.post_impression import PostImpression
from app.database.models.reaction import Reaction


@dataclass(frozen=True)
class RankSignals:
    felt: int
    thought: int
    funny: int
    comments: int
    reveals: int
    saves: int
    impressions: int
    seen_by_viewer: bool
    follows_author: bool
    age_hours: float


def signals_for(db: Session, post: Post, viewer_id: int) -> RankSignals:
    reaction_rows = db.execute(
        select(Reaction.reaction_type, func.count(Reaction.id))
        .where(Reaction.post_id == post.id)
        .group_by(Reaction.reaction_type)
    ).all()
    counts = {"felt": 0, "thought": 0, "funny": 0}
    for kind, count in reaction_rows:
        if kind in counts:
            counts[kind] = int(count)
    comments = int(db.scalar(select(func.count(Comment.id)).where(Comment.post_id == post.id)) or 0)
    reveals = int(db.scalar(select(func.count(IdentityReveal.id)).where(IdentityReveal.post_id == post.id)) or 0)
    saves = int(db.scalar(select(func.count(Bookmark.id)).where(Bookmark.post_id == post.id)) or 0)
    impressions = int(db.scalar(select(func.count(PostImpression.id)).where(PostImpression.post_id == post.id)) or 0)
    seen = db.scalar(select(PostImpression.id).where(PostImpression.post_id == post.id, PostImpression.user_id == viewer_id)) is not None
    follows = db.scalar(select(Follow.id).where(Follow.follower_id == viewer_id, Follow.followed_id == post.author_id)) is not None
    created = post.created_at
    if created.tzinfo is None:
        created = created.replace(tzinfo=timezone.utc)
    age_hours = max(0.0, (datetime.now(timezone.utc) - created).total_seconds() / 3600.0)
    return RankSignals(counts["felt"], counts["thought"], counts["funny"], comments, reveals, saves, impressions, seen, follows, age_hours)


def score(post: Post, s: RankSignals, viewer_id: int) -> float:
    engagement = s.felt * 1.0 + s.thought * 2.0 + s.funny * 1.25 + s.comments * 2.5 + s.reveals * 1.5 + s.saves * 2.0
    freshness = max(0.0, 12.0 - s.age_hours / 6.0)
    # NOVA fairness: every post gets a meaningful boost until it has been tested on ~50 unique feeds.
    fairness = max(0.0, 18.0 * (1.0 - min(s.impressions, 50) / 50.0))
    unseen = 9.0 if not s.seen_by_viewer else -4.0
    following = 1.5 if s.follows_author else 0.0
    mine = -1.0 if post.author_id == viewer_id else 0.0
    stable_jitter = ((post.id * 31 + viewer_id * 17) % 100) / 100.0
    return engagement + freshness + fairness + unseen + following + mine + stable_jitter


def rank_posts(db: Session, posts: list[Post], viewer_id: int) -> list[Post]:
    ranked = [(score(post, signals_for(db, post, viewer_id), viewer_id), post) for post in posts]
    ranked.sort(key=lambda pair: pair[0], reverse=True)
    return [post for _, post in ranked]
