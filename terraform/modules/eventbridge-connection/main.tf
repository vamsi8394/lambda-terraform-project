resource "aws_cloudwatch_event_connection" "this" {
  name        = var.connection_name
  description = var.description

  authorization_type = var.authorization_type

  auth_parameters {
    basic {
      username = var.jira_email
      password = var.jira_api_token
    }
  }
}
