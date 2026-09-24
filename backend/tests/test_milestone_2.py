from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def auth_header(token: str):
    return {"Authorization": f"Bearer {token}"}


def register(username: str) -> str:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "username": username,
            "email": f"{username}@example.com",
            "display_name": username.title(),
            "password": "supersecret1",
        },
    )
    assert response.status_code == 201, response.text
    return response.json()["access_token"]


def test_milestone_2_social_flow():
    author_token = register("m2author")
    viewer_token = register("m2viewer")

    created = client.post(
        "/api/v1/posts",
        headers=auth_header(author_token),
        json={"content": "NOVA Milestone 2 deneme düşüncesi", "is_anonymous": False},
    )
    assert created.status_code == 201, created.text
    post_id = created.json()["id"]
    assert created.json()["reaction_counts"] == {"felt": 0, "thought": 0, "funny": 0}
    assert created.json()["comment_count"] == 0

    reacted = client.put(
        f"/api/v1/posts/{post_id}/reaction",
        headers=auth_header(viewer_token),
        json={"reaction_type": "thought"},
    )
    assert reacted.status_code == 200, reacted.text
    assert reacted.json()["viewer_reaction"] == "thought"
    assert reacted.json()["counts"]["thought"] == 1

    switched = client.put(
        f"/api/v1/posts/{post_id}/reaction",
        headers=auth_header(viewer_token),
        json={"reaction_type": "felt"},
    )
    assert switched.status_code == 200, switched.text
    assert switched.json()["counts"]["thought"] == 0
    assert switched.json()["counts"]["felt"] == 1

    comment = client.post(
        f"/api/v1/posts/{post_id}/comments",
        headers=auth_header(viewer_token),
        json={"content": "Buna katılıyorum", "parent_id": None},
    )
    assert comment.status_code == 201, comment.text
    comment_id = comment.json()["id"]

    reply = client.post(
        f"/api/v1/posts/{post_id}/comments",
        headers=auth_header(author_token),
        json={"content": "Ben de bunu merak ediyordum", "parent_id": comment_id},
    )
    assert reply.status_code == 201, reply.text
    assert reply.json()["parent_id"] == comment_id

    liked = client.put(
        f"/api/v1/comments/{comment_id}/like",
        headers=auth_header(author_token),
        json={},
    )
    assert liked.status_code == 200, liked.text
    assert liked.json()["like_count"] == 1
    assert liked.json()["liked_by_me"] is True

    comments = client.get(
        f"/api/v1/posts/{post_id}/comments",
        headers=auth_header(viewer_token),
    )
    assert comments.status_code == 200, comments.text
    assert len(comments.json()) == 2

    feed = client.get("/api/v1/feed", headers=auth_header(viewer_token))
    assert feed.status_code == 200, feed.text
    item = next(post for post in feed.json() if post["id"] == post_id)
    assert item["reaction_counts"]["felt"] == 1
    assert item["comment_count"] == 2
    assert item["viewer_reaction"] == "felt"

    question = client.get("/api/v1/questions/today", headers=auth_header(viewer_token))
    assert question.status_code == 200, question.text
    assert question.json()["text"]
    assert question.json()["answered_by_me"] is False

    answer = client.post(
        "/api/v1/questions/today/answer",
        headers=auth_header(viewer_token),
        json={"content": "Bugünün sorusuna cevabım", "is_anonymous": False},
    )
    assert answer.status_code == 201, answer.text
    assert answer.json()["question"]["answered_by_me"] is True
    assert answer.json()["post"]["daily_question_text"] == question.json()["text"]

    duplicate = client.post(
        "/api/v1/questions/today/answer",
        headers=auth_header(viewer_token),
        json={"content": "İkinci cevap", "is_anonymous": False},
    )
    assert duplicate.status_code == 409

    profile = client.get("/api/v1/users/m2author", headers=auth_header(viewer_token))
    assert profile.status_code == 200, profile.text
    assert profile.json()["username"] == "m2author"
    assert profile.json()["post_count"] >= 1
    assert profile.json()["reactions_received"] >= 1
