# tech-extracttextlambda

AWS Lambda function for extracting text from PDF and DOCX files and performing AI-powered contract analysis using Amazon Bedrock.

## Purpose

This Lambda function:
- Extracts text from PDF and DOCX contract documents
- Classifies contract type using Amazon Bedrock Nova Lite
- Performs deep legal analysis using Amazon Bedrock Nova Pro
- Supports 7 contract types: DPA, NDA, MSA, SOW, ADDENDUM, PURCHASE_AGREEMENT, OPEN_SOURCE
- Returns structured analysis with exact citations and risk assessments

## Runtime Configuration

- **Runtime**: Python 3.13
- **Architecture**: arm64
- **Memory**: 512 MB
- **Ephemeral Storage**: 512 MB
- **Timeout**: 180 seconds (3 minutes)

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `S3_BUCKET_NAME` | S3 bucket containing contract files | `pfj-legal-tech-contracts-bucket` |
| `AWS_REGION` | AWS region for Bedrock | `us-east-1` |

## Dependencies

- `boto3` - AWS SDK for S3 and Bedrock
- `PyPDF2` - PDF text extraction
- `docx2txt` - DOCX text extraction

## IAM Permissions Required

```json
{
  "CloudWatchLogs": "logs:CreateLogGroup, CreateLogStream, PutLogEvents",
  "S3ReadAccess": "s3:GetObject on bucket/*",
  "BedrockFullAccess": "bedrock:* on all resources"
}
```

## Trigger

- **Step Functions**: Invoked by `TechContractAnalysisWorkflow`
- **Input**: S3 location, file metadata, correlation ID

## Features

### Text Extraction
- PDF: Page-by-page extraction with page markers
- DOCX: Text extraction with estimated page markers
- Quality validation (minimum length, readability ratio)

### Contract Classification
- Primary: Amazon Bedrock Nova Lite
- Fallback: Keyword-based classification
- Confidence scoring and warnings

### Legal Analysis
- Amazon Bedrock Nova Pro for deep analysis
- Contract-type-specific prompts
- Exact citations with section and page numbers
- Risk assessment (CRITICAL, HIGH, MEDIUM, LOW)
- Prompt injection protection

### Security
- SSRF protection in prompts
- Prompt injection detection
- Comprehensive error handling
- Correlation ID tracking

## Supported Contract Types

1. **DPA** - Data Protection Addendum
2. **NDA** - Non-Disclosure Agreement
3. **MSA** - Master Services Agreement
4. **SOW** - Statement of Work
5. **ADDENDUM** - Addendum/Amendment/Change Order
6. **PURCHASE_AGREEMENT** - Purchase Agreement
7. **OPEN_SOURCE** - Open Source License Agreement

## Output Format

```json
{
  "success": true,
  "contractType": "MSA",
  "contractTypeName": "Master Services Agreement",
  "contractTypeConfidence": 0.95,
  "classificationMethod": "nova_lite",
  "pageCount": 12,
  "analysis": "Detailed analysis with citations...",
  "correlationId": "uuid"
}
```

## Error Handling

- S3 download failures
- Unsupported file types
- Text extraction errors
- Classification failures
- Bedrock API errors

## Deployment

See the main project README for deployment instructions using Terraform.
