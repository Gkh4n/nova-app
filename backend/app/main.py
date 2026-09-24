from html import escape

from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.router import api_router
from app.core.config import API_V1_PREFIX, APP_NAME, CORS_ORIGINS
from app.database import models  # noqa: F401
from app.database.base import Base
from app.database.migrations import ensure_runtime_schema
from app.database.session import SessionLocal, engine
from app.database.models.post import Post

Base.metadata.create_all(bind=engine)
ensure_runtime_schema()

app = FastAPI(title=APP_NAME, version="1.0.0-beta")
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(api_router, prefix=API_V1_PREFIX)


@app.get("/")
def root():
    return {"app": "NOVA", "version": "1.0.0-beta", "status": "online"}


@app.get("/health")
def health():
    return {"status": "ok", "app": "NOVA", "version": "1.0.0-beta"}


@app.get("/p/{post_id}", response_class=HTMLResponse)
def public_post(post_id: int):
    with SessionLocal() as db:
        post = db.get(Post, post_id)
        if post is None:
            return HTMLResponse("<h1>NOVA</h1><p>Bu düşünce bulunamadı.</p>", status_code=404)
        content = escape(post.content)
        badge = "Anonim düşünce" if post.is_anonymous else "NOVA düşüncesi"
        return HTMLResponse(f"""<!doctype html><html lang='tr'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>NOVA</title><style>body{{margin:0;background:#0a0a0e;color:#fff;font-family:system-ui;display:grid;place-items:center;min-height:100vh}}main{{max-width:680px;padding:36px}}.brand{{letter-spacing:6px;font-weight:900;color:#a991ff}}.card{{margin-top:24px;background:#141419;border:1px solid #282832;border-radius:24px;padding:28px}}.muted{{color:#aaa}}p{{font-size:24px;line-height:1.5}}</style></head><body><main><div class='brand'>NOVA</div><div class='card'><div class='muted'>{badge}</div><p>{content}</p><div class='muted'>Önce düşünceyi keşfet, sonra insanı.</div></div></main></body></html>""")
