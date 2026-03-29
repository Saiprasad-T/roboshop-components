variable "project" {
    default = "roboshop"
}

variable "environment" {
    default = "dev"
}

variable "instance_type" {
  type        = string
  default = "t3.micro"
}

variable "ec2_tags" {
  type        = map
  default = { }
}

variable "component" {
    type = string
}

variable "rule_priority" {
    
}

variable "domain_name" {
    default = "devopswiththota.online"
}

variable "zone_id" {
  type        = string
  default     = "Z054884433KSB5YRIKHVR"
  description = "zone_id"
}

variable "domain" {
  type        = string
  default     = "devopswiththota.online"
}

variable "launch_template_tags" {
  type        = map
  default     = { }
}