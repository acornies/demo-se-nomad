job "go-api-demo" {
  type        = "service"
  datacenters = ["dc1"]

  group "svc" {
    vault {
      policies = ["apps-read"]
    }

    network {
      mode = "bridge"

      port "http" {
        to = 3000
      }
    }

    service {
      tags = ["urlprefix-go-api-demo-svc.service.consul/", "urlprefix-/demo strip=/demo"]

      port = "http"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

    task "server" {
      driver = "docker"

      config {
        image      = "acornies/demo-go-api-fiber:latest"
        ports      = ["http"]
        force_pull = true
        command    = "/app/demo-go-api-fiber"

        args = [
          "--mode",
          "server",
        ]
      }

      env {
        DB_HOST = "${attr.unique.network.ip-address}"
      }

      template {
        data = <<EOH
DB_USER="{{ with secret "database/creds/postgresql-read"}}{{ .Data.username }}{{end}}"
DB_PASSWORD="{{ with secret "database/creds/postgresql-read"}}{{ .Data.password }}{{end}}"
EOH

        destination = "secrets/go-api.env"
        env         = true
      }

      resources {}
    }
  }
}
