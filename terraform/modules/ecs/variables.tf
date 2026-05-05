variable "project"            { type = string }
variable "environment"        { type = string }
variable "aws_region"         { type = string }
variable "vpc_id"             { type = string }
variable "public_subnet_ids"  { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "ecr_repository_url" { type = string }
variable "image_tag"          { type = string; default = "latest" }
variable "app_port"           { type = number; default = 3000 }
variable "task_cpu"           { type = number; default = 256 }
variable "task_memory"        { type = number; default = 512 }
variable "desired_count"      { type = number; default = 2 }
variable "min_capacity"       { type = number; default = 1 }
variable "max_capacity"       { type = number; default = 4 }
variable "tags"               { type = map(string); default = {} }