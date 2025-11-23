# CloudWatch Log Group for Step Functions
resource "aws_cloudwatch_log_group" "state_machine" {
  name              = "/aws/vendedlogs/states/${var.state_machine_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Step Functions State Machine
resource "aws_sfn_state_machine" "this" {
  name     = var.state_machine_name
  role_arn = var.create_role ? aws_iam_role.state_machine[0].arn : var.role_arn
  type     = var.state_machine_type

  definition = var.definition

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.state_machine.arn}:*"
    include_execution_data = true
    level                  = var.logging_level
  }

  tags = var.tags
}
