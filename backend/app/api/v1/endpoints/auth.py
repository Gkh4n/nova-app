from datetime import datetime, timedelta, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.config import DEV_RETURN_RESET_TOKEN, RESET_TOKEN_EXPIRE_MINUTES
from app.core.security import (
    create_access_token,
    hash_password,
    hash_reset_token,
    new_reset_token,
    verify_password,
)
from app.database.models.password_reset import PasswordReset
from app.database.models.user import User
from app.database.session import get_db
from app.schemas.auth import (
    ForgotPasswordRequest,
    ForgotPasswordResponse,
    LoginRequest,
    PasswordChangeRequest,
    RegisterRequest,
    ResetPasswordRequest,
    TokenResponse,
)
from app.schemas.user import UserMe

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest, db: Annotated[Session, Depends(get_db)]):
    username = payload.username.strip().lower()
    email = payload.email.strip().lower()
    existing = db.scalar(select(User).where(or_(User.username == username, User.email == email)))
    if existing:
        raise HTTPException(status_code=409, detail="Kullanıcı adı veya e-posta zaten kullanılıyor")
    user = User(
        username=username,
        email=email,
        display_name=payload.display_name.strip(),
        password_hash=hash_password(payload.password),
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return TokenResponse(access_token=create_access_token(user.id, user.token_version))


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Annotated[Session, Depends(get_db)]):
    login_value = payload.login.strip().lower()
    user = db.scalar(select(User).where(or_(User.username == login_value, User.email == login_value)))
    if user is None or not user.is_active or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Kullanıcı adı/e-posta veya şifre hatalı")
    return TokenResponse(access_token=create_access_token(user.id, user.token_version))


@router.get("/me", response_model=UserMe)
def me(current_user: Annotated[User, Depends(get_current_user)]):
    return current_user


@router.post("/password/change")
def change_password(
    payload: PasswordChangeRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    if not verify_password(payload.current_password, current_user.password_hash):
        raise HTTPException(status_code=422, detail="Mevcut şifre yanlış")
    if payload.current_password == payload.new_password:
        raise HTTPException(status_code=422, detail="Yeni şifre mevcut şifreyle aynı olamaz")
    current_user.password_hash = hash_password(payload.new_password)
    current_user.token_version += 1
    db.commit()
    return {"changed": True}


@router.post("/password/forgot", response_model=ForgotPasswordResponse)
def forgot_password(payload: ForgotPasswordRequest, db: Annotated[Session, Depends(get_db)]):
    user = db.scalar(select(User).where(User.email == payload.email.strip().lower(), User.is_active.is_(True)))
    token: str | None = None
    if user is not None:
        token, digest = new_reset_token()
        db.add(
            PasswordReset(
                user_id=user.id,
                token_hash=digest,
                expires_at=datetime.now(timezone.utc) + timedelta(minutes=RESET_TOKEN_EXPIRE_MINUTES),
            )
        )
        db.commit()
        # Email delivery is intentionally provider-agnostic. In local beta, set
        # NOVA_DEV_RETURN_RESET_TOKEN=1 to test this flow without an email service.
        if DEV_RETURN_RESET_TOKEN:
            return ForgotPasswordResponse(message="Beta sıfırlama kodu oluşturuldu.", dev_reset_token=token)
    return ForgotPasswordResponse(message="Bu e-posta kayıtlıysa şifre sıfırlama isteği oluşturuldu.")


@router.post("/password/reset")
def reset_password(payload: ResetPasswordRequest, db: Annotated[Session, Depends(get_db)]):
    digest = hash_reset_token(payload.token)
    row = db.scalar(select(PasswordReset).where(PasswordReset.token_hash == digest))
    if row is None or row.used_at is not None:
        raise HTTPException(status_code=422, detail="Geçersiz sıfırlama kodu")
    expires = row.expires_at
    if expires.tzinfo is None:
        expires = expires.replace(tzinfo=timezone.utc)
    if expires < datetime.now(timezone.utc):
        raise HTTPException(status_code=422, detail="Sıfırlama kodunun süresi dolmuş")
    user = db.get(User, row.user_id)
    if user is None or not user.is_active:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
    user.password_hash = hash_password(payload.new_password)
    user.token_version += 1
    row.used_at = datetime.now(timezone.utc)
    db.commit()
    return {"reset": True}
