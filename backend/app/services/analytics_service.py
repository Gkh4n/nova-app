import json
from sqlalchemy.orm import Session

from app.database.models.analytics_event import AnalyticsEvent


def log_event(db: Session, user_id: int | None, event_name: str, *, post_id: int | None = None, metadata: dict | None = None) -> None:
    db.add(
        AnalyticsEvent(
            user_id=user_id,
            event_name=event_name,
            post_id=post_id,
            metadata_json=json.dumps(metadata or {}, ensure_ascii=False)[:1000],
        )
    )
