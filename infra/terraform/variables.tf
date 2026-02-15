variable "project_id" { type = string }

variable "region" {
  type    = string
  default = "europe-west1"
}

variable "zone" {
  type    = string
  default = "europe-west1-b"
}

variable "ssh_user" {
  type    = string
  default = "ubuntu"
}

variable "ssh_public_key_path" {
  type = string
}

variable "admin_cidr" {
  type = string
}

variable "subnet_cidr" {
  type    = string
  default = "10.50.0.0/24"
}
