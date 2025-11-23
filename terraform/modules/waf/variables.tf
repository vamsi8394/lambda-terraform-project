variable "name" {
  description = "Name of the Web ACL"
  type        = string
}

variable "scope" {
  description = "Scope of the Web ACL (CLOUDFRONT or REGIONAL)"
  type        = string
  default     = "REGIONAL"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
