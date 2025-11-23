variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "api_description" {
  description = "Description of the API Gateway"
  type        = string
  default     = ""
}

variable "stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
  default     = "stage1"
}

variable "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "resource_path" {
  description = "API resource path"
  type        = string
  default     = "webhook"
}

variable "http_method" {
  description = "HTTP method"
  type        = string
  default     = "POST"
}

variable "binary_media_types" {
  description = "Binary media types supported by the API"
  type        = list(string)
  default     = ["*/*"]
}

variable "throttling_rate_limit" {
  description = "Throttling rate limit"
  type        = number
  default     = 1000
}

variable "throttling_burst_limit" {
  description = "Throttling burst limit"
  type        = number
  default     = 500
}

variable "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL to associate with the API Gateway stage"
  type        = string
  default     = ""
}

variable "enable_cors" {
  description = "Whether to enable CORS"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
