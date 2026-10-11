variable "project" {
    default = "roboshop"
}

variable "environment" {
    default = "dev"
}

variable "instance_type"{
    type = string
    default = "t2.micro"
}

variable "component"{
    type = string
}

variable "app_version"{
    type = string
    default = "v3"
}

variable "rule_priority"{
    type = string
}

variable "domain_name"{
    type = string
    default = "sivadevops.in"
}