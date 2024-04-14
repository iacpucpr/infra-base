terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }

  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

 
# Download the latest Kali Linux Docker image
resource "docker_image" "kalilinux" {
  name = "kalilinux/kali-rolling:latest"
  keep_locally = false
}
 
# Run container kalilinux based on the image
resource "docker_container" "kalilinux" {

  image = docker_image.kalilinux.image_id
  
  name  = "KaliLinux"
  network_mode = "kalilinux_net"
  restart = "always"

  ports {
    internal = 81
    external = 8001
  }

# The Kali image will exit unless there is a long running command
  command = [
    "tail",
    "-f",
    "/dev/null"
  ]

}

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = "nginx"
  restart = "always"
  network_mode = "wordpress_net"
  ports {
    internal = 80
    external = 8000
  }
}

variable wordpress_port {
  default = "8080"
}

resource "docker_volume" "db_data" {}

resource "docker_network" "wordpress_net" {
  name = "wordpress_net"
}

resource "docker_network" "kalilunux_net" {
  name = "kalilinux_net"
}
resource "docker_container" "db" {
  name  = "db"
  image = "mysql:5.7"
  restart = "always"
  network_mode = "wordpress_net"
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
  network_mode = "wordpress_net"
  env = [
    "WORDPRESS_DB_HOST=db:3306",
    "WORDPRESS_DB_PASSWORD=wordpress"
  ]
  ports {
    internal = "8080"
    external = "${var.wordpress_port}"
  }
}

# Recurso de execucao local para invocar o script Bash
resource "null_resource" "run_random_docker_command" {
  triggers = {
    always_run = "${timestamp()}"
  }

}
