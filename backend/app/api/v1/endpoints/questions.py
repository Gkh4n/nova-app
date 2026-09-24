from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.api.v1.endpoints.posts import to_feed_post
from app.database.models.daily_question import DailyQuestion, DailyQuestionAnswer
from app.database.models.post import Post
from app.database.models.user import User
from app.database.session import get_db
from app.schemas.question import (
    DailyQuestionAnswerCreate,
    DailyQuestionAnswerResponse,
    DailyQuestionPublic,
)

router = APIRouter(prefix="/questions", tags=["daily-question"])

QUESTIONS = [
    "Hayatında yeniden yaşamak istediğin bir gün var mı?",
    "İnsanların senin hakkında yanlış bildiği bir şey ne?",
    "Bugün her şeyi bırakıp gidebilseydin nereye giderdin?",
    "Geçmişteki kendine tek cümle söyleyebilseydin ne derdin?",
    "Sence bir insanı gerçekten tanımak ne kadar sürer?",
    "Hayatında verdiğin en iyi karar neydi?",
    "Kimse yargılamayacak olsa neyi açıkça söylerdin?",
    "Büyüdükçe fikrinin tamamen değiştiği bir konu ne?",
    "Şu an hayatında en çok neyin eksikliğini hissediyorsun?",
    "Birine teşekkür etmek isteyip hiç edemediğin oldu mu?",
]


def _today_question(db: Session) -> DailyQuestion:
    today = date.today()
    question = db.scalar(select(DailyQuestion).where(DailyQuestion.question_date == today))
    if question is not None:
        return question

    text = QUESTIONS[today.toordinal() % len(QUESTIONS)]
    question = DailyQuestion(question_date=today, text=text)
    db.add(question)
    try:
        db.commit()
        db.refresh(question)
        return question
    except IntegrityError:
        db.rollback()
        question = db.scalar(select(DailyQuestion).where(DailyQuestion.question_date == today))
        if question is None:
            raise
        return question


def _to_public(db: Session, question: DailyQuestion, user_id: int) -> DailyQuestionPublic:
    answer_count = db.scalar(
        select(func.count(DailyQuestionAnswer.id)).where(
            DailyQuestionAnswer.question_id == question.id
        )
    ) or 0
    answered = db.scalar(
        select(DailyQuestionAnswer.id).where(
            DailyQuestionAnswer.question_id == question.id,
            DailyQuestionAnswer.user_id == user_id,
        )
    ) is not None
    return DailyQuestionPublic(
        id=question.id,
        question_date=question.question_date,
        text=question.text,
        answer_count=int(answer_count),
        answered_by_me=answered,
    )


@router.get("/today", response_model=DailyQuestionPublic)
def today_question(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    return _to_public(db, _today_question(db), current_user.id)


@router.post(
    "/today/answer",
    response_model=DailyQuestionAnswerResponse,
    status_code=status.HTTP_201_CREATED,
)
def answer_today(
    payload: DailyQuestionAnswerCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    question = _today_question(db)
    existing = db.scalar(
        select(DailyQuestionAnswer).where(
            DailyQuestionAnswer.question_id == question.id,
            DailyQuestionAnswer.user_id == current_user.id,
        )
    )
    if existing is not None:
        raise HTTPException(status_code=409, detail="Bugünün sorusunu zaten cevapladın")

    content = payload.content.strip()
    if not content:
        raise HTTPException(status_code=422, detail="Cevap boş olamaz")

    post = Post(
        author_id=current_user.id,
        content=content,
        is_anonymous=payload.is_anonymous,
    )
    db.add(post)
    db.flush()
    db.add(
        DailyQuestionAnswer(
            question_id=question.id,
            post_id=post.id,
            user_id=current_user.id,
        )
    )
    db.commit()
    db.refresh(post)
    return DailyQuestionAnswerResponse(
        question=_to_public(db, question, current_user.id),
        post=to_feed_post(db, post, current_user.id),
    )
