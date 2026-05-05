variable "project"      { type = string }
variable "environment"  { type = string }
variable "aws_region"   { type = string }
variable "cluster_name" { type = string }
variable "service_name" { type = string }
variable "alb_arn"      { type = string }
variable "tags"         { type = map(string); default = {} }