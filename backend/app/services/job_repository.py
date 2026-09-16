import json
import sqlite3
import uuid
from datetime import datetime, timedelta, timezone
from pathlib import Path


DATABASE_PATH = Path(__file__).resolve().parents[2] / "data" / "jobs.db"


def _connection() -> sqlite3.Connection:
    DATABASE_PATH.parent.mkdir(parents=True, exist_ok=True)
    connection = sqlite3.connect(DATABASE_PATH)
    connection.row_factory = sqlite3.Row
    return connection


def initialize() -> None:
    with _connection() as connection:
        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS jobs (
                id TEXT PRIMARY KEY,
                source TEXT NOT NULL,
                title TEXT NOT NULL,
                company TEXT NOT NULL,
                location TEXT NOT NULL,
                country TEXT NOT NULL DEFAULT 'TR',
                description TEXT NOT NULL DEFAULT '',
                apply_url TEXT,
                required_skills TEXT NOT NULL DEFAULT '[]',
                published_at TEXT,
                fetched_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                salary TEXT
            )
            """
        )
        try:
            connection.execute("ALTER TABLE jobs ADD COLUMN salary TEXT")
        except sqlite3.OperationalError:
            pass
        connection.execute(
            "CREATE INDEX IF NOT EXISTS idx_jobs_filters ON jobs(country, published_at, source)"
        )
        
        # Kullanıcılar tablosu (Auth Sistemi)
        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY,
                email TEXT UNIQUE NOT NULL,
                hashed_password TEXT NOT NULL,
                full_name TEXT NOT NULL,
                fcm_token TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            )
            """
        )
        connection.execute(
            "CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)"
        )



def upsert_jobs(jobs: list[dict]) -> int:
    """fetch_real_jobs() çıktısını doğrudan alır ve SQLite'a yazar/günceller."""
    now = datetime.now(timezone.utc).isoformat()
    records: list[tuple] = []
    seen_ids: set[str] = set()
    for job in jobs:
        job_id = str(job.get("id", ""))
        if not job_id or job_id in seen_ids:
            continue
        seen_ids.add(job_id)
        records.append((
            job_id,
            str(job.get("source") or "unknown"),
            str(job.get("title") or "Belirtilmemiş Pozisyon"),
            str(job.get("company") or "Gizli Şirket"),
            str(job.get("location") or "Belirtilmemiş Konum"),
            str(job.get("country") or "TR").upper(),
            str(job.get("description") or ""),
            job.get("link"),
            json.dumps(job.get("required_skills") or [], ensure_ascii=False),
            job.get("published_at"),
            now,
            now,
            job.get("salary"),
        ))

    if not records:
        return 0

    initialize()
    with _connection() as connection:
        connection.executemany(
            """
            INSERT INTO jobs (
                id, source, title, company, location, country, description,
                apply_url, required_skills, published_at, fetched_at, updated_at, salary
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                title=excluded.title, company=excluded.company, location=excluded.location,
                country=excluded.country, description=excluded.description,
                apply_url=excluded.apply_url, required_skills=excluded.required_skills,
                published_at=COALESCE(excluded.published_at, jobs.published_at),
                fetched_at=excluded.fetched_at, updated_at=excluded.updated_at,
                salary=excluded.salary
            """,
            records,
        )
    return len(records)


def list_jobs(
    *, country: str | None = None, query: str | None = None, days: int | None = None,
    source: str | None = None, page: int = 1, page_size: int = 20,
) -> tuple[int, list[dict]]:
    initialize()
    clauses: list[str] = []
    values: list[object] = []
    if country and country.upper() != "ALL":
        clauses.append("country = ?")
        values.append(country.upper())
    if source:
        clauses.append("source = ?")
        values.append(source.lower())
    if query:
        clauses.append("(title LIKE ? OR company LIKE ? OR location LIKE ? OR description LIKE ?)")
        term = f"%{query.strip()}%"
        values.extend([term, term, term, term])
    if days:
        cutoff = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()
        clauses.append("COALESCE(published_at, fetched_at) >= ?")
        values.append(cutoff)

    where = f"WHERE {' AND '.join(clauses)}" if clauses else ""
    offset = (max(page, 1) - 1) * page_size
    with _connection() as connection:
        total = connection.execute(f"SELECT COUNT(*) FROM jobs {where}", values).fetchone()[0]
        rows = connection.execute(
            f"""
            SELECT id, source, title, company, location, country, description,
                   apply_url, required_skills, published_at, fetched_at, salary
            FROM jobs {where}
            ORDER BY COALESCE(published_at, fetched_at) DESC
            LIMIT ? OFFSET ?
            """,
            [*values, page_size, offset],
        ).fetchall()

    return total, [
        {**dict(row), "required_skills": json.loads(row["required_skills"])}
        for row in rows
    ]


