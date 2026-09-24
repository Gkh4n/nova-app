from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.database.models.analytics_event import AnalyticsEvent
from app.database.models.bookmark import Bookmark
from app.database.models.comment import Comment
from app.database.models.comment_like import CommentLike
from app.database.models.daily_question import DailyQuestionAnswer
from app.database.models.identity_reveal import IdentityReveal
from app.database.models.notification import Notification
from app.database.models.post import Post
from app.database.models.post_impression import PostImpression
from app.database.models.reaction import Reaction
from app.database.models.topic import PostTopic


def delete_post_graph(db: Session, post: Post) -> None:
    comment_ids = list(db.scalars(select(Comment.id).where(Comment.post_id == post.id)).all())
    if comment_ids:
        db.execute(delete(CommentLike).where(CommentLike.comment_id.in_(comment_ids)))
    db.execute(delete(Comment).where(Comment.post_id == post.id))
    db.execute(delete(Reaction).where(Reaction.post_id == post.id))
    db.execute(delete(IdentityReveal).where(IdentityReveal.post_id == post.id))
    db.execute(delete(DailyQuestionAnswer).where(DailyQuestionAnswer.post_id == post.id))
    db.execute(delete(Notification).where(Notification.post_id == post.id))
    db.execute(delete(Bookmark).where(Bookmark.post_id == post.id))
    db.execute(delete(PostImpression).where(PostImpression.post_id == post.id))
    db.execute(delete(PostTopic).where(PostTopic.post_id == post.id))
    db.execute(delete(AnalyticsEvent).where(AnalyticsEvent.post_id == post.id))
    db.delete(post)
