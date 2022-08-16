variable "azs" { type = list(string)  }

variable "lightsail_names" { type = list(string) }

variable "blueprint_id" { default = "wordpress"  }

variable "bundle_id"  { default = "nano_2_0" }

variable "db_name" { type = string }

variable "db_database_name" { type = string }

variable "db_az" { type = string }

variable "db-user" { default = "admin" }

variable "db_blueprint_id" { default = "mysql_8_0" }

variable "db_bundle_id" { default = "micro_2_0" }