def all_jobs_for_matching() -> list[dict]:
    """Matcher'ın beklediği şemada tüm ilanları döndürür."""
    _, jobs = list_jobs(page=1, page_size=2000)
    return [
        {
            "id": job["id"], "title": job["title"], "company": job["company"],
            "location": job["location"], "country": job["country"], "required_skills": job["required_skills"],
            "description": job.get("description", ""),
            "link": job.get("apply_url"),
            "published_at": job.get("published_at") or job.get("fetched_at", ""),
            "salary": job.get("salary"),
        }
        for job in jobs
    ]


def job_count() -> int:
    """Veritabanındaki toplam ilan sayısını döndürür."""
    initialize()
    with _connection() as connection:
        return connection.execute("SELECT COUNT(*) FROM jobs").fetchone()[0]


def last_refresh_at() -> str | None:
    initialize()
    with _connection() as connection:
        return connection.execute("SELECT MAX(fetched_at) FROM jobs").fetchone()[0]


def get_jobs_by_ids(job_ids: list[str]) -> list[dict]:
    """Belirli ID'lere sahip ilanları SQLite'tan tek bir verimli sorguyla çeker."""
    if not job_ids:
        return []
    initialize()
    placeholders = ",".join(["?"] * len(job_ids))
    with _connection() as connection:
        rows = connection.execute(
            f"""
            SELECT id, source, title, company, location, country, description,
                   apply_url, required_skills, published_at, fetched_at, salary
            FROM jobs
            WHERE id IN ({placeholders})
            """,
            job_ids,
        ).fetchall()

    return [
        {
            "id": row["id"],
            "title": row["title"],
            "company": row["company"],
            "location": row["location"],
            "country": row["country"],
            "required_skills": json.loads(row["required_skills"]),
            "description": row["description"] or "",
            "link": row["apply_url"],
            "published_at": row["published_at"] or row["fetched_at"] or "",
            "salary": row["salary"],
        }
        for row in rows
    ]


# ---------------------------------------------------------------------------
# Kullanıcı Yönetimi (Auth Sistemi)
# ---------------------------------------------------------------------------

def create_user(email: str, hashed_password: str, full_name: str) -> dict:
    """Yeni kullanıcı oluşturur ve veritabanına kaydeder."""
    initialize()
    user_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()
    clean_email = email.strip().lower()

    with _connection() as connection:
        connection.execute(
            """
            INSERT INTO users (id, email, hashed_password, full_name, fcm_token, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (user_id, clean_email, hashed_password, full_name.strip(), None, now, now),
        )

    return {
        "id": user_id,
        "email": clean_email,
        "full_name": full_name.strip(),
        "created_at": now,
    }


def get_user_by_email(email: str) -> dict | None:
    """E-posta adresine göre kullanıcı kaydını döner (şifre doğrulaması için hash dahil)."""
    initialize()
    clean_email = email.strip().lower()
    with _connection() as connection:
        row = connection.execute(
            "SELECT id, email, hashed_password, full_name, fcm_token, created_at FROM users WHERE email = ?",
            (clean_email,),
        ).fetchone()
        if row:
            return dict(row)
    return None


def get_user_by_id(user_id: str) -> dict | None:
    """ID'ye göre kullanıcı kaydını döner (şifre hash'i hariç)."""
    initialize()
    with _connection() as connection:
        row = connection.execute(
            "SELECT id, email, full_name, fcm_token, created_at FROM users WHERE id = ?",
            (user_id,),
        ).fetchone()
        if row:
            return dict(row)
    return None


def update_user_fcm_token(user_id: str, fcm_token: str) -> bool:
    """Kullanıcının FCM bildirim token'ını günceller."""
    initialize()
    now = datetime.now(timezone.utc).isoformat()
    with _connection() as connection:
        cursor = connection.execute(
            "UPDATE users SET fcm_token = ?, updated_at = ? WHERE id = ?",
            (fcm_token.strip(), now, user_id),
        )
        return cursor.rowcount > 0

