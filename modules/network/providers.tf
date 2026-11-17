# Provider configuration for network module
# Per PC-IAC-005, reference modules do not configure providers directly.
# The consumer stack injects the provider via configuration_aliases:
#   providers = { aws.project = aws.principal }
