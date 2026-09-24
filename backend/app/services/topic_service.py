import re
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.database.models.topic import PostTopic, Topic

_HASHTAG = re.compile(r"(?<!\w)#([\wçğıöşüÇĞİÖŞÜ]{2,40})", re.UNICODE)


def extract_topics(content: str) -> list[str]:
    result: list[str] = []
    for raw in _HASHTAG.findall(content):
        name = raw.lower().strip("_")
        if name and name not in result:
            result.append(name)
    return result[:5]


def sync_post_topics(db: Session, post_id: int, content: str) -> None:
    names = extract_topics(content)
    for name in names:
        topic = db.scalar(select(Topic).where(Topic.name == name))
        if topic is None:
            topic = Topic(name=name)
            db.add(topic)
            db.flush()
        existing = db.scalar(
            select(PostTopic.id).where(PostTopic.post_id == post_id, PostTopic.topic_id == topic.id)
        )
        if existing is None:
            db.add(PostTopic(post_id=post_id, topic_id=topic.id))


def post_topics(db: Session, post_id: int) -> list[str]:
    return list(
        db.scalars(
            select(Topic.name)
            .join(PostTopic, PostTopic.topic_id == Topic.id)
            .where(PostTopic.post_id == post_id)
            .order_by(Topic.name.asc())
        ).all()
    )


def top_topics(db: Session, limit: int = 10) -> list[tuple[str, int]]:
    return [
        (name, int(count))
        for name, count in db.execute(
            select(Topic.name, func.count(PostTopic.id))
            .join(PostTopic, PostTopic.topic_id == Topic.id)
            .group_by(Topic.id, Topic.name)
            .order_by(func.count(PostTopic.id).desc(), Topic.name.asc())
            .limit(limit)
        ).all()
    ]
