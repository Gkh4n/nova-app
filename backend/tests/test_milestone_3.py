from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def h(token: str): return {"Authorization": f"Bearer {token}"}

def reg(name: str) -> str:
    r = client.post("/api/v1/auth/register", json={"username": name, "email": f"{name}@example.com", "display_name": name.title(), "password": "supersecret1"})
    assert r.status_code == 201, r.text
    return r.json()["access_token"]

def test_milestone_3_explore_follow_notifications():
    a = reg("m3author")
    b = reg("m3viewer")
    post = client.post("/api/v1/posts", headers=h(a), json={"content": "M3 keşfet denemesi", "is_anonymous": False})
    assert post.status_code == 201
    pid = post.json()["id"]

    assert client.put(f"/api/v1/posts/{pid}/reaction", headers=h(b), json={"reaction_type": "thought"}).status_code == 200
    exp = client.get("/api/v1/explore", headers=h(b))
    assert exp.status_code == 200, exp.text
    assert any(x["id"] == pid for x in exp.json()["trending"])

    follow = client.put("/api/v1/users/m3author/follow", headers=h(b), json={})
    assert follow.status_code == 200 and follow.json()["following"] is True
    profile = client.get("/api/v1/users/m3author", headers=h(b))
    assert profile.status_code == 200 and profile.json()["followed_by_me"] is True

    notes = client.get("/api/v1/notifications", headers=h(a))
    assert notes.status_code == 200
    kinds = {n["kind"] for n in notes.json()}
    assert "reaction" in kinds
    assert "follow" in kinds
