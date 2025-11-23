resource "aws_wafv2_ip_set" "jira_ipv4" {
  name               = "jira-ipv4-ranges-${var.name}"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses = [
    "18.184.99.224/28",
    "18.234.32.224/28",
    "13.52.5.96/28",
    "52.215.192.224/28",
    "104.192.136.0/21",
    "13.200.41.128/25",
    "16.63.53.128/25",
    "13.236.8.224/28",
    "43.202.69.0/25",
    "185.166.140.0/22",
    "18.246.31.224/28",
    "18.136.214.96/28"
  ]

  tags = var.tags
}

# IPv6 IP Set for Jira IP ranges
resource "aws_wafv2_ip_set" "jira_ipv6" {
  name               = "jira-ipv6-ranges-${var.name}"
  scope              = var.scope
  ip_address_version = "IPV6"
  addresses = [
    "2a05:d014:0f99:dd04:0000:0000:0000:0000/63",
    "2a05:d018:034d:5804:0000:0000:0000:0000/63",
    "2600:1f14:0824:0306:0000:0000:0000:0000/64",
    "2406:da1c:01e0:a206:0000:0000:0000:0000/64",
    "2600:1f1c:0cc5:2304:0000:0000:0000:0000/63",
    "2600:1f18:2146:e306:0000:0000:0000:0000/64",
    "2406:da1c:01e0:a204:0000:0000:0000:0000/63",
    "2600:1f18:2146:e304:0000:0000:0000:0000/63",
    "2a05:d018:034d:5806:0000:0000:0000:0000/64",
    "2406:da18:0809:0e06:0000:0000:0000:0000/64",
    "2a05:d014:0f99:dd06:0000:0000:0000:0000/64",
    "2600:1f14:0824:0304:0000:0000:0000:0000/63",
    "2406:da18:0809:0e04:0000:0000:0000:0000/63",
    "2401:1d80:3000:0000:0000:0000:0000:0000/36"
  ]

  tags = var.tags
}

# WAF Web ACL - Restricts access to Jira IPs only
resource "aws_wafv2_web_acl" "this" {
  name  = var.name
  scope = var.scope

  # SECURITY: Default action is BLOCK - only allow Jira IPs
  default_action {
    block {}
  }

  rule {
    name     = "AllowJiraIPv4"
    priority = 1

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.jira_ipv4.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowJiraIPv4"
      sampled_requests_enabled   = true
    }
  }

  # IPv6 rule for Jira IP ranges - ALLOW these IPs
  rule {
    name     = "AllowJiraIPv6"
    priority = 2

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.jira_ipv6.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowJiraIPv6"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - Block Anonymous IPs (applies to allowed IPs)
  rule {
    name     = "AWS-AWSManagedRulesAnonymousIpList"
    priority = 50

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAnonymousIpList"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - Block Known Bad Inputs
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 200

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - Block SQL Injection
  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 201

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - Common Rule Set
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 700

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "webhook-ACL"
    sampled_requests_enabled   = true
  }

  tags = var.tags
}
