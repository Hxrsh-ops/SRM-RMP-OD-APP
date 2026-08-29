def test_login_student_success(client):
    response = client.post(
        "/api/v1/auth/login",
        data={"username": "RA2511026020400", "password": "Student@123"}
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"

def test_login_faculty_success(client):
    response = client.post(
        "/api/v1/auth/login",
        data={"username": "FA1001", "password": "Faculty@123"}
    )
    assert response.status_code == 200
    assert "access_token" in response.json()

def test_login_invalid_password(client):
    response = client.post(
        "/api/v1/auth/login",
        data={"username": "INVALID_TEST_USER_99", "password": "wrongpassword"}
    )
    assert response.status_code == 401

def test_get_me_profile(client):
    login_res = client.post(
        "/api/v1/auth/login",
        data={"username": "RA2511026020400", "password": "Student@123"}
    )
    token = login_res.json()["access_token"]

    response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["username"] == "RA2511026020400"
    assert data["full_name"] == "K.M. Harshanth"
    assert data["role"] == "STUDENT"
    assert data["assigned_faculty_name"] == "Dr. Karthik B"

def test_refresh_token(client):
    login_res = client.post(
        "/api/v1/auth/login/json",
        json={"username": "RA2511026020400", "password": "Student@123"}
    )
    refresh_token = login_res.json()["refresh_token"]

    refresh_res = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token}
    )
    assert refresh_res.status_code == 200
    data = refresh_res.json()
    assert "access_token" in data
    assert "refresh_token" in data
