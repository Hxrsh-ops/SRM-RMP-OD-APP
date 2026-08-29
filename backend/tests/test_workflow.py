from datetime import date, timedelta

def get_auth_token(client, username, password):
    res = client.post("/api/v1/auth/login", data={"username": username, "password": password})
    return res.json()["access_token"]

def test_full_multi_role_approval_and_completion_proof_workflow(client):
    student_token = get_auth_token(client, "RA2511026020400", "Student@123")
    faculty_token = get_auth_token(client, "FA1001", "Faculty@123")
    coordinator_token = get_auth_token(client, "CO1001", "Coord@123")

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

    # 5. Faculty Advisor verifies proof -> COMPLETED in Standard FA_ONLY mode
    fac_verify_res = client.post(
        f"/api/v1/od-requests/{req_id}/faculty-action",
        json={"approve": True, "comment": "Verified certificate and prize evidence."},
        headers={"Authorization": f"Bearer {faculty_token}"}
    )
    assert fac_verify_res.status_code == 200
    assert fac_verify_res.json()["status"] == "COMPLETED"

def test_evidence_submission_before_end_date_fails(client):
    student_token = get_auth_token(client, "RA2511026020400", "Student@123")
    faculty_token = get_auth_token(client, "FA1001", "Faculty@123")
    coordinator_token = get_auth_token(client, "CO1001", "Coord@123")

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
    coordinator_token = get_auth_token(client, "CO1001", "Coord@123")
    res = client.get("/api/v1/od-requests/analytics/coordinator", headers={"Authorization": f"Bearer {coordinator_token}"})
    assert res.status_code == 200
    data = res.json()
    assert "pending_coordinator_count" in data
    assert "completed_count" in data
    assert "total_submissions_count" in data

