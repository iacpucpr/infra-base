terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_volume" "wp" {}

resource "docker_volume" "db" {}

resource "docker_network" "wordpress_net" {
  name = "wordpress_net"
}

resource "docker_network" "attackers_net" {
  name = "attackers_net"
}

###############

# Download the latest Kali Linux Docker image
resource "docker_image" "kalilinux" {
  name = "kalilinux/kali-rolling:latest"
  keep_locally = false
}

# Run container kalilinux based on the image
resource "docker_container" "kalilinux" {

  image = docker_image.kalilinux.image_id

  name  = "Atacante-KaliLinux-2"
  network_mode = "attackers_net"
  restart = "always"

#  ports {
#    internal = 81
#    external = 8001
#  }

# The Kali image will exit unless there is a long running command
  command = [
    "tail",
    "-f",
    "/dev/null"
  ]

}

###############

resource "docker_container" "wordpress-1" {
#resource "docker_container" "container-1" {
  name  = "wordpress-1"
#  name  = "container-1"
  image = "wordpress:latest"
  restart = "always"
  network_mode = "wordpress_net"
  env = [
    "WORDPRESS_DB_HOST=db:3308",
    "WORDPRESS_DB_PASSWORD=wordpress"
  ]
  ports {
    internal = "8081"
#    external = "${var.wordpress_port}"
  }
}

###############

resource "docker_container" "mysql-1" {
  name  = "mysql-1"
  image = "mysql:latest"
  restart = "always"

  ports {
    internal = 3308
#    external = 8001
  }

  env = [
     "MYSQL_ROOT_PASSWORD=wordpress",
     "MYSQL_PASSWORD=wordpress",
     "MYSQL_USER=wordpress",
     "MYSQL_DATABASE=wordpress"
  ]
}

###############

resource "docker_container" "mysql" {
#resource "docker_container" "container-2" {
  name         = "mysql"
#  name         = "container-2"
#  image        = "mysql:5.7"
  image        = "galianoppgia/image-2-dvwp_mysql_1:v2"
  restart      = "always"
  network_mode = docker_network.wordpress_net.name

  env = [
    "MYSQL_ROOT_PASSWORD=password",
    "MYSQL_DATABASE=wordpress",
    "MYSQL_USER=wordpress",
    "MYSQL_PASSWORD=wordpress"
  ]

  volumes {
    volume_name    = docker_volume.db.name
    container_path = "/var/lib/mysql"
  }
}

resource "docker_container" "wordpress" {
  name         = "wordpress"
#  image        = "wordpress:latest"
  image        = "galianoppgia/image-3-dvwp_wordpress_1:v2"
  restart      = "always"
  network_mode = docker_network.wordpress_net.name

  env = [
    "WORDPRESS_DB_HOST=mysql:3306",
    "WORDPRESS_DB_NAME=wordpress",
    "WORDPRESS_DB_USER=wordpress",
    "WORDPRESS_DB_PASSWORD=wordpress"
  ]

  ports {
    internal = 80
    external = 31337
  }

  volumes {
    volume_name    = docker_volume.wp.name
    container_path = "/var/www/html"
  }

  depends_on = [
    docker_container.mysql
  ]
}

resource "docker_container" "phpmyadmin" {
  name         = "phpmyadmin"
  image        = "galianoppgia/image-1-dvwp_phpmyadmin_1:v2"
#  image        = "phpmyadmin/phpmyadmin:latest"
  restart      = "always"
  network_mode = docker_network.wordpress_net.name

  env = [
    "PMA_ARBITRARY=1",
    "PMA_HOST=mysql"
  ]

  ports {
    internal = 80
    external = 31338
  }

  depends_on = [
    docker_container.mysql
  ]
}

resource "docker_image" "wp_cli" {
  name         = "wordpress:cli-php7.1"
  keep_locally = false
}

resource "docker_container" "wp_cli" {
  name         = "wp-cli"
  image        = docker_image.wp_cli.name
  network_mode = docker_network.wordpress_net.name

  env = [
    "APACHE_RUN_USER=www-data",
    "APACHE_RUN_GROUP=www-data"
  ]

  volumes {
    volume_name    = docker_volume.wp.name
    container_path = "/var/www/html"
  }

  volumes {
    host_path      = abspath("${path.module}/bin/install-wp.sh")
    container_path = "/usr/local/bin/install-wp"
    read_only      = true
  }

  depends_on = [
    docker_container.mysql
  ]
}


resource "null_resource" "run_random_docker_command" {
  triggers = {
    always_run = "${timestamp()}"
  }
}

