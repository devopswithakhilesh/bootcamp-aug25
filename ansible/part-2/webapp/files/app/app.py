import os

import psycopg
from flask import Flask, jsonify, redirect, render_template, request, url_for
from psycopg.rows import dict_row


app = Flask(__name__)


def get_db_connection():
    """Create a PostgreSQL connection from environment variables."""
    return psycopg.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", "5432")),
        dbname=os.getenv("DB_NAME", "appdb"),
        user=os.getenv("DB_USER", "appuser"),
        password=os.getenv("DB_PASSWORD", "changeme"),
        connect_timeout=5,
        row_factory=dict_row,
    )


def create_contacts_table(connection):
    with connection.cursor() as cursor:
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS contacts (
                id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                email VARCHAR(255) NOT NULL,
                created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
            """
        )


@app.route("/", methods=["GET", "POST"])
def index():
    try:
        with get_db_connection() as connection:
            create_contacts_table(connection)

            if request.method == "POST":
                name = request.form.get("name", "").strip()
                email = request.form.get("email", "").strip()

                if not name or not email:
                    return (
                        render_template(
                            "index.html",
                            contacts=[],
                            error="Name and email are required.",
                            form={"name": name, "email": email},
                        ),
                        400,
                    )

                if len(name) > 100 or len(email) > 255:
                    return (
                        render_template(
                            "index.html",
                            contacts=[],
                            error="Name or email is too long.",
                            form={"name": name, "email": email},
                        ),
                        400,
                    )

                with connection.cursor() as cursor:
                    cursor.execute(
                        "INSERT INTO contacts (name, email) VALUES (%s, %s)",
                        (name, email),
                    )

                return redirect(url_for("index", created="1"))

            with connection.cursor() as cursor:
                cursor.execute(
                    """
                    SELECT id, name, email, created_at
                    FROM contacts
                    ORDER BY id DESC
                    """
                )
                contacts = cursor.fetchall()

        return render_template(
            "index.html",
            contacts=contacts,
            created=request.args.get("created") == "1",
            form={},
        )
    except psycopg.Error:
        app.logger.exception("Unable to connect to PostgreSQL")
        return (
            render_template(
                "index.html",
                contacts=[],
                error="Unable to connect to PostgreSQL.",
                form={},
            ),
            503,
        )


@app.get("/health")
def health():
    try:
        with get_db_connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")

        return jsonify(status="healthy", database="connected")
    except psycopg.Error:
        return jsonify(status="unhealthy", database="disconnected"), 503


if __name__ == "__main__":
    app.run(
        host=os.getenv("APP_HOST", "0.0.0.0"),
        port=int(os.getenv("APP_PORT", "5000")),
    )
