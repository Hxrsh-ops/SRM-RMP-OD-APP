# SRM RMP OD Platform — Production Bootstrap, Administration & Recovery Manual

This manual documents the production bootstrap process, initial MASTER_ADMIN account creation, administrative user management workflows, forced password change security policy, and emergency password recovery procedures.

---

## 1. Fresh Production Installation

When deploying the SRM RMP OD Platform onto a new production infrastructure:

1. **Database Provisioning**: Ensure a clean PostgreSQL database server is running and accessible via `POSTGRES_SERVER`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` (configured in `backend/.env`).
2. **Schema Migration**: Execute Alembic migrations to apply structural table metadata:
   ```bash
   cd backend
   alembic upgrade head
   ```
3. **Clean Database Verification**: The PostgreSQL database will initially contain 0 tables rows. No demo accounts, mock requests, or fake departments exist.

---

## 2. Bootstrap Master Administrator Creation (`create_bootstrap_admin.py`)

To create the initial **MASTER_ADMIN** account:

```bash
cd backend
python scripts/create_bootstrap_admin.py
```

### Environment Overrides (Optional)
The script respects environment variables if set in `.env` or system shell:
- `BOOTSTRAP_ADMIN_USERNAME` (Default: `ADMIN1001`)
- `BOOTSTRAP_ADMIN_EMAIL` (Default: `admin@srmist.edu.in`)
- `BOOTSTRAP_ADMIN_PASSWORD` (Default: `Admin@123456`)

> **Idempotency Safeguard**: If a user with `role = MASTER_ADMIN` already exists in PostgreSQL, the script aborts immediately with `[ABORTED]` to prevent unauthorized account overwrites.

---

## 3. Administrative User Provisioning

Once the `MASTER_ADMIN` logs into the Admin Control Center, they provision institutional accounts:

1. **Create Departments**:
   - Define Department Code (e.g. `CSE`, `ECE`, `MECH`) and Name.
2. **Create Faculty Advisors & Coordinators**:
   - Provide Employee ID, Email, Full Name, and Initial Temporary Password.
3. **Create Students**:
   - Provide Register Number, Email, Full Name, Program, Year & Section, Department, Assigned Faculty Advisor, and Temporary Password.

---

## 4. Forced Password Change Security Policy (`force_password_change`)

- Every user account created by an Admin has `force_password_change = True` set in PostgreSQL.
- On first login, the user's session payload returns `"force_password_change": true`.
- The user is prompted to change their temporary password via `/api/v1/auth/change-password`.
- Upon successful password update, `force_password_change` flips to `False` in PostgreSQL.

---

## 5. Emergency Password Recovery (`reset_password.py`)

If an administrator or user loses access or gets locked out due to failed login attempts:

Run the recovery script on the backend host:

```bash
cd backend
python scripts/reset_password.py <username_or_email> <new_password>
```

### Interactive Usage:
Running `python scripts/reset_password.py` without arguments enters interactive mode:
1. Enter Register Number, Employee ID, or Email.
2. Interactively type and confirm new password.
3. The script hashes the password with bcrypt, unlocks the account (`is_locked = False`), resets failed login attempts (`failed_login_attempts = 0`), and commits directly to PostgreSQL.
