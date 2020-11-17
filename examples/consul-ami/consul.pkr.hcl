variable "aws_region" {
  default = "us-east-1"
}

variable "consul_version" {
  default = "1.8.5"
}

variable "download_url" {
  default = "https://releases.hashicorp.com/consul/1.8.5/consul_1.8.5_linux_amd64.zip"
}

variable "access_key" {}

variable "secret_key" {}

source "amazon-ebs" "consul" {
  ami_name         = "consul"
  access_key       = var.access_key
  secret_key       = var.secret_key
  source_ami       = "ami-029c0fbe456d58bd1"
  region           = var.aws_region
  ami_description  = "A RHEL 7.7 Image that has Consul installed."
  instance_type    = "m5a.large"
  ssh_username     = "ec2-user"
  force_deregister = true
}

build {
  sources = [
    "sources.amazon-ebs.consul"
  ]

  provisioner "shell" {
    inline = [
      "mkdir -p /tmp/terraform-aws-consul/modules",
      "sudo yum install -y wget",
      "wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
      "sudo yum install -y ./epel-release-latest-7.noarch.rpm",
      "sudo rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7",
      "sudo yum install -y python-pip",
      "umask \"0022\"",
      "sudo pip install --upgrade pip",
      "sudo pip install awscli"
    ]
  }

  provisioner "file" {
    source       = "${path.root}/../../modules/"
    destination  = "/tmp/terraform-aws-consul/modules"
    pause_before = "30s"
  }

  provisioner "shell" {
    inline = [
      "if test -n \"${var.download_url}\"; then",
      " /tmp/terraform-aws-consul/modules/install-consul/install-consul --download-url ${var.download_url};",
      "else",
      " /tmp/terraform-aws-consul/modules/install-consul/install-consul --version ${var.consul_version};",
      "fi"
    ]
    pause_before = "30s"
  }

  provisioner "shell" {
    inline = [
      "/tmp/terraform-aws-consul/modules/install-dnsmasq/install-dnsmasq"
    ]
    pause_before = "30s"
  }
}