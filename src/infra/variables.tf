variable "vpc-cidr" {
  type        = string
  default     = "172.31.0.0/16"
  description = "value for vpc cidr range"
}

variable "public-1-cidr" {
  type    = string
  default = "172.31.1.0/24"
}

variable "public-2-cidr" {
  type    = string
  default = "172.31.2.0/24"
}

variable "private-1-cidr" {
  type    = string
  default = "172.31.101.0/24"
}

variable "private-2-cidr" {
  type    = string
  default = "172.31.102.0/24"
}


variable "atier-az" {
  type    = string
  default = "us-east-1a"
}


variable "btier-az" {
  type    = string
  default = "us-east-1b"
}

variable "app1a-cidr" {
  type    = string
  default = "172.31.101.0/24"
}

variable "app1b-cidr" {
  type    = string
  default = "172.31.102.0/24"
}

variable "aws-ami" {
  type    = string
  default = "ami-0cff7528ff583bf9a"
}

variable "private-ipa" {
  type = map(string)
  default = {
    web1 = "172.31.1.21"
    app1 = "172.31.101.21"
    db   = "172.31.101.99"
  }
}


variable "private-ipb" {
  type = map(string)
  default = {
    "2-web" = "172.31.2.22"
    "3-web" = "172.31.2.23"
    "2-app" = "172.31.102.22"
    "3-app" = "172.31.102.23"
  }
}