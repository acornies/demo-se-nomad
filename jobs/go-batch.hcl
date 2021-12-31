job "go-batch-demo" {
  type        = "batch"
  datacenters = ["dc1"]

  periodic {
    cron             = "*/5 * * * * *"
    prohibit_overlap = false
  }

  group "todo" {
    vault {
      policies = ["apps-write"]
    }

    task "insert" {
      driver = "exec"

      config {
        // image      = "acornies/demo-go-api-fiber:latest"
        // force_pull = true
        command = "demo-go-api-fiber-linux"

        args = [
          "--mode",
          "batch",
          "--task",
          "create-todo",
        ]
      }

      artifact {
        source = "http://go-api-demo-svc.service.consul:9999/demo/static/demo-go-api-fiber-linux"
      }

      env {
        DB_HOST = "${attr.unique.network.ip-address}"
      }

      template {
        data = <<EOH
DB_USER="{{ with secret "database/creds/postgresql-write"}}{{ .Data.username }}{{end}}"
DB_PASSWORD="{{ with secret "database/creds/postgresql-write"}}{{ .Data.password }}{{end}}"
EOH

        destination = "secrets/go-batch.env"
        env         = true
      }

      resources {}
    }
  }
}
