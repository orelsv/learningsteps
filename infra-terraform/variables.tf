variable "resource_group_name" {
  default = "learningsteps-rg"
}

variable "location" {
  default = "westeurope"
}

variable "db_password" {
  type      = string
  sensitive = true
}
