# Single reusable farm identity

Implements one farm identity for [planning #24](https://github.com/aromapacifico-platform/planning/issues/24). The caller provides `farm_id`, final `thing_name`, the existing farm-scoped `policy_name`, a public `certificate_csr`, and `certificate_active`. The module creates one IoT thing, one certificate and its thing/policy attachments. The dev root invokes the module exactly once. There is no loop over 200 farms.

`thing_name` is also the exact MQTT ClientId authorized by ingest. The thing's `FincaID` attribute and the attached policy's FincaID tag identify the farm. IoT things and this provider's certificate resource have no `tags` argument; `identity_tags` returns caller metadata but does not pretend to apply unsupported tags.

## Certificate lifecycle without private keys

Generate the key and CSR in the device or approved external provisioning process. Supply only the PEM CSR. It must have a nonempty base64 body. AWS signs it through CreateCertificateFromCsr; Terraform never invokes CreateKeysAndCertificate. Empty/null/non-CSR input is rejected, and there is no private-key input, TLS private-key resource, local key file or private-key output. The provider schema exposes a computed private_key field, but the CSR API does not return one. Public CSR/certificate data may appear in state and must still follow state-access governance.

The module returns the public signed certificate for external device provisioning. Neither keys nor certificate fixtures are committed. The deliberately synthetic CSR in mocked tests is not usable as a deployment CSR.

Set `certificate_active=false` to request an actual in-place change to certificate status, retaining the identity and policy attachments. Set it to true to activate it. The committed dev pattern starts inactive. Real AWS changes are outside this task; no apply is performed. Certificate deactivation is not a claim that an unimplemented satellite adapter has been revoked, or a measured guarantee about already-open MQTT session timing. If such an adapter is later added, its registry must be revoked separately as required by #12. Replacing a CSR creates a replacement certificate; plan rotation with external provisioning before enabling a real node.

## Example and validation

See [sample](sample/README.md) and [dev integration](../../environments/dev/README.md). Requires Terraform >=1.11,<2 and AWS >=6.72,<7, with explicit `aws.project` injection.

From the repository root, validate through the configured sample and run unit tests in the child module:

```bash
terraform -chdir=modules/farm/sample init -backend=false -input=false
terraform -chdir=modules/farm/sample validate
terraform -chdir=modules/farm init -backend=false -input=false
terraform -chdir=modules/farm test
```

Do not run standalone `validate` in `modules/farm`: it declares `aws.project` as a caller-supplied configuration alias. The sample supplies `providers = { aws.project = aws.principal }`; dev supplies `providers = { aws.project = aws }`. Unit tests supply `mock_provider "aws"` with `alias = "project"`. Test mocks are injected by `terraform test`, not by `terraform validate`. No provider configuration belongs inside this reusable module. Validation through the sample needs installed provider schemas but no real CSR, dependency values or AWS credentials. The generic missing-provider diagnostic alone does not establish that any resources exist in state.

Mocked plan tests cover active/inactive status, one identity with its FincaID attribute, supplied CSR and attached policy, and rejection of empty, null, private-key-like and invalid farm inputs. No real AWS mutation occurs. See the [execution evidence](../../docs/iac/hu-24-validation.md).
