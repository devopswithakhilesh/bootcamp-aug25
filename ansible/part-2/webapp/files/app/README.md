# Flask PostgreSQL App

This Flask app connects to PostgreSQL and provides a form for creating and
listing contacts. It creates the `contacts` table automatically.

## Run locally

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

export DB_HOST=13.233.80.28
export DB_PORT=5432
export DB_NAME=appdb
export DB_USER=appuser
export DB_PASSWORD='your-password'

python app.py
```

Open `http://localhost:5000/` to create and view contacts, or use
`http://localhost:5000/health` for a database health check.

The PostgreSQL server must allow port `5432` from the web server, and
`postgresql.conf`/`pg_hba.conf` must permit the remote connection.
