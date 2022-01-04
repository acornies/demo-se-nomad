# demo-se-nomad

The following steps facilitate a working demo that a HashiCorp Solutions Engineer can use to demonstrate Nomad workloads. This repo assumes you've cloned [HashiQube](https://servian.github.io/hashiqube/#/) and have installed the dependencies (Vagrant, VirtualBox etc).

## HashiQube Steps

```shell
vagrant up --provision-with bootstrap,docker,consul,vault,nomad

# Set new Vault root token
# export VAULT_TOKEN=xxx

# Get the Nomad cluster and server policy files
curl https://nomadproject.io/data/vault/nomad-server-policy.hcl -O -s -L
curl https://nomadproject.io/data/vault/nomad-cluster-role.json -O -s -L

# Write the policy to Vault
vault policy write nomad-server nomad-server-policy.hcl

# Create the token role with Vault
vault write /auth/token/roles/nomad-cluster @nomad-cluster-role.json

# Create Nomad orphan token
vault token create -policy nomad-server -period 72h -orphan

# vagrant up --provision-with nomad
# vagrant up --provision-with postgresql

# run jobs
nomad job run jobs/go-api.hcl
nomad job run jobs/go-batch.hcl
```

There are a few modifications to the postgresql Vagrant target:

1. Create a separate `tech_demo` database

   ```shell
   sudo docker exec postgres psql -U root -c 'CREATE DATABASE tech_demo'
   ```

2. Update the connection url:

   ```shell
   vault write database/config/postgresql \
    plugin_name=postgresql-database-plugin \
    allowed_roles=postgresql-read,postgresql-write \
    connection_url='postgresql://root:rootpassword@localhost:5432/tech_demo?sslmode=disable'
   ```

3. Create a read-only role

   ```shell
   vault write database/roles/postgresql-read db_name=postgresql \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl=1h max_ttl=24h
   ```

4. Create a write role

   ```shell
   vault write database/roles/postgresql-write db_name=postgresql \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
    GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO \"{{name}}\";
    GRANT INSERT, UPDATE, DELETE, SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl=1h max_ttl=24h
   ```

5. Create the todos table:

   ```shell
   sudo docker exec postgres psql -U root -c 'CREATE TABLE IF NOT EXISTS todos (
    id serial PRIMARY KEY,
    description TEXT,
    due_date TIMESTAMP
    )' tech_demo
   ```

## Run Jobs

HashiQube should automatically run the `fabio` job as your web proxy. Run the jobs in the jobs folder to start the demo.

```shell
nomad job run jobs/go-api.hcl
nomad job run jobs/go-batch.hcl
```

Visit: http://go-api-demo-svc.service.consul:9999/demo/static/index.html in a browser.

## Related Repositories

The source code for the jobs reside at: https://github.com/acornies/demo-go-api-fiber.