# demo-se-nomad

Thanks for your consideration. The following steps facilitate a working demo that a HashiCOrp Solutions Engineer can use to demonstrate Nomad workloads. This repos assumes you've also cloned [HashiQube](https://servian.github.io/hashiqube/#/).

WIP

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
nomad job run go-api.hcl
nomad job run go-batch.hcl
```
