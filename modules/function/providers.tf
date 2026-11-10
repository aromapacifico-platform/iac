# Provider configuration for function module (PC-IAC-005)
# Per PC-IAC-005, modules do not configure providers directly.
# The consumer stack injects the provider via configuration_aliases:
#   providers = { aws.project = aws.principal }
