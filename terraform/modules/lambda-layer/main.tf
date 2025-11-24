resource "aws_lambda_layer_version" "this" {
  layer_name          = var.layer_name
  description         = var.description
  compatible_runtimes = var.compatible_runtimes
  filename            = var.layer_zip_path
  source_code_hash    = filebase64sha256(var.layer_zip_path)

  lifecycle {
    create_before_destroy = true
  }
}
