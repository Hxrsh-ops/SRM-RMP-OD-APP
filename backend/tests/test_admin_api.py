import pytest
from fastapi.testclient import TestClient

def get_token(client: TestClient, username: str, password: str) -> str:
    res = client.post("/api/v1/auth/login", data={"username": username, "password": password})
    assert res.status_code == 200, f"Login failed for {username}: {res.text}"
    return res.json()["access_token"]

def test_admin_rbac_protection(client: TestClient):
    student_token = get_token(client, "RA2511026020400", "Student@123")
    headers = {"Authorization": f"Bearer {student_token}"}
    res = client.get("/api/v1/admin/dashboard/metrics", headers=headers)
    assert res.status_code == 403

def test_master_admin_dashboard_metrics(client: TestClient):
    admin_token = get_token(client, "ADMIN1001", "Admin@123456")
    headers = {"Authorization": f"Bearer {admin_token}"}
    res = client.get("/api/v1/admin/dashboard/metrics", headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert "total_users" in data
    assert "students_count" in data
    assert "approval_rate" in data

def test_admin_user_crud(client: TestClient):
    admin_token = get_token(client, "ADMIN1001", "Admin@123456")
    headers = {"Authorization": f"Bearer {admin_token}"}

    # Create user
    new_user = {
        "username": "TEST_STU_99",
        "email": "teststu99@srmist.edu.in",
        "full_name": "Test Student 99",
        "password": "Password@123",
        "role": "STUDENT"
    }
    res = client.post("/api/v1/admin/users", json=new_user, headers=headers)
    assert res.status_code == 201
    created = res.json()
    user_id = created["id"]
    assert created["username"] == "TEST_STU_99"

    # List users
    res_list = client.get("/api/v1/admin/users", headers=headers)
    assert res_list.status_code == 200
    assert res_list.json()["total"] >= 1

    # Update user status (lock / unlock)
    res_status = client.patch(f"/api/v1/admin/users/{user_id}/status", json={"is_locked": True}, headers=headers)
    assert res_status.status_code == 200
    assert res_status.json()["is_locked"] is True

def test_admin_settings_and_monitoring(client: TestClient):
    admin_token = get_token(client, "ADMIN1001", "Admin@123456")
    headers = {"Authorization": f"Bearer {admin_token}"}

    # Settings
    res_set = client.get("/api/v1/admin/settings", headers=headers)
    assert res_set.status_code == 200
    assert res_set.json()["academic_year"] == "2025-2026"

    # Monitoring
    res_mon = client.get("/api/v1/admin/monitoring", headers=headers)
    assert res_mon.status_code == 200
    assert res_mon.json()["status"] == "HEALTHY"

    # Security Summary
    res_sec = client.get("/api/v1/admin/security/summary", headers=headers)
    assert res_sec.status_code == 200
    assert "recent_events" in res_sec.json()

def test_admin_user_records_and_delete(client: TestClient):
    admin_token = get_token(client, "ADMIN1001", "Admin@123456")
    headers = {"Authorization": f"Bearer {admin_token}"}

    users_res = client.get("/api/v1/admin/users", headers=headers)
    assert users_res.status_code == 200
    first_user = users_res.json()["items"][0]
    user_id = first_user["id"]

    records_res = client.get(f"/api/v1/admin/users/{user_id}/records", headers=headers)
    assert records_res.status_code == 200
    data = records_res.json()
    assert "user" in data
    assert "records" in data
    assert "total_records" in data

    # Test Bulk Delete for User
    del_all_res = client.delete(f"/api/v1/admin/users/{user_id}/od-requests", headers=headers)
    assert del_all_res.status_code == 200
    assert "deleted_count" in del_all_res.json()
