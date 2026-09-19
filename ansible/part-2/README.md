# Flask and PostgreSQL Ansible Deployment

The `site.yml` playbook runs the roles in this order:

1. `postgres` on the `dbservers` group
2. `webapp` on the `webservers` group

## Run

Install the required Ansible collection:

```bash
ansible-galaxy collection install -r requirements.yml
```

Run the complete deployment:

```bash
ansible-playbook -i inventory.ini site.yml \
  -e 'postgres_db_password=replace-with-a-secure-password'
```

The same `postgres_db_password` variable is passed to both roles. The web app
automatically uses the first host in the `dbservers` inventory group.

## Important network rules

- Allow SSH (`22`) from your machine to both EC2 instances.
- Allow PostgreSQL (`5432`) from the web server to the database server.
- Allow the application port (`5000`) to the web server.
- Set `postgres_allowed_cidr` to the web server's CIDR instead of leaving it
  as `0.0.0.0/0` in production.

Example with a restricted database source:

```bash
ansible-playbook -i inventory.ini site.yml \
  -e 'postgres_db_password=replace-with-a-secure-password' \
  -e 'postgres_allowed_cidr=3.110.43.192/32'
```
