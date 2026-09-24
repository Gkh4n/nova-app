from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def h(token: str):
    return {"Authorization": f"Bearer {token}"}


def reg(name: str) -> str:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "username": name,
            "email": f"{name}@example.com",
            "display_name": name.title(),
            "password": "supersecret1",
        },
    )
    assert response.status_code == 201, response.text
    return response.json()["access_token"]


def test_milestone_4_profile_edit_own_posts_and_delete():
    owner = reg("m4owner")
    viewer = reg("m4viewer")

    updated = client.patch(
        "/api/v1/users/me",
        headers=h(owner),
        json={"display_name": "NOVA Owner", "bio": "Önce düşünce, sonra insan."},
    )
    assert updated.status_code == 200, updated.text
    assert updated.json()["display_name"] == "NOVA Owner"
    assert updated.json()["bio"] == "Önce düşünce, sonra insan."

    visible = client.post(
        "/api/v1/posts",
        headers=h(owner),
        json={"content": "Görünür düşünce", "is_anonymous": False},
    )
    hidden = client.post(
        "/api/v1/posts",
        headers=h(owner),
        json={"content": "Anonim düşünce", "is_anonymous": True},
    )
    assert visible.status_code == 201 and hidden.status_code == 201
    assert visible.json()["is_mine"] is True
    assert visible.json()["can_reveal"] is False

    own_profile = client.get("/api/v1/users/m4owner", headers=h(owner))
    assert own_profile.status_code == 200
    own_ids = {post["id"] for post in own_profile.json()["recent_posts"]}
    assert visible.json()["id"] in own_ids
    assert hidden.json()["id"] in own_ids
    assert own_profile.json()["bio"] == "Önce düşünce, sonra insan."

    public_profile = client.get("/api/v1/users/m4owner", headers=h(viewer))
    assert public_profile.status_code == 200
    public_ids = {post["id"] for post in public_profile.json()["recent_posts"]}
    assert visible.json()["id"] in public_ids
    assert hidden.json()["id"] not in public_ids

    denied = client.delete(f"/api/v1/posts/{visible.json()['id']}", headers=h(viewer))
    assert denied.status_code == 403

    deleted = client.delete(f"/api/v1/posts/{visible.json()['id']}", headers=h(owner))
    assert deleted.status_code == 200 and deleted.json()["deleted"] is True

    after = client.get("/api/v1/users/m4owner", headers=h(owner))
    after_ids = {post["id"] for post in after.json()["recent_posts"]}
    assert visible.json()["id"] not in after_ids
