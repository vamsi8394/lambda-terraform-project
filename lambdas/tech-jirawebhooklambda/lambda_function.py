import json
import os
import hmac
import hashlib
import time
import uuid
import logging
import socket
import ipaddress
from typing import Dict, Any, Tuple, Set
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse
import base64

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client('s3')
sfn_client = boto3.client('stepfunctions')
secrets_client = boto3.client('secretsmanager')

JIRA_BASE_URL = os.environ['JIRA_BASE_URL']
JIRA_CONNECTION_ARN = os.environ['JIRA_CONNECTION_ARN']
STATE_MACHINE_ARN = os.environ['STATE_MACHINE_ARN']
S3_BUCKET_NAME = os.environ['S3_BUCKET_NAME']
SECRETS_ARN = os.environ['SECRETS_ARN']

MAX_FILE_SIZE_MB = 50
ALLOWED_EXTENSIONS = {'pdf', 'docx'}
DOWNLOAD_TIMEOUT = 120
S3_PREFIX = 'contracts'

DISALLOWED_HOSTNAMES: Set[str] = {
    'localhost',
    '127.0.0.1',
    '0.0.0.0',
    '169.254.169.254',
    'metadata.google.internal',
    '::1',
    'ip6-localhost'
}

PRIVATE_IP_RANGES = [
    ipaddress.ip_network('10.0.0.0/8'),
    ipaddress.ip_network('172.16.0.0/12'),
    ipaddress.ip_network('192.168.0.0/16'),
    ipaddress.ip_network('127.0.0.0/8'),
    ipaddress.ip_network('169.254.0.0/16'),
    ipaddress.ip_network('::1/128'),
    ipaddress.ip_network('fe80::/10'),
    ipaddress.ip_network('fc00::/7')
]


class WebhookError(Exception):
    pass


class SecretsCache:
    def __init__(self):
        self._cache = {}
    
    def get(self, secret_arn: str, correlation_id: str) -> Dict[str, str]:
        if secret_arn in self._cache:
            logger.info(f"[{correlation_id}] Using cached secret")
            return self._cache[secret_arn]
        
        logger.info(f"[{correlation_id}] Fetching secret from Secrets Manager")
        
        try:
            response = secrets_client.get_secret_value(SecretId=secret_arn)
            secret_string = response['SecretString']
            secret = json.loads(secret_string)
            
            required_keys = {'jiraEmail', 'jiraApiToken', 'webhookSecret'}
            missing_keys = required_keys - secret.keys()
            if missing_keys:
                logger.error(f"[{correlation_id}] Secret missing keys: {missing_keys}")
                raise WebhookError(f"Secret missing required keys: {missing_keys}")
            
            self._cache[secret_arn] = secret
            logger.info(f"[{correlation_id}] Secret cached successfully")
            return secret
            
        except ClientError as e:
            error_code = e.response['Error']['Code']
            logger.error(f"[{correlation_id}] Failed to retrieve secret: {error_code}")
            raise WebhookError(f"Failed to retrieve secret: {error_code}")
        except json.JSONDecodeError as e:
            logger.error(f"[{correlation_id}] Secret is not valid JSON: {str(e)}")
            raise WebhookError("Secret is not valid JSON")


secrets_cache = SecretsCache()


