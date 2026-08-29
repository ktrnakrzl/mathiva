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


def test_register_normalizes_email_and_prevents_case_duplicates(client):
    mixed = {**SAMPLE_USER, "email": "Student@Example.COM"}
    r = client.post("/auth/register", json=mixed)
    assert r.status_code == 200
    assert r.json()["email"] == "student@example.com"

    r = client.post(
        "/auth/register", json={**SAMPLE_USER, "email": "student@example.com"}
    )
    assert r.status_code == 409


def test_login_accepts_case_insensitive_email(client):
    client.post("/auth/register", json=SAMPLE_USER)
    r = client.post(
        "/auth/login",
        json={"email": "STUDENT@EXAMPLE.COM", "password": SAMPLE_USER["password"]},
    )
    assert r.status_code == 200


def test_login_rejects_invalid_email(client):
    r = client.post(
        "/auth/login",
        json={"email": "not-an-email", "password": "password123"},
    )
    assert r.status_code == 422


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


def test_google_login_creates_user_and_returns_token(client, monkeypatch):
    from app.api import auth as auth_api

    monkeypatch.setattr(auth_api, "google_sign_in_configured", lambda: True)
    monkeypatch.setattr(
        auth_api,
        "verify_google_id_token",
        lambda token: {
            "email": "google-user@example.com",
            "email_verified": True,
            "name": "Google User",
        },
    )

    r = client.post("/auth/google", json={"id_token": "valid-google-token"})
    assert r.status_code == 200
    assert r.json()["access_token"]

    token = r.json()["access_token"]
    r = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200
    assert r.json()["email"] == "google-user@example.com"
    assert r.json()["full_name"] == "Google User"


def test_google_login_reuses_existing_email(client, monkeypatch):
    from app.api import auth as auth_api

    client.post("/auth/register", json=SAMPLE_USER)

    monkeypatch.setattr(auth_api, "google_sign_in_configured", lambda: True)
    monkeypatch.setattr(
        auth_api,
        "verify_google_id_token",
        lambda token: {
            "email": SAMPLE_USER["email"],
            "email_verified": True,
            "name": "Different Google Name",
        },
    )

    r = client.post("/auth/google", json={"id_token": "valid-google-token"})
    assert r.status_code == 200
    token = r.json()["access_token"]

    r = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200
    assert r.json()["email"] == SAMPLE_USER["email"]
    assert r.json()["full_name"] == SAMPLE_USER["full_name"]


def test_google_login_rejects_bad_token(client, monkeypatch):
    from app.api import auth as auth_api

    def fail(_token):
        raise ValueError("bad token")

    monkeypatch.setattr(auth_api, "google_sign_in_configured", lambda: True)
    monkeypatch.setattr(auth_api, "verify_google_id_token", fail)

    r = client.post("/auth/google", json={"id_token": "bad-google-token"})
    assert r.status_code == 401


def test_google_login_rejects_unverified_email(client, monkeypatch):
    from app.api import auth as auth_api

    monkeypatch.setattr(auth_api, "google_sign_in_configured", lambda: True)
    monkeypatch.setattr(
        auth_api,
        "verify_google_id_token",
        lambda token: {
            "email": "google-user@example.com",
            "email_verified": False,
            "name": "Google User",
        },
    )

    r = client.post("/auth/google", json={"id_token": "valid-google-token"})
    assert r.status_code == 401


def test_google_login_requires_configuration(client, monkeypatch):
    from app.api import auth as auth_api

    monkeypatch.setattr(auth_api, "google_sign_in_configured", lambda: False)

    r = client.post("/auth/google", json={"id_token": "valid-google-token"})
    assert r.status_code == 503


def test_forgot_password_resets_password(client, monkeypatch):
    from app.api import auth as auth_api

    sent_links = []
    monkeypatch.setattr(
        auth_api,
        "send_password_reset_email",
        lambda email, url: sent_links.append(url),
    )
    monkeypatch.setattr(
        auth_api,
        "build_password_reset_url",
        lambda token: f"https://app.example.com/reset-password?token={token}",
    )

    client.post("/auth/register", json=SAMPLE_USER)

    r = client.post("/auth/password/forgot", json={"email": SAMPLE_USER["email"]})
    assert r.status_code == 200
    assert "If an account exists" in r.json()["message"]
    assert len(sent_links) == 1

    token = sent_links[0].split("token=", 1)[1]
    r = client.post(
        "/auth/password/reset",
        json={"token": token, "new_password": "newpassword123"},
    )
    assert r.status_code == 200

    assert client.post(
        "/auth/login",
        json={"email": SAMPLE_USER["email"], "password": SAMPLE_USER["password"]},
    ).status_code == 401
    assert client.post(
        "/auth/login",
        json={"email": SAMPLE_USER["email"], "password": "newpassword123"},
    ).status_code == 200


