# Pure configuration data (PC-IAC-026)
client      = "fnc"
project     = "aromapacifico"
environment = "desarrollo"
aws_region  = "us-east-1"

expedientes_table_name = "fnc-aromapacifico-dev-dynamo-expedientes"
inference_model_id     = "amazon.nova-lite-v1:0"

mock_kms_key_objects_arn = "arn:aws:kms:us-east-1:111122223333:key/12345678-1234-1234-1234-123456789012"
mock_kms_key_data_arn    = "arn:aws:kms:us-east-1:111122223333:key/87654321-4321-4321-4321-210987654321"

additional_tags = {
  SampleTag = "FunctionModuleFixture"
}

