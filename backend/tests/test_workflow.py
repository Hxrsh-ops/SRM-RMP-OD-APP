def get_auth_token(client, username, password):
    res = client.post("/api/v1/auth/login", data={"username": username, "password": password})
    return res.json()["access_token"]

def test_full_multi_role_approval_workflow(client):
    student_token = get_auth_token(client, "RA2510026020400", "student123")
    faculty_token = get_auth_token(client, "FA1001", "faculty123")
    coordinator_token = get_auth_token(client, "CO1001", "coord123")

    # 1. Student creates OD request
    create_res = client.post(
        "/api/v1/od-requests",
        json={
            "reason": "Hackathon",
            "start_date": "2026-07-28",
            "end_date": "2026-07-30",
            "duration_days": 3,
            "purpose": "National AI Hackathon 2026",
            "venue": "Tech Park Auditorium",
            "organizer": "Dept of CSE",
            "additional_notes": "Team Leader"
        },
        headers={"Authorization": f"Bearer {student_token}"}
    )
    assert create_res.status_code == 201
    od_data = create_res.json()
    req_id = od_data["id"]
    assert od_data["status"] == "PENDING_FACULTY"
    assert len(od_data["timeline"]) == 2

    # 2. Faculty Advisor reviews & approves
    fac_res = client.post(
        f"/api/v1/od-requests/{req_id}/faculty-action",
        json={"approve": True, "comment": "Verified event attendance."},
        headers={"Authorization": f"Bearer {faculty_token}"}
    )
    assert fac_res.status_code == 200
    fac_data = fac_res.json()
    assert fac_data["status"] == "PENDING_COORDINATOR"
    assert len(fac_data["timeline"]) == 3

    # 3. Coordinator grants final sign-off approval
    coord_res = client.post(
        f"/api/v1/od-requests/{req_id}/coordinator-action",
        json={"approve": True, "comment": "Final sign-off recorded."},
        headers={"Authorization": f"Bearer {coordinator_token}"}
    )
    assert coord_res.status_code == 200
    final_data = coord_res.json()
    assert final_data["status"] == "COMPLETED"
    assert len(final_data["timeline"]) == 4

def test_student_cannot_approve_own_request(client):
    student_token = get_auth_token(client, "RA2510026020400", "student123")
    res = client.post(
        "/api/v1/od-requests/OD-2026-001/faculty-action",
        json={"approve": True},
        headers={"Authorization": f"Bearer {student_token}"}
    )
    assert res.status_code == 403