def test_forgot_password_finds_mixed_case_registered_email(client, monkeypatch):
    from app.api import auth as auth_api

    sent_links = []
    monkeypatch.setattr(
        auth_api,
        "send_password_reset_email",
        lambda email, url: sent_links.append(url),
    )

    client.post(
        "/auth/register", json={**SAMPLE_USER, "email": "Student@Example.COM"}
    )
    r = client.post("/auth/password/forgot", json={"email": "student@example.com"})

    assert r.status_code == 200
    assert len(sent_links) == 1


def test_forgot_password_unknown_email_is_generic(client, monkeypatch):
    from app.api import auth as auth_api

    sent_links = []
    monkeypatch.setattr(
        auth_api,
        "send_password_reset_email",
        lambda email, url: sent_links.append(url),
    )

    r = client.post("/auth/password/forgot", json={"email": "nobody@example.com"})
    assert r.status_code == 200
    assert "If an account exists" in r.json()["message"]
    assert sent_links == []


def test_password_reset_email_uses_resend_when_configured(monkeypatch):
    from app.services import auth_service

    requests = []

    class Response:
        status_code = 200
        text = "{}"

    monkeypatch.setattr(auth_service.settings, "brevo_api_key", None)
    monkeypatch.setattr(auth_service.settings, "resend_api_key", "test-key")
    monkeypatch.setattr(auth_service.settings, "email_from", "Mathiva <test@example.com>")
    monkeypatch.setattr(
        auth_service.requests,
        "post",
        lambda url, **kwargs: requests.append((url, kwargs)) or Response(),
    )

    auth_service.send_password_reset_email(
        "student@example.com",
        "https://app.example.com/reset-password?token=test",
    )

    assert len(requests) == 1
    url, kwargs = requests[0]
    assert url == "https://api.resend.com/emails"
    assert kwargs["headers"]["Authorization"] == "Bearer test-key"
    assert kwargs["json"]["from"] == "Mathiva <test@example.com>"
    assert kwargs["json"]["to"] == ["student@example.com"]
    assert kwargs["json"]["subject"] == "Reset your Mathiva password"
    assert "https://app.example.com/reset-password?token=test" in kwargs["json"]["text"]


def test_password_reset_email_uses_brevo_when_configured(monkeypatch):
    from app.services import auth_service

    requests = []

    class Response:
        status_code = 201
        text = "{}"

    monkeypatch.setattr(auth_service.settings, "brevo_api_key", "brevo-key")
    monkeypatch.setattr(auth_service.settings, "resend_api_key", "resend-key")
    monkeypatch.setattr(auth_service.settings, "email_from", "Mathiva <sender@example.com>")
    monkeypatch.setattr(
        auth_service.requests,
        "post",
        lambda url, **kwargs: requests.append((url, kwargs)) or Response(),
    )

    auth_service.send_password_reset_email(
        "student@example.com",
        "https://app.example.com/reset-password?token=test",
    )

    assert len(requests) == 1
    url, kwargs = requests[0]
    assert url == "https://api.brevo.com/v3/smtp/email"
    assert kwargs["headers"]["api-key"] == "brevo-key"
    assert kwargs["json"]["sender"] == {
        "name": "Mathiva",
        "email": "sender@example.com",
    }
    assert kwargs["json"]["to"] == [{"email": "student@example.com"}]
    assert kwargs["json"]["subject"] == "Reset your Mathiva password"
    assert "https://app.example.com/reset-password?token=test" in kwargs["json"]["textContent"]


def test_reset_password_rejects_reused_token(client, monkeypatch):
    from app.api import auth as auth_api

    sent_links = []
    monkeypatch.setattr(
        auth_api,
        "send_password_reset_email",
        lambda email, url: sent_links.append(url),
    )

    client.post("/auth/register", json=SAMPLE_USER)
    client.post("/auth/password/forgot", json={"email": SAMPLE_USER["email"]})
    token = sent_links[0].split("token=", 1)[1]

    r = client.post(
        "/auth/password/reset",
        json={"token": token, "new_password": "newpassword123"},
    )
    assert r.status_code == 200
    r = client.post(
        "/auth/password/reset",
        json={"token": token, "new_password": "anotherpassword123"},
    )
    assert r.status_code == 400


def test_reset_password_rejects_short_password(client):
    r = client.post(
        "/auth/password/reset",
        json={"token": "anything", "new_password": "short"},
    )
    assert r.status_code == 422
