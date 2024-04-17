# Definição do provider Docker
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
    twingate = {
      source = "twingate/twingate"
  }
}
}
#Controlador Zero Trust
provider "twingate" {
  api_token = "94JkLc_uYvJSfot_mADPjtt-CNbhhGhNOHKD94readBAC-GcXHszGD1dl7jiY92Lz0k8m_acvQ0TmK3QoywQiDbDhl-eZucFB4E8QtJpMYpT0n_HDWBfQvfThPE5EHoOou7pQA"
  network   = "iacpucpr"
}
resource "twingate_remote_network" "terraform_network" {
  name = "terraform_remote_network"
}
resource "twingate_connector" "db_data" {
  remote_network_id = twingate_remote_network.terraform_network.id
  status_updates_enabled = true
}
resource "twingate_group" "iacpucpr" {
  name = "iacpucpr_group"
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
# Creating a Docker Image ubuntu with the latest as the Tag.
resource "docker_image" "ubuntu" {
  name = "ubuntu:latest"
}
# Creating a Docker Container using the latest ubuntu image.
resource "docker_container" "SFTP-SSH" {
  image             = docker_image.ubuntu.image_id
  name              = "ubuntu-sftp-ssh"
  must_run          = true
  command = [
    "tail",
    "-f",
    "/dev/null"
  ]
  ports {
    internal = 22
    external = 221
  }
}
# Creating a Docker Image ubuntu with the latest as the Tag.
resource "docker_image" "debian" {
  name = "debian:latest"
}
resource "docker_network" "backup_network" {
  name = "backup_network"
}
# Creating a Docker Container using the latest ubuntu image.
resource "docker_container" "backup-INC001" {
  image             = docker_image.debian.image_id
  name              = "backup-INC001"
  network_mode = "backup_network"
  must_run          = true
  command = [
    "tail",
    "-f",
    "/dev/null"
  ]
}
#resource "docker_image" "nginx" {
#  name         = "nginx:latest"
#  keep_locally = false
#}
resource "docker_container" "nginx_instance1" {
  name  = "nginx_instance1"
  image = "nginx:latest"
  networks_advanced {
    name = "nginx_network"
  }
  ports {
    internal = 80
    external = 8000
  }
}
resource "docker_container" "nginx_instance2" {
  name  = "nginx_instance2"
  image = "nginx:latest"
  networks_advanced {
    name = "nginx_network"
  }
  ports {
    internal = 81
    external = 8001
  }
}
resource "docker_volume" "db_data" {}
resource "docker_container" "db-mysql" {
  name  = "db-mysql"
  image = "mysql:5.7"
  restart = "always"
  networks_advanced {
    name = "mysql_network"
  }
# network_mode = "mysql_network"
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
provider "docker" {
  host = "unix:///var/run/docker.sock"
  }
provider "docker" {
  alias = "prod" 
  }
variable wordpress_port {
  default = "8090"
  }
resource "docker_network" "wordpress_network" {
  name = "wordpress_network"
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