import os
from pathlib import Path

TEST_DB = Path(__file__).parent / "test_nova.db"
if TEST_DB.exists():
    TEST_DB.unlink()
os.environ["DATABASE_URL"] = f"sqlite:///{TEST_DB.as_posix()}"
os.environ["NOVA_SECRET_KEY"] = "test-secret-key-that-is-at-least-32-bytes-long"

from fastapi.testclient import TestClient  # noqa: E402
from app.main import app  # noqa: E402

client = TestClient(app)


def auth_header(token: str):
    return {"Authorization": f"Bearer {token}"}


def test_milestone_1_flow():
    first = client.post(
        "/api/v1/auth/register",
        json={
            "username": "gokhan",
            "email": "gokhan@example.com",
            "display_name": "Gökhan",
            "password": "supersecret1",
        },
    )
    assert first.status_code == 201
    first_token = first.json()["access_token"]

    second = client.post(
        "/api/v1/auth/register",
        json={
            "username": "deniz",
            "email": "deniz@example.com",
            "display_name": "Deniz",
            "password": "supersecret2",
        },
    )
    assert second.status_code == 201
    second_token = second.json()["access_token"]

    created = client.post(
        "/api/v1/posts",
        headers=auth_header(first_token),
        json={"content": "İnsan bazen bir kişiyi değil, o kişinin yanındaki halini özlüyor.", "is_anonymous": False},
    )
    assert created.status_code == 201
    post_id = created.json()["id"]
    assert "author" not in created.json()

    feed = client.get("/api/v1/feed", headers=auth_header(second_token))
    assert feed.status_code == 200
    assert feed.json()[0]["id"] == post_id
    assert "author" not in feed.json()[0]

    reveal = client.post(f"/api/v1/posts/{post_id}/reveal", headers=auth_header(second_token))
    assert reveal.status_code == 200
    assert reveal.json()["author"]["username"] == "gokhan"
