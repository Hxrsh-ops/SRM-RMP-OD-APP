from datetime import date, timedelta

def get_auth_token(client, username, password):
    res = client.post("/api/v1/auth/login", data={"username": username, "password": password})
    return res.json()["access_token"]

def test_full_multi_role_approval_and_completion_proof_workflow(client):
    student_token = get_auth_token(client, "RA2511026020400", "student123")
    faculty_token = get_auth_token(client, "FA1001", "faculty123")
    coordinator_token = get_auth_token(client, "CO1001", "coord123")

    today = date.today()
    past_start = (today - timedelta(days=5)).isoformat()
    past_end = (today - timedelta(days=2)).isoformat()

    # 1. Student creates Day Scholar OD request for past event
    create_res = client.post(
        "/api/v1/od-requests",
        json={
            "reason": "Hackathon",
            "start_date": past_start,
            "end_date": past_end,
            "duration_days": 3,
            "purpose": "National AI Hackathon 2026",
            "venue": "Tech Park Auditorium",
            "organizer": "Dept of CSE",
            "additional_notes": "Team Leader",
            "residence_type": "Day Scholar"
        },
        headers={"Authorization": f"Bearer {student_token}"}
    )
    assert create_res.status_code == 201
    od_data = create_res.json()
    req_id = od_data["id"]
    assert od_data["status"] == "PENDING_FACULTY"

    # 2. Faculty Advisor approves initial request
    fac_res = client.post(
        f"/api/v1/od-requests/{req_id}/faculty-action",
        json={"approve": True, "comment": "Verified event attendance."},
        headers={"Authorization": f"Bearer {faculty_token}"}
    )
    assert fac_res.status_code == 200
    assert fac_res.json()["status"] == "PENDING_COORDINATOR"

    # 3. Coordinator approves initial request -> APPROVED_AWAITING_EVIDENCE
    coord_res = client.post(
        f"/api/v1/od-requests/{req_id}/coordinator-action",
        json={"approve": True, "comment": "Approved for event participation."},
        headers={"Authorization": f"Bearer {coordinator_token}"}
    )
    assert coord_res.status_code == 200
    assert coord_res.json()["status"] == "APPROVED_AWAITING_EVIDENCE"

    # 4. Student submits post-event completion proof & report
    fake_pdf = ("certificate.pdf", b"%PDF-1.4 completion certificate fake content", "application/pdf")
    proof_res = client.post(
        f"/api/v1/od-requests/{req_id}/completion-evidence",
        data={"completion_summary": "Successfully secured 1st prize in National Hackathon."},
        files={"files": fake_pdf},
        headers={"Authorization": f"Bearer {student_token}"}
    )
    assert proof_res.status_code == 200
    proof_data = proof_res.json()
    assert proof_data["status"] == "PENDING_EVIDENCE_FACULTY"
    assert proof_data["completion_summary"] == "Successfully secured 1st prize in National Hackathon."

    # 5. Faculty Advisor verifies proof -> PENDING_EVIDENCE_COORDINATOR
    fac_verify_res = client.post(
        f"/api/v1/od-requests/{req_id}/faculty-action",
        json={"approve": True, "comment": "Verified certificate and prize evidence."},
        headers={"Authorization": f"Bearer {faculty_token}"}
    )
    assert fac_verify_res.status_code == 200
    assert fac_verify_res.json()["status"] == "PENDING_EVIDENCE_COORDINATOR"

    # 6. Coordinator final verifies proof -> COMPLETED
    coord_final_res = client.post(
        f"/api/v1/od-requests/{req_id}/coordinator-action",
        json={"approve": True, "comment": "Final sign-off recorded. OD granted."},
        headers={"Authorization": f"Bearer {coordinator_token}"}
    )
    assert coord_final_res.status_code == 200
    assert coord_final_res.json()["status"] == "COMPLETED"

def test_evidence_submission_before_end_date_fails(client):
    student_token = get_auth_token(client, "RA2511026020400", "student123")
    faculty_token = get_auth_token(client, "FA1001", "faculty123")
    coordinator_token = get_auth_token(client, "CO1001", "coord123")

    future_start = (date.today() + timedelta(days=10)).isoformat()
    future_end = (date.today() + timedelta(days=12)).isoformat()

    create_res = client.post(
        "/api/v1/od-requests",
        json={
            "reason": "Future Symposium",
            "start_date": future_start,
            "end_date": future_end,
            "duration_days": 3,
            "purpose": "Tech Symposium",
            "venue": "Main Hall",
            "organizer": "Dept of ECE",
            "residence_type": "Day Scholar"
        },
        headers={"Authorization": f"Bearer {student_token}"}
    )
    req_id = create_res.json()["id"]

    client.post(f"/api/v1/od-requests/{req_id}/faculty-action", json={"approve": True}, headers={"Authorization": f"Bearer {faculty_token}"})
    client.post(f"/api/v1/od-requests/{req_id}/coordinator-action", json={"approve": True}, headers={"Authorization": f"Bearer {coordinator_token}"})

    fake_pdf = ("early_proof.pdf", b"%PDF-1.4 early file", "application/pdf")
    proof_res = client.post(
        f"/api/v1/od-requests/{req_id}/completion-evidence",
        data={"completion_summary": "Tried to submit early before event ended."},
        files={"files": fake_pdf},
        headers={"Authorization": f"Bearer {student_token}"}
    )
    assert proof_res.status_code == 400
    assert "end date" in proof_res.json()["detail"].lower()

def test_coordinator_analytics_endpoint(client):
    coordinator_token = get_auth_token(client, "CO1001", "coord123")
    res = client.get("/api/v1/od-requests/analytics/coordinator", headers={"Authorization": f"Bearer {coordinator_token}"})
    assert res.status_code == 200
    data = res.json()
    assert "pending_coordinator_count" in data
    assert "completed_count" in data
    assert "total_submissions_count" in data

def test_hosteller_without_parent_consent_fails(client):
    student_token = get_auth_token(client, "RA2511026020400", "student123")
    res = client.post(
        "/api/v1/od-requests",
        json={
            "reason": "Conference",
            "start_date": "2026-08-10",
            "end_date": "2026-08-12",
            "duration_days": 3,
            "purpose": "IEEE Conference",
            "venue": "Campus Auditorium",
            "organizer": "IEEE Student Chapter",
            "residence_type": "Hosteller"
        },
        headers={"Authorization": f"Bearer {student_token}"}
    )
    assert res.status_code == 400
    assert "parent consent" in res.json()["detail"].lower()

def test_student_cannot_approve_own_request(client):
    student_token = get_auth_token(client, "RA2511026020400", "student123")
    res = client.post(
        "/api/v1/od-requests/OD-2026-001/faculty-action",
        json={"approve": True},
        headers={"Authorization": f"Bearer {student_token}"}
    )
    assert res.status_code == 403