def test_hosteller_without_parent_consent_fails(client):
    student_token = get_auth_token(client, "RA2511026020400", "Student@123")
    res = client.post(
        "/api/v1/od-requests",
        json={
            "reason": "Conference",
            "start_date": "2026-11-10",
            "end_date": "2026-11-12",
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
    student_token = get_auth_token(client, "RA2511026020400", "Student@123")
    res = client.post(
        "/api/v1/od-requests/OD-2026-001/faculty-action",
        json={"approve": True},
        headers={"Authorization": f"Bearer {student_token}"}
    )
    assert res.status_code == 403

def test_direct_hod_workflow_routing_and_approval(client):
    admin_token = get_auth_token(client, "ADMIN1001", "Admin@123456")
    student_token = get_auth_token(client, "RA2511026020400", "Student@123")
    fa_token = get_auth_token(client, "FA1001", "Faculty@123")
    hod_token = get_auth_token(client, "HOD1001", "Hod@123456")
    coord_token = get_auth_token(client, "CO1001", "Coord@123")

    # 1. Update Org Setting to DIRECT_HOD mode
    set_res = client.put(
        "/api/v1/admin/settings",
        json={"workflow_mode": "DIRECT_HOD", "evidence_workflow_mode": "FA_ONLY"},
        headers={"Authorization": f"Bearer {admin_token}"}
    )
    assert set_res.status_code == 200

    # 2. Student submits OD request (Starts at assigned Faculty Advisor)
    create_res = client.post(
        "/api/v1/od-requests",
        json={
            "reason": "Direct HOD Workshop",
            "start_date": "2026-10-01",
            "end_date": "2026-10-02",
            "duration_days": 2,
            "purpose": "HOD Level Approval Test",
            "venue": "Campus Hall",
            "organizer": "Department",
            "residence_type": "Day Scholar"
        },
        headers={"Authorization": f"Bearer {student_token}"}
    )
    assert create_res.status_code == 201
    od_data = create_res.json()
    req_id = od_data["id"]
    assert od_data["status"] == "PENDING_FACULTY"

    # Faculty Advisor approves -> in DIRECT_HOD mode, forwards directly for HOD review (bypassing coordinator)
    fac_approve = client.post(
        f"/api/v1/od-requests/{req_id}/faculty-action",
        json={"approve": True, "comment": "Faculty verified. Forwarding for HOD approval."},
        headers={"Authorization": f"Bearer {fa_token}"}
    )
    assert fac_approve.status_code == 200
    assert fac_approve.json()["status"] == "PENDING_COORDINATOR"

    # 3. Verify Coordinator does NOT see it in pending queue in DIRECT_HOD mode
    coord_list = client.get("/api/v1/od-requests?include_history=false", headers={"Authorization": f"Bearer {coord_token}"})
    assert all(r["id"] != req_id for r in coord_list.json())

    # 4. Verify HOD DOES see it in pending queue
    hod_list = client.get("/api/v1/od-requests?include_history=false", headers={"Authorization": f"Bearer {hod_token}"})
    assert any(r["id"] == req_id for r in hod_list.json())

    # 5. HOD approves directly
    hod_approve = client.post(
        f"/api/v1/od-requests/{req_id}/coordinator-action",
        json={"approve": True, "comment": "Approved by HOD directly."},
        headers={"Authorization": f"Bearer {hod_token}"}
    )
    assert hod_approve.status_code == 200
    assert hod_approve.json()["status"] == "APPROVED_AWAITING_EVIDENCE"

    # Reset setting back to STANDARD
    client.put(
        "/api/v1/admin/settings",
        json={"workflow_mode": "STANDARD", "evidence_workflow_mode": "FA_ONLY"},
        headers={"Authorization": f"Bearer {admin_token}"}
    )

def test_hod_escalation_to_dean(client):
    admin_token = get_auth_token(client, "ADMIN1001", "Admin@123456")
    student_token = get_auth_token(client, "RA2511026020401", "Student@123")
    fa_token = get_auth_token(client, "FA1001", "Faculty@123")
    hod_token = get_auth_token(client, "HOD1001", "Hod@123456")
    dean_token = get_auth_token(client, "DEAN1001", "Dean@123456")

    # Set DIRECT_HOD mode for easy routing to HOD
    client.put(
        "/api/v1/admin/settings",
        json={"workflow_mode": "DIRECT_HOD", "evidence_workflow_mode": "FA_ONLY"},
        headers={"Authorization": f"Bearer {admin_token}"}
    )

    create_res = client.post(
        "/api/v1/od-requests",
        json={
            "reason": "International Symposium",
            "start_date": "2026-10-15",
            "end_date": "2026-10-18",
            "duration_days": 4,
            "purpose": "Escalation to Dean Test",
            "venue": "National Arena",
            "organizer": "Global Org",
            "residence_type": "Day Scholar"
        },
        headers={"Authorization": f"Bearer {student_token}"}
    )
    req_id = create_res.json()["id"]

    # FA approves initial request
    client.post(
        f"/api/v1/od-requests/{req_id}/faculty-action",
        json={"approve": True, "comment": "Approved and forwarded."},
        headers={"Authorization": f"Bearer {fa_token}"}
    )

    # HOD escalates to Dean
    esc_res = client.post(
        f"/api/v1/od-requests/{req_id}/coordinator-action",
        json={"approve": True, "escalate_to": "DEAN", "comment": "Escalating multi-day outstation event for Dean concurrence."},
        headers={"Authorization": f"Bearer {hod_token}"}
    )
    assert esc_res.status_code == 200

    # HOD pending queue no longer shows it
    hod_list = client.get("/api/v1/od-requests?include_history=false", headers={"Authorization": f"Bearer {hod_token}"})
    assert all(r["id"] != req_id for r in hod_list.json())

    # Dean pending queue now shows it
    dean_list = client.get("/api/v1/od-requests?include_history=false", headers={"Authorization": f"Bearer {dean_token}"})
    assert any(r["id"] == req_id for r in dean_list.json())

    # Dean approves
    dean_app = client.post(
        f"/api/v1/od-requests/{req_id}/coordinator-action",
        json={"approve": True, "comment": "Campus clearance granted by Dean."},
        headers={"Authorization": f"Bearer {dean_token}"}
    )
    assert dean_app.status_code == 200
    assert dean_app.json()["status"] == "APPROVED_AWAITING_EVIDENCE"

    # Reset setting
    client.put(
        "/api/v1/admin/settings",
        json={"workflow_mode": "STANDARD", "evidence_workflow_mode": "FA_ONLY"},
        headers={"Authorization": f"Bearer {admin_token}"}
    )