def verify_hmac(body: str, signature: str, secret: str) -> bool:
    if not signature or '=' not in signature:
        return False
    
    try:
        algo, received_hash = signature.split('=', 1)
        if algo != 'sha256':
            return False
        
        expected_hash = hmac.new(
            secret.encode('utf-8'),
            body.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()
        
        return hmac.compare_digest(expected_hash, received_hash)
    except Exception:
        return False


def parse_webhook_payload(event: Dict[str, Any], correlation_id: str) -> Tuple[str, Dict[str, Any]]:
    body = event.get('body', '{}')
    
    if event.get('isBase64Encoded'):
        import base64
        logger.info(f"[{correlation_id}] Decoding base64 payload")
        try:
            body = base64.b64decode(body).decode('utf-8')
        except Exception:
            raise WebhookError("Invalid base64 encoding")
    
    try:
        payload = json.loads(body)
        logger.info(f"[{correlation_id}] Parsed webhook payload, event: {payload.get('webhookEvent', 'unknown')}")
        return body, payload
    except json.JSONDecodeError as e:
        logger.error(f"[{correlation_id}] JSON decode error: {str(e)}")
        raise WebhookError(f"Invalid JSON payload: {str(e)}")


def is_ip_disallowed(hostname: str) -> bool:
    if hostname.lower() in DISALLOWED_HOSTNAMES:
        return True
    
    try:
        ip_obj = ipaddress.ip_address(hostname)
        for private_range in PRIVATE_IP_RANGES:
             if ip_obj in private_range:
                return True
        return False
    except ValueError:
        pass

    try:
        ip_addresses = socket.getaddrinfo(hostname, None)
        
        for ip_info in ip_addresses:
            ip_str = ip_info[4][0]
            
            try:
                ip_obj = ipaddress.ip_address(ip_str)
                
                for private_range in PRIVATE_IP_RANGES:
                    if ip_obj in private_range:
                        return True
                        
            except ValueError:
                continue
                
        return False
        
    except socket.gaierror:
        return True
    except Exception:
        return True


def validate_content_url(url: str, correlation_id: str) -> None:
    if not url or not url.strip():
        logger.error(f"[{correlation_id}] Empty URL provided")
        raise WebhookError("Empty URL")
    
    try:
        parsed = urlparse(url)
    except Exception as e:
        logger.error(f"[{correlation_id}] URL parse error: {str(e)}")
        raise WebhookError(f"Invalid URL format: {str(e)}")
    
    if parsed.scheme != 'https':
        logger.error(f"[{correlation_id}] Invalid URL scheme: {parsed.scheme} (Must be https)")
        raise WebhookError(f"Invalid URL scheme: {parsed.scheme}")
    
    if not parsed.netloc:
        logger.error(f"[{correlation_id}] Missing hostname in URL")
        raise WebhookError("Invalid URL: missing hostname")
    
    hostname = parsed.hostname
    if not hostname:
        logger.error(f"[{correlation_id}] Could not extract hostname from URL")
        raise WebhookError("Invalid URL: could not extract hostname")
    
    expected_jira_hostname = urlparse(JIRA_BASE_URL).hostname
    if hostname != expected_jira_hostname:
        logger.error(f"[{correlation_id}] Hostname mismatch: {hostname} != {expected_jira_hostname}")
        raise WebhookError(f"URL hostname does not match Jira base URL")
    
    if is_ip_disallowed(hostname):
        logger.error(f"[{correlation_id}] Disallowed IP/hostname: {hostname}")
        raise WebhookError(f"URL resolves to disallowed IP address")
    
    logger.info(f"[{correlation_id}] URL validation passed: {hostname}")


def validate_attachment(attachment: Dict[str, Any], correlation_id: str) -> Tuple[str, str, int]:
    required_fields = {'id', 'filename', 'content', 'size'}
    missing = required_fields - attachment.keys()
    if missing:
        logger.error(f"[{correlation_id}] Missing attachment fields: {missing}")
        raise WebhookError(f"Missing attachment fields: {missing}")
    
    filename = attachment['filename']
    if not filename or '.' not in filename:
        logger.error(f"[{correlation_id}] Invalid filename: {filename}")
        raise WebhookError(f"Invalid filename: {filename}")
    
    extension = filename.rsplit('.', 1)[-1].lower()
    if extension not in ALLOWED_EXTENSIONS:
        logger.error(f"[{correlation_id}] Unsupported file type: .{extension}")
        raise WebhookError(
            f"Unsupported file type: .{extension}. Allowed: {ALLOWED_EXTENSIONS}"
        )
    
    size = attachment['size']
    max_bytes = MAX_FILE_SIZE_MB * 1024 * 1024
    if size > max_bytes:
        logger.error(f"[{correlation_id}] File too large: {size} bytes")
        raise WebhookError(
            f"File size {size / 1024 / 1024:.1f}MB exceeds {MAX_FILE_SIZE_MB}MB limit"
        )
    
    logger.info(f"[{correlation_id}] Attachment validated: {filename} ({extension}, {size} bytes)")
    return filename, extension, size


def sanitize_filename(filename: str) -> str:
    safe_chars = set('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_')
    return ''.join(c if c in safe_chars else '_' for c in filename)


def download_from_jira(url: str, jira_email: str, jira_api_token: str, 
                       expected_size: int, correlation_id: str) -> bytes:
    try:
        auth_string = f"{jira_email}:{jira_api_token}"
        auth_b64 = base64.b64encode(auth_string.encode('utf-8')).decode('utf-8')
        
        logger.info(f"[{correlation_id}] Starting download from Jira, expected size: {expected_size} bytes")
        
        request = Request(
            url,
            headers={
                'Authorization': f'Basic {auth_b64}',
                'User-Agent': 'Mozilla/5.0',
                'Accept': '*/*'
            }
        )
        
        with urlopen(request, timeout=DOWNLOAD_TIMEOUT) as response:
            if response.status != 200:
                logger.error(f"[{correlation_id}] Jira HTTP error: {response.status}")
                raise WebhookError(f"Jira returned status {response.status}")
            
            content_length = response.headers.get('Content-Length')
            if content_length and int(content_length) != expected_size:
                logger.error(f"[{correlation_id}] Size mismatch: header={content_length}, expected={expected_size}")
                raise WebhookError("Size mismatch between metadata and response")
            
            file_content = response.read()
            
            if len(file_content) != expected_size:
                logger.error(f"[{correlation_id}] Downloaded size mismatch: {len(file_content)} != {expected_size}")
                raise WebhookError(
                    f"Downloaded {len(file_content)} bytes, expected {expected_size}"
                )
            
            logger.info(f"[{correlation_id}] Download complete: {len(file_content)} bytes")
            return file_content
            
    except HTTPError as e:
        if e.code in (401, 403):
            logger.error(f"[{correlation_id}] Jira authentication failed: {e.code}")
            raise WebhookError(f"Jira authentication failed: {e.code}")
        logger.error(f"[{correlation_id}] Jira HTTP error: {e.code}")
        raise WebhookError(f"Jira HTTP error: {e.code}")
    except URLError as e:
        logger.error(f"[{correlation_id}] Network error: {str(e.reason)}")
        raise WebhookError(f"Network error: {str(e.reason)}")
    except Exception as e:
        logger.error(f"[{correlation_id}] Download error: {str(e)}")
        raise WebhookError(f"Download failed: {str(e)}")


def upload_to_s3(file_content: bytes, issue_key: str, attachment_id: str,
                 filename: str, extension: str, correlation_id: str) -> str:
    timestamp = int(time.time())
    safe_filename = sanitize_filename(filename)
    s3_key = f"{S3_PREFIX}/{issue_key}/{timestamp}_{attachment_id}_{safe_filename}"
    
    content_types = {
        'pdf': 'application/pdf',
        'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    }
    
    try:
        logger.info(f"[{correlation_id}] Uploading to S3: {s3_key}")
        
        s3_client.put_object(
            Bucket=S3_BUCKET_NAME,
            Key=s3_key,
            Body=file_content,
            ContentType=content_types.get(extension, 'application/octet-stream'),
            StorageClass='INTELLIGENT_TIERING',
            ServerSideEncryption='AES256',
            Metadata={
                'original-filename': filename,
                'attachment-id': attachment_id,
                'issue-key': issue_key,
                'correlation-id': correlation_id,
                'file-size': str(len(file_content)),
                'upload-timestamp': str(timestamp)
            }
        )
        
        logger.info(f"[{correlation_id}] S3 upload complete: {s3_key}")
        return s3_key
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        logger.error(f"[{correlation_id}] S3 upload failed: {error_code}")
        raise WebhookError(f"S3 upload failed: {error_code}")


def start_step_functions(issue_key: str, attachment_id: str, filename: str,
                         extension: str, s3_key: str, file_size: int,
                         correlation_id: str) -> str:
    execution_input = {
        'issueKey': issue_key,
        'attachmentId': attachment_id,
        'filename': filename,
        'fileExtension': extension,
        's3Bucket': S3_BUCKET_NAME,
        's3Key': s3_key,
        'fileSize': file_size,
        'jiraBaseUrl': JIRA_BASE_URL,
        'jiraConnectionArn': JIRA_CONNECTION_ARN,
        'correlationId': correlation_id,
        'timestamp': int(time.time())
    }
    
    try:
        execution_name = f"{issue_key}-{attachment_id}-{int(time.time())}"
        logger.info(f"[{correlation_id}] Starting Step Functions execution: {execution_name}")
        
        response = sfn_client.start_execution(
            stateMachineArn=STATE_MACHINE_ARN,
            name=execution_name,
            input=json.dumps(execution_input)
        )
        
        execution_arn = response['executionArn']
        logger.info(f"[{correlation_id}] Step Functions started: {execution_arn}")
        return execution_arn
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        logger.error(f"[{correlation_id}] Step Functions failed: {error_code}")
        raise WebhookError(f"Step Functions failed: {error_code}")


def create_response(status_code: int, body: Dict[str, Any]) -> Dict[str, Any]:
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'X-Content-Type-Options': 'nosniff',
            'X-Frame-Options': 'DENY',
            'Strict-Transport-Security': 'max-age=31536000'
        },
        'body': json.dumps(body)
    }


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    correlation_id = str(uuid.uuid4())
    
    logger.info(f"[{correlation_id}] Webhook received, request_id: {context.aws_request_id}")
    
    try:
        secrets = secrets_cache.get(SECRETS_ARN, correlation_id)
        jira_email = secrets['jiraEmail']
        jira_api_token = secrets['jiraApiToken']
        webhook_secret = secrets['webhookSecret']
        
        body, webhook_data = parse_webhook_payload(event, correlation_id)
        
        headers = {k.lower(): v for k, v in event.get('headers', {}).items()}
        signature = headers.get('x-hub-signature-256') or headers.get('x-hub-signature')
        
        if not signature:
            logger.error(f"[{correlation_id}] Missing signature header")
            return create_response(403, {
                'error': 'Missing signature',
                'correlationId': correlation_id
            })
        
        if not verify_hmac(body, signature, webhook_secret):
            logger.error(f"[{correlation_id}] HMAC verification failed")
            return create_response(403, {
                'error': 'Invalid signature',
                'correlationId': correlation_id
            })
        
        logger.info(f"[{correlation_id}] HMAC verification passed")
        
        issue = webhook_data.get('issue', {})
        issue_key = issue.get('key')
        if not issue_key:
            logger.error(f"[{correlation_id}] Missing issue key in webhook")
            raise WebhookError("Missing issue key")
        
        logger.info(f"[{correlation_id}] Processing issue: {issue_key}")
        
        webhook_event = webhook_data.get('webhookEvent', '')
        attachment = webhook_data.get('attachment')
        if not attachment:
            attachments = issue.get('fields', {}).get('attachment', [])
            if not attachments:
                logger.info(f"[{correlation_id}] No attachment found in issue data.")
                return create_response(200, {'message': 'No attachment detected or found'})
            attachment = sorted(attachments, key=lambda x: x.get('created', ''), reverse=True)[0]
        
        if not attachment:
            logger.error(f"[{correlation_id}] Attachment object is None after search")
            raise WebhookError("No attachment found")
        
        filename, extension, size = validate_attachment(attachment, correlation_id)
        attachment_id = attachment['id']
        content_url = attachment['content']
        
        validate_content_url(content_url, correlation_id)
        
        file_content = download_from_jira(
            content_url,
            jira_email,
            jira_api_token,
            size,
            correlation_id
        )
        
        s3_key = upload_to_s3(
            file_content,
            issue_key,
            attachment_id,
            filename,
            extension,
            correlation_id
        )
        
        execution_arn = start_step_functions(
            issue_key,
            attachment_id,
            filename,
            extension,
            s3_key,
            size,
            correlation_id
        )
        
        logger.info(f"[{correlation_id}] Webhook processing complete for {issue_key}")
        
        return create_response(202, {
            'message': 'Webhook processed successfully',
            'issueKey': issue_key,
            'filename': filename,
            's3Key': s3_key,
            'executionArn': execution_arn,
            'correlationId': correlation_id
        })
        
    except WebhookError as e:
        logger.error(f"[{correlation_id}] WebhookError: {str(e)}")
        return create_response(400, {
            'error': str(e),
            'correlationId': correlation_id
        })
    
    except Exception as e:
        logger.error(f"[{correlation_id}] Unexpected fatal error: {str(e)}", exc_info=True)
        return create_response(500, {
            'error': 'Internal server error',
            'correlationId': correlation_id
        })
