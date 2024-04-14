# Definição do provider Docker
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Criação das redes isoladas no Docker
resource "null_resource" "create_networks" {
  provisioner "local-exec" {
    command = <<-EOT
      docker network create --subnet=192.168.0.0/24 nginx_network
      docker network create --subnet=172.16.0.0/24 mysql_network
    EOT
  }
}

# Criação dos containers Nginx
resource "docker_container" "nginx_instance1" {
  name  = "nginx_instance1"
  image = "nginx:latest"
  networks_advanced {
    name = "nginx_network"
  }
}

resource "docker_container" "nginx_instance2" {
  name  = "nginx_instance2"
  image = "nginx:latest"
  networks_advanced {
    name = "nginx_network"
  }
}

resource "docker_container" "nginx_instance3" {
  name  = "nginx_instance3"
  image = "nginx:latest"
  networks_advanced {
    name = "nginx_network"
  }
}

provider "docker" {
  alias = "prod"
}

variable wordpress_port {
  default = "8090"
}

resource "docker_volume" "db_data" {}

resource "docker_network" "wordpress_network" {
  name = "wordpress_network"
}

resource "docker_container" "db" {
  name  = "db"
  image = "mysql:5.7"
  restart = "always"
  network_mode = "wordpress_network"
  env = [
     "MYSQL_ROOT_PASSWORD=wordpress",
     "MYSQL_PASSWORD=wordpress",
     "MYSQL_USER=wordpress",
     "MYSQL_DATABASE=wordpress"
  ]
  mounts {
    type = "volume"
    target = "/var/lib/mysql"
    source = "db_data"
  }
}

resource "docker_container" "wordpress" {
  name  = "wordpress"
  image = "wordpress:latest"
  restart = "always"
  network_mode = "wordpress_network"
  env = [
    "WORDPRESS_DB_HOST=db:3306",
    "WORDPRESS_DB_PASSWORD=wordpress"
  ]
  ports {
    internal = "8090"
    external = "${var.wordpress_port}"
  }
}
