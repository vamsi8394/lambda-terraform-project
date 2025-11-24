# Lambda Layer Module

This module creates an AWS Lambda Layer for packaging and managing dependencies.

## Features

- **Versioned layers** – each deployment creates a new layer version
- **Runtime compatibility** – specify which Lambda runtimes can use the layer
- **Automatic hashing** – detects changes in the zip file and creates new versions
- **Lifecycle management** – creates new version before destroying old one

## Usage

```hcl
module "my_layer" {
  source = "../../modules/lambda-layer"

  layer_name          = "my-dependencies-layer"
  description         = "Python dependencies for my Lambda function"
  compatible_runtimes = ["python3.13", "python3.12"]
  layer_zip_path      = "${path.module}/../../../layers/python-dependencies.zip"
}

# Use the layer in a Lambda function
module "my_lambda" {
  source = "../../modules/lambda"
  
  # ... other configuration ...
  
  layers = [module.my_layer.layer_arn]
}
```

## Creating the Layer Zip File

The layer zip must follow AWS Lambda's directory structure:

```
python-dependencies.zip
└── python/
    ├── package1/
    ├── package2/
    └── ...
```

Use the provided script to package dependencies:

```bash
./scripts/package-layer.sh
```

Or manually:

```bash
mkdir -p layers/python
pip install PyPDF2 docx2txt boto3 -t layers/python/
cd layers
zip -r python-dependencies.zip python/
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| layer_name | Name of the Lambda layer | string | - | yes |
| description | Description of the layer | string | "" | no |
| compatible_runtimes | List of compatible Lambda runtimes | list(string) | ["python3.13"] | no |
| layer_zip_path | Path to the layer zip file | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| layer_arn | ARN of the Lambda layer version |
| layer_version | Version number of the layer |
| layer_name | Name of the Lambda layer |

## Notes

- The layer zip file must exist before running `terraform apply`
- Run `./scripts/package-layer.sh` to create the zip file
- Each `terraform apply` with a changed zip will create a new layer version
- Old layer versions are retained (you can delete them manually in AWS Console if needed)
