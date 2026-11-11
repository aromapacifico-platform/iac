resource "aws_iot_thing" "this" {
  provider = aws.project
  name     = var.thing_name
  # IoT things do not support AWS resource tags; expose FincaID as an attribute.
  attributes = local.attributes
}

resource "aws_iot_certificate" "this" {
  provider = aws.project
  csr      = var.certificate_csr
  active   = var.certificate_active
  # The mandatory CSR selects CreateCertificateFromCsr, never key generation.
}

resource "aws_iot_thing_principal_attachment" "this" {
  provider  = aws.project
  thing     = aws_iot_thing.this.name
  principal = aws_iot_certificate.this.arn
}

resource "aws_iot_policy_attachment" "this" {
  provider = aws.project
  policy   = var.policy_name
  target   = aws_iot_certificate.this.arn
}
