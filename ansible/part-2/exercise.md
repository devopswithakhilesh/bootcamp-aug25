# Exercise: Deploy Flask and PostgreSQL with Ansible Roles

## Objective

Use Ansible to configure two EC2 instances:

- A PostgreSQL database server
- A Flask web application server

The database role must finish successfully before the web application role
starts.

## Architecture

```text
Your computer
     |
     | Ansible over SSH
     |
     +---- Web server (Flask/Gunicorn) ---- PostgreSQL server
                  port 5000                     port 5432
```

## Prerequisites

- Two Amazon Linux EC2 instances
- An SSH private key
- Ansible installed on your computer
- SSH (`22`) allowed from your computer to both instances
- PostgreSQL (`5432`) allowed from the web server to the database server
- Application port (`5000`) allowed to the web server

## Step 1: Configure the inventory

Update `inventory.ini` with your EC2 addresses and private-key path:

```ini
[webservers]
WEB_PUBLIC_IP ansible_user=ec2-user ansible_ssh_private_key_file=../ansible.pem

[dbservers]
DB_PUBLIC_IP ansible_user=ec2-user ansible_ssh_private_key_file=../ansible.pem
```

Test connectivity:

```bash
ansible all -i inventory.ini -m ping
```

Both hosts should return `pong`.

## Step 2: Review the PostgreSQL role

The `postgres` role should:

1. Install PostgreSQL.
2. Initialize the database cluster.
3. Listen for remote connections.
4. update `pg_hba.conf`.
5. Start and enable PostgreSQL.
6. Create an application user and database.

Review these files:

```text
postgres/defaults/main.yml
postgres/tasks/main.yml
postgres/handlers/main.yml
```

Do not store a production database password in Git.

## Step 3: Review the web application role

The `webapp` role should:

1. Install Python.
2. Create a dedicated service account.
3. Copy the Flask application.
4. Create a Python virtual environment.
5. Install the Python dependencies.
6. Render the database environment file.
7. Run Gunicorn as a systemd service.
8. Verify the `/health` endpoint.

Review these files:

```text
webapp/defaults/main.yml
webapp/tasks/main.yml
webapp/handlers/main.yml
webapp/templates/flask-webapp.env.j2
webapp/templates/flask-webapp.service.j2
```

On the web server, Ansible creates the database environment file at:

```text
/opt/flask-webapp/app.env
```

## Step 4: Review role ordering

Open `site.yml`. It contains two plays:

1. Run `postgres` against `dbservers`.
2. Run `webapp` against `webservers`.

Ansible executes plays from top to bottom. If the database play fails, the
deployment stops before a working web application is deployed.

## Step 5: Install the required collection

The PostgreSQL role uses modules from `community.postgresql`:

```bash
ansible-galaxy collection install -r requirements.yml
```

## Step 6: Check the playbook

Run a syntax check:

```bash
ansible-playbook -i inventory.ini site.yml --syntax-check
```

## Step 7: Deploy the application

Run the playbook with a database password:

```bash
ansible-playbook -i inventory.ini site.yml \
  -e 'postgres_db_password=choose-a-secure-password'
```

For better security, restrict PostgreSQL access to the web server:

```bash
ansible-playbook -i inventory.ini site.yml \
  -e 'postgres_db_password=choose-a-secure-password' \
  -e 'postgres_allowed_cidr=WEB_SERVER_IP/32'
```

## Step 8: Verify the deployment

From your computer:

```bash
curl http://WEB_PUBLIC_IP:5000/
curl http://WEB_PUBLIC_IP:5000/health
```

Expected health response:

```json
{"database":"connected","status":"healthy"}
```

On the web server, inspect the service if needed:

```bash
sudo systemctl status flask-webapp
sudo journalctl -u flask-webapp --no-pager -n 50
```

On the database server:

```bash
sudo systemctl status postgresql
sudo -u postgres psql -c '\l'
sudo -u postgres psql -c '\du'
```

## Step 9: Test idempotency

Run the same playbook again:

```bash
ansible-playbook -i inventory.ini site.yml \
  -e 'postgres_db_password=choose-a-secure-password'
```

Most tasks should report `ok` instead of `changed`, and the application should
continue working.

## Troubleshooting

- **SSH fails:** Check the key path, `ec2-user`, and the port `22` security rule.
- **Database connection fails:** Check port `5432`, `postgresql.conf`,
  `pg_hba.conf`, the database address, and the password.
- **Web page does not open:** Check port `5000` and the `flask-webapp` service.
- **PostgreSQL module is missing:** Install the collection from
  `requirements.yml`.

## Challenge Tasks

1. Store the database password with Ansible Vault.
2. Put Nginx in front of Gunicorn on port `80`.
3. Add a Flask endpoint that writes and reads records from PostgreSQL.
4. Replace public database traffic with EC2 private IP addresses.
5. Add tags so each role can be run independently.
