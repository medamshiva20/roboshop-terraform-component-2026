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
    type = "string"
    default = "v3"
}
