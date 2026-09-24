import os

APP_NAME = "NOVA API"
API_V1_PREFIX = "/api/v1"
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./nova.db")
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql+psycopg://", 1)
elif DATABASE_URL.startswith("postgresql://") and "+psycopg" not in DATABASE_URL:
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+psycopg://", 1)

SECRET_KEY = os.getenv("NOVA_SECRET_KEY", "dev-only-change-this-before-production")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "43200"))
RESET_TOKEN_EXPIRE_MINUTES = int(os.getenv("RESET_TOKEN_EXPIRE_MINUTES", "30"))
JWT_ALGORITHM = "HS256"
PUBLIC_BASE_URL = os.getenv("PUBLIC_BASE_URL", "").rstrip("/")
DEV_RETURN_RESET_TOKEN = os.getenv("NOVA_DEV_RETURN_RESET_TOKEN", "0") == "1"
CORS_ORIGINS = [x.strip() for x in os.getenv("CORS_ORIGINS", "*").split(",") if x.strip()]
