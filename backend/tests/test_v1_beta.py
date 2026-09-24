from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def h(token: str):
    return {"Authorization": f"Bearer {token}"}

def reg(name: str) -> str:
    r = client.post('/api/v1/auth/register', json={
        'username': name,
        'email': f'{name}@example.com',
        'display_name': name.title(),
        'password': 'supersecret1',
    })
    assert r.status_code == 201, r.text
    return r.json()['access_token']

def test_v1_save_search_block_report_and_password_change():
    a = reg('v1alpha')
    b = reg('v1beta')

    post = client.post('/api/v1/posts', headers=h(a), json={
        'content': 'NOVA hakkında #teknoloji konuşalım',
        'is_anonymous': False,
    })
    assert post.status_code == 201, post.text
    pid = post.json()['id']
    assert 'teknoloji' in post.json()['topics']

    saved = client.put(f'/api/v1/posts/{pid}/save', headers=h(b), json={})
    assert saved.status_code == 200 and saved.json()['saved'] is True
    saved_list = client.get('/api/v1/users/me/saved', headers=h(b))
    assert saved_list.status_code == 200
    assert pid in {p['id'] for p in saved_list.json()}

    searched = client.get('/api/v1/search?q=teknoloji', headers=h(b))
    assert searched.status_code == 200
    assert pid in {p['id'] for p in searched.json()['posts']}
    assert any(t['name'] == 'teknoloji' for t in searched.json()['topics'])

    report = client.post('/api/v1/reports', headers=h(b), json={
        'target_type': 'post', 'target_id': pid, 'reason': 'Diğer', 'details': 'test'
    })
    assert report.status_code == 201

    blocked = client.put('/api/v1/users/v1alpha/block', headers=h(b), json={})
    assert blocked.status_code == 200 and blocked.json()['blocked'] is True
    feed = client.get('/api/v1/feed', headers=h(b))
    assert pid not in {p['id'] for p in feed.json()}

    changed = client.post('/api/v1/auth/password/change', headers=h(a), json={
        'current_password': 'supersecret1', 'new_password': 'newsecret99'
    })
    assert changed.status_code == 200
    assert client.get('/api/v1/auth/me', headers=h(a)).status_code == 401
    relogin = client.post('/api/v1/auth/login', json={'login': 'v1alpha', 'password': 'newsecret99'})
    assert relogin.status_code == 200


def test_v1_delete_account():
    token = reg('v1delete')
    r = client.delete('/api/v1/users/me', headers=h(token))
    assert r.status_code == 200 and r.json()['deleted'] is True
    assert client.get('/api/v1/auth/me', headers=h(token)).status_code == 401
