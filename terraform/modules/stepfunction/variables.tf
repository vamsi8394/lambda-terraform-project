variable "state_machine_name" {
  description = "Name of the Step Functions state machine"
  type        = string
}

variable "description" {
  description = "Description of the Step Functions state machine"
  type        = string
  default     = ""
}

variable "definition" {
  description = "Amazon States Language definition of the state machine"
  type        = string
}

variable "iam_policy_statements" {
  description = "List of IAM policy statements for the state machine role"
  type = list(object({
    sid       = string
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to the state machine"
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}
