locals { enabled = var.route53_acm_config.enabled }
resource "aws_acm_certificate" "this" {
  count             = var.route53_acm_config.enabled ? 1 : 0
  domain_name       = var.route53_acm_config.domain_name
  validation_method = "DNS"
  tags              = { Name = var.route53_acm_config.domain_name }
}

resource "aws_route53_record" "validation" {
  count   = var.route53_acm_config.enabled ? 1 : 0
  zone_id = var.route53_acm_config.hosted_zone_id
  name    = element(tolist(aws_acm_certificate.this[0].domain_validation_options), 0).resource_record_name
  type    = element(tolist(aws_acm_certificate.this[0].domain_validation_options), 0).resource_record_type
  records = [element(tolist(aws_acm_certificate.this[0].domain_validation_options), 0).resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "this" {
  count                   = var.route53_acm_config.enabled ? 1 : 0
  certificate_arn         = aws_acm_certificate.this[0].arn
  validation_record_fqdns = [aws_route53_record.validation[0].fqdn]
}
