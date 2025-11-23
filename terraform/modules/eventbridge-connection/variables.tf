variable "connection_name" {
  description = "Name of the EventBridge connection"
  type        = string
}

variable "description" {
  description = "Description of the connection"
  type        = string
  default     = ""
}

variable "authorization_type" {
  description = "Type of authorization (BASIC, OAUTH_CLIENT_CREDENTIALS, API_KEY, INVOCATION_HTTP_PARAMETERS)"
  type        = string
  default     = "BASIC"
}

variable "jira_email" {
  description = "Jira user email for basic auth"
  type        = string
  sensitive   = true
}

variable "jira_api_token" {
  description = "Jira API token for basic auth"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to the connection"
  type        = map(string)
  default     = {}
}
