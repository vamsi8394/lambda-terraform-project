variable "layer_name" {
  description = "Name of the Lambda layer"
  type        = string
}

variable "description" {
  description = "Description of the Lambda layer"
  type        = string
  default     = ""
}

variable "compatible_runtimes" {
  description = "List of compatible runtimes"
  type        = list(string)
  default     = ["python3.13"]
}

variable "layer_zip_path" {
  description = "Path to the layer zip file"
  type        = string
}
