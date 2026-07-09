"""Tests for the auth endpoints (register / login / me) and enforcement."""

from tests.conftest import SAMPLE_USER


def test_register_then_login_then_me(client):
    r = client.post("/auth/register", json=SAMPLE_USER)
    assert r.status_code == 200
    assert r.json()["email"] == SAMPLE_USER["email"]

    r = client.post(
        "/auth/login",
        json={"email": SAMPLE_USER["email"], "password": SAMPLE_USER["password"]},
    )
    assert r.status_code == 200
    token = r.json()["access_token"]
    assert token

    r = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200
    body = r.json()
    assert body["email"] == SAMPLE_USER["email"]
    assert body["full_name"] == SAMPLE_USER["full_name"]
    assert body["section"] == SAMPLE_USER["section"]
    # The password hash must never be exposed.
    assert "password" not in body
    assert "password_hash" not in body


def test_register_duplicate_email_conflicts(client):
    client.post("/auth/register", json=SAMPLE_USER)
    r = client.post("/auth/register", json=SAMPLE_USER)
    assert r.status_code == 409


def test_register_rejects_short_password(client):
    payload = {**SAMPLE_USER, "password": "short"}
    r = client.post("/auth/register", json=payload)
    assert r.status_code == 422


def test_register_rejects_blank_name(client):
    payload = {**SAMPLE_USER, "full_name": "   "}
    r = client.post("/auth/register", json=payload)
    assert r.status_code == 422


def test_login_wrong_password_unauthorized(client):
    client.post("/auth/register", json=SAMPLE_USER)
    r = client.post(
        "/auth/login",
        json={"email": SAMPLE_USER["email"], "password": "wrongpassword"},
    )
    assert r.status_code == 401


def test_login_unknown_email_unauthorized(client):
    r = client.post(
        "/auth/login",
        json={"email": "nobody@example.com", "password": "password123"},
    )
    assert r.status_code == 401


def test_me_without_token_unauthorized(client):
    assert client.get("/auth/me").status_code == 401


def test_me_with_garbage_token_unauthorized(client):
    r = client.get("/auth/me", headers={"Authorization": "Bearer not-a-jwt"})
    assert r.status_code == 401


def test_password_hash_is_not_plaintext(client):
    """A registered user's stored hash must differ from the raw password and
    must verify against it."""
    from app.services.auth_service import hash_password, verify_password

    hashed = hash_password("password123")
    assert hashed != "password123"
    assert verify_password("password123", hashed) is True
    assert verify_password("wrongpassword", hashed) is False
