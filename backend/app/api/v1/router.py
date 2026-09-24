from fastapi import APIRouter

from app.api.v1.endpoints import analytics, auth, comments, explore, follows, notifications, posts, questions, reactions, safety, search, users

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(posts.router)
api_router.include_router(reactions.router)
api_router.include_router(comments.router)
api_router.include_router(questions.router)
api_router.include_router(users.router)
api_router.include_router(follows.router)
api_router.include_router(explore.router)
api_router.include_router(notifications.router)
api_router.include_router(safety.router)
api_router.include_router(search.router)
api_router.include_router(analytics.router)
