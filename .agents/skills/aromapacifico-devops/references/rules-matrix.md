# Matriz de Reglas IaC AromaPacífico (PC-IAC-001 a PC-IAC-026)

Este documento contiene la matriz exhaustiva de las **26 reglas de Infraestructura como Código (IaC)** en Terraform para el proyecto **AromaPacífico (FNC 2026)**. Cada regla detalla su identificador, objetivo, restricciones obligatorias, antipatrones prohibidos y la matriz de decisión para saber con precisión cuándo y cómo aplicarla ante cualquier requerimiento o Historia de Usuario (HU).

---

## 1. Catálogo Completo de Reglas PC-IAC

| ID | Nombre de la Regla | Tipo | Ámbito Principal | Pilares Well-Architected |
|---|---|---|---|---|
| **PC-IAC-001** | Estructura Obligatoria para Módulos de Referencia | Básica | Módulos Reutilizables | Operational Excellence, Security |
| **PC-IAC-002** | Variables Obligatorias y Buenas Prácticas | Variables | Módulos y Root | Operational Excellence, Security |
| **PC-IAC-003** | Nomenclatura para Terraform y Recursos AWS | Nomenclatura | Global (Root y Módulos) | Operational Excellence, Cost Optimization |
| **PC-IAC-004** | Etiquetas Obligatorias (Tagging en 2 Capas) | Etiquetas | Global (Root y Módulos) | Cost Optimization, Operational Excellence, Security |
| **PC-IAC-005** | Configuración y Alias de Providers | Providers | Global (Root y Módulos) | Operational Excellence, Security |
| **PC-IAC-006** | Versiones y Estabilidad (Pinning) | Versiones | Global (`versions.tf`) | Operational Excellence, Security |
| **PC-IAC-007** | Outputs (Salidas del Módulo) | Flujo de Datos | Módulos y Root | Operational Excellence, Security |
| **PC-IAC-008** | Gestión de Estado (Backend Remoto S3) | Estado | Root (`environments/`) | Security, Operational Excellence |
| **PC-IAC-009** | Tipos de Datos, Conversiones y Lógica en Locals | Flujo / Lógica | Módulos y Root | Operational Excellence |
| **PC-IAC-010** | For_Each y Control de Recursos (`lifecycle`) | Recursos | Módulos y Root | Reliability, Operational Excellence |
| **PC-IAC-011** | Data Sources y Consumo de Datos Externos | Flujo / Integración | IaC Root Exclusivo | Operational Excellence |
| **PC-IAC-012** | Estructuras de Datos y Reutilización en Locals | Lógica Interna | Módulos y Root | Operational Excellence |
| **PC-IAC-013** | Estructura de Llamada a Módulos (Ordering) | Consistencia | Root (`main.tf`) | Operational Excellence |
| **PC-IAC-014** | Bloques Dinámicos y Splat Expressions | Sintaxis HCL | Módulos y Root | Operational Excellence |
| **PC-IAC-015** | Consumo de Módulos (Remoto y Versionado) | Modularización | Root (`environments/`) | Operational Excellence, Reliability |
| **PC-IAC-016** | Manejo de Secretos y Datos Sensibles | Seguridad | Global | Security |
| **PC-IAC-017** | Comunicación entre Dominios (Data Sources) | Integración | Root / Workload | Operational Excellence |
| **PC-IAC-018** | Testing y Validación del Código | Calidad / CI/CD | Global | Operational Excellence, Reliability |
| **PC-IAC-019** | Uso Restringido de Remote State | Integración | Root | Operational Excellence |
| **PC-IAC-020** | Gobernanza General de Seguridad (Hardening) | Seguridad | Global (Todos los Recursos) | Security |
| **PC-IAC-021** | Centralización de Configuración en Locals | Flujo de Datos | Root (`main.tf` / `locals.tf`) | Operational Excellence |
| **PC-IAC-022** | Separación de Responsabilidades por Dominio | Arquitectura | Dominios (Net/Sec/Workload) | Operational Excellence, Security |
| **PC-IAC-023** | Diseño Monolítico Funcional de Módulos | Modularización | Módulos de Referencia | Operational Excellence, Security |
| **PC-IAC-024** | Trazabilidad de Configuración Compleja | Flujo / Variables | Root (`.tfvars` a Módulos) | Operational Excellence |
| **PC-IAC-025** | Procesamiento de Gobernanza en el Root | Trazabilidad / Naming| Root (`locals.tf`) | Operational Excellence |
| **PC-IAC-026** | Patrón de Transformación en `sample/` | Módulos / Ejemplos | Directorio `sample/` | Operational Excellence, Reliability |

---

## 2. Detalle Normativo por Regla (Requisitos y Antipatrones)

### PC-IAC-001: Estructura Obligatoria para Módulos de Referencia
- **Mandatorio:** Todo módulo debe tener exactamente **10 archivos en raíz**: `.gitignore`, `CHANGELOG.md`, `README.md`, `data.tf`, `locals.tf`, `main.tf`, `outputs.tf`, `providers.tf`, `variables.tf`, `versions.tf`.
- **Mandatorio:** Todo módulo debe incluir subdirectorio `sample/` con **7 archivos obligatorios**: `README.md`, `data.tf`, `locals.tf`, `main.tf`, `outputs.tf`, `providers.tf`, `variables.tf`.
- **Prohibido:** Crear módulos sin documentación o sin su suite de `sample/`.

### PC-IAC-002: Variables Obligatorias y Buenas Prácticas
- **Mandatorio:** Atributos obligatorios en cada variable: `type`, `description` y al menos un bloque `validation`.
- **Mandatorio:** En la raíz son obligatorias las variables de gobernanza: `client`, `project`, `environment`.
- **Mandatorio:** Colecciones para `for_each` deben ser `map(object)` para garantizar estabilidad en el plan. Atributos opcionales deben usar `optional()`.
- **Prohibido:** Variables sin tipo explícito o sin bloque de validación.

### PC-IAC-003: Nomenclatura para Terraform y Recursos AWS
- **Mandatorio en HCL:** Convención `snake_case` para todo elemento interno (recursos, variables, outputs, locals).
- **Mandatorio Recurso Principal:** El recurso nuclear del módulo debe nombrarse `this` (ej. `resource "aws_vpc" "this"`).
- **Mandatorio Físico AWS:** Patrón `${client}-${project}-${environment}-${type}-${key}` con guiones `-`.
- **Prohibido:** Nombres físicos con guiones bajos (`_`), mayúsculas o que excedan 28 caracteres estándar.

### PC-IAC-004: Etiquetas Obligatorias (Tagging en 2 Capas)
- **Capa 1 (Transversal):** Inyectada masivamente vía `default_tags` del provider en el Root usando `var.common_tags`. En AromaPacífico incluye: `FincaID`, `DronID`, `AcopioID`, `ViajeID`, `Ambiente`, `Propietario`, `Proyecto`.
- **Capa 2 (Específica):** Etiqueta `Name` explícita en cada recurso construida en `locals.tf`, combinada con `additional_tags` (`merge(local.resource_tags, var.additional_tags)`).
- **Prohibido:** Recursos sin etiqueta `Name` o providers en Root sin `default_tags`.

### PC-IAC-005: Configuración y Alias de Providers
- **En Root:** Provider AWS principal configurado con `alias = "principal"` y `default_tags`.
- **En Módulos:** Prohibido instanciar bloques de configuración de provider. Se declara únicamente `configuration_aliases = [aws.project]` dentro de `required_providers`.
- **En Invocación:** Mapeo explícito: `providers = { aws.project = aws.principal }`.

### PC-IAC-006: Versiones y Estabilidad (Pinning)
- **En Root:** `required_version = ">= 1.10.0"` y version pinning estricto del provider `~> 6.0`.
- **En Módulos:** `required_version = ">= 1.10.0"` y restricción flexible de compatibilidad (ej. `>= 6.72.0, < 7.0.0`).
- **Archivo Dedicado:** Siempre en `versions.tf`.

### PC-IAC-007: Outputs (Salidas del Módulo)
- **Mandatorio:** Atributos obligatorios: `description` clara y concisa.
- **Granularidad:** Exponer solo lo estrictamente necesario para el consumidor.
- **Seguridad:** Datos sensibles marcados obligatoriamente con `sensitive = true`.
- **Nomenclatura:** `<recurso>_<identificador>` (ej. `vpc_id`, `lambda_function_arn`).

### PC-IAC-008: Gestión de Estado (Backend Remoto S3)
- **En Root:** Declarar bloque `backend "s3" {}` vacío en `backend.tf`, parametrizado desde `backend.hcl`.
- **Requisitos S3:** Cifrado SSE-KMS (`encrypt = true`), versionamiento activo, bloqueo de concurrencia nativo (`use_lockfile = true`), aislamiento de un bucket por cuenta/ambiente.
- **Prohibido:** Bloques `backend` dentro de Módulos de Referencia.

### PC-IAC-009: Tipos de Datos, Conversiones y Lógica en Locals
- **Mandatorio:** Toda conversión de tipos (`toset`, `tomap`, `try`) y manipulación compleja reside en `locals.tf`.
- **Mandatorio:** `main.tf` solo consume valores listos desde `local.*`.

### PC-IAC-010: For_Each y Control de Recursos (`lifecycle`)
- **Mandatorio:** Uso de `for_each` sobre `map(object)` para iteraciones.
- **Prohibido:** `count` para recursos dinámicos (solo se permite como switch ternario booleano `var.enable ? 1 : 0`).
- **Protección:** `prevent_destroy = true` en recursos de datos críticos (buckets de estado, DynamoDB, VPC core).

### PC-IAC-011: Data Sources y Consumo de Datos Externos
- **Ubicación Exclusiva:** Solo en el IaC Root (`environments/` o dominio consumidor).
- **Prohibido:** Data sources dentro de Módulos de Referencia para descubrir infraestructura externa (deben recibirse por `var.*`).

### PC-IAC-012: Estructuras de Datos y Reutilización en Locals
- **Mandatorio:** Bloque `locals` único y organizado.
- **Mandatorio:** Uso de `flatten()` para transformar mapas o listas anidadas en colecciones planas iterables.
- **Mandatorio:** Mapa de abreviaturas estandarizadas de recursos (`vpc`, `s3`, `dynamo`, `kms`, `lambda`, `iot`).

### PC-IAC-013: Estructura de Llamada a Módulos (Ordering)
Los bloques `module` en Root deben seguir este orden exacto con saltos de línea (`\n`):
1. **A:** `source` y `version`
2. **B:** `providers = { ... }`
3. **C:** Variables de Gobernanza (`client`, `project`, `environment`)
4. **D:** Variables Transversales e inyecciones (`vpc_id`, `kms_key_arn`)
5. **E:** Variables Específicas del Recurso (configuración del payload)

### PC-IAC-014: Bloques Dinámicos y Splat Expressions
- **Mandatorio:** Usar `dynamic "block_name"` para bloques repetitivos anidados basados en colecciones variables.
- **Mandatorio:** Uso de Splat expressions (`[*].id`) para extraer listas simples de atributos de recursos.

### PC-IAC-015: Consumo de Módulos (Remoto y Versionado)
- **Mandatorio:** Consumo de módulos desde repositorios remotos con tags SemVer: `source = "git::https://github.com/.../repo.git?ref=v1.0.0"`.
- **Excepción:** Rutas relativas `./modules/...` permitidas únicamente durante desarrollo local en mono-repositorio controlado.

### PC-IAC-016: Manejo de Secretos y Datos Sensibles
- **Prohibición Absoluta:** Cero contraseñas, tokens, llaves privadas o certificados en Git o `.tfvars`.
- **Mandatorio:** Marcar `sensitive = true` en variables y outputs sensibles.
- **Autenticación:** OIDC federado con GitHub Actions (cero `aws_access_key` permanentes).

### PC-IAC-017: Comunicación entre Dominios mediante Data Sources
- **Prioridad 1 (Mandatoria):** Data sources filtrados por tags estándar y nombres estandarizados (`PC-IAC-003`).
- **Prohibido:** Acoplar stacks mediante `terraform_remote_state` a menos que sea la única opción técnica viable.

### PC-IAC-018: Testing y Validación del Código
- **Validaciones Mandatorias:** `terraform fmt -check`, `terraform validate`, `tflint`, `gitleaks`, análisis de seguridad (`checkov` / `tfsec`).
- **Estructura:** Directorios `sample/` y `tests/` funcionales.

### PC-IAC-019: Uso Restringido de Remote State
- **Regla:** Se prohíbe el uso indiscriminado de `terraform_remote_state`. Si se requiere como excepción, debe justificarse formalmente en el `README.md` del stack.

### PC-IAC-020: Gobernanza General de Seguridad (Hardening Well-Architected)
- **Cifrado Obligatorio:** KMS para datos en reposo (DynamoDB, S3, SQS); TLS 1.2+ obligatorio en tránsito (políticas bucket HTTPS enforced, IoT MQTT TLS).
- **Mínimo Privilegio:** IAM Roles específicos con acciones y recursos concretos; prohibido usar `Action: "*"` o `Resource: "*"`.
- **Perímetro:** S3 con `block_public_acls = true`, `block_public_policy = true`, `ignore_public_acls = true`, `restrict_public_buckets = true`.
- **Cómputo:** Lambdas dentro de VPC privada sin IP pública, conectadas vía VPC Endpoints.

### PC-IAC-021: Centralización de Configuración en Locals
- **Prohibido:** Declarar mapas o listas de configuración complejas directamente en el bloque `module` de `main.tf`.
- **Flujo Obligatorio:** `var.config (en .tfvars) -> local.config_transformed (en locals.tf) -> module.resource`.

### PC-IAC-022: Separación de Responsabilidades por Dominio
- **Dominio Networking:** VPC, Subnets, Route Tables, Internet Gateways, NAT Gateways, VPC Endpoints, TGW.
- **Dominio Seguridad:** Security Groups, Network ACLs, IAM Roles, IAM Policies, KMS Keys, WAF.
- **Dominio Workload:** Lambda, DynamoDB, IoT Core, S3 de aplicación, SQS, ECS.
- **Regla de Oro:** Un módulo o stack de Workload **NUNCA** crea VPCs, Subnets, Security Groups ni IAM Roles; los consume vía Data Sources (`PC-IAC-017`) o variables de entrada (`var.subnet_ids`, `var.security_group_ids`).

### PC-IAC-023: Diseño Monolítico Funcional de Módulos
- **Responsabilidad Única:** Un Módulo de Referencia solo despliega el servicio intrínseco que le corresponde.
- **Prohibido:** Que un módulo de cómputo/ingesta cree sus propios Security Groups o subredes.

### PC-IAC-024: Trazabilidad de Configuración Compleja
- **Fuente de Verdad:** La configuración de parámetros variables debe provenir de los archivos de variables por ambiente (`dev.tfvars`, `test.tfvars`, `prod.tfvars`).
- **Prohibido:** Hardcodear parámetros operativos en `locals.tf` o `main.tf`.

### PC-IAC-025: Procesamiento Obligatorio de Gobernanza en el Root
- **Regla de Naming:** El Root construye el nombre físico final completo `${client}-${project}-${environment}-${type}-${key}` en su `locals.tf` y lo pasa al módulo.
- **Prohibido:** Que los módulos reciban las piezas sueltas (`client`, `project`, `environment`) para concatenarlas internamente.

### PC-IAC-026: Patrón de Transformación en `sample/`
- **Flujo en sample/:**
  - `sample/terraform.tfvars`: Datos crudos del recurso sin dependencias de gobernanza.
  - `sample/locals.tf`: Inyección de variables de gobernanza (`client`, `project`, `environment`) y construcción de nombres estándar.
  - `sample/main.tf`: Invocación del módulo pasando `local.*`.
- **Prohibido:** Transformaciones o lógica dentro de `sample/main.tf`.

---

## 3. Matriz de Decisión por Tipo de Tarea / HU

Usa esta matriz para saber qué reglas aplican de inmediato según el alcance de la Historia de Usuario:

| Tipo de Tarea / HU | Reglas Obligatorias Aplicables |
|---|---|
| **Creación de un Módulo de Referencia (`modules/<name>`)** | `PC-IAC-001`, `PC-IAC-002`, `PC-IAC-003`, `PC-IAC-004`, `PC-IAC-005`, `PC-IAC-006`, `PC-IAC-007`, `PC-IAC-009`, `PC-IAC-010`, `PC-IAC-012`, `PC-IAC-014`, `PC-IAC-018`, `PC-IAC-020`, `PC-IAC-023`, `PC-IAC-026` |
| **Instanciación en Ambiente (`environments/<env>/main.tf`)** | `PC-IAC-003`, `PC-IAC-004`, `PC-IAC-005`, `PC-IAC-006`, `PC-IAC-008`, `PC-IAC-011`, `PC-IAC-013`, `PC-IAC-015`, `PC-IAC-016`, `PC-IAC-017`, `PC-IAC-021`, `PC-IAC-022`, `PC-IAC-024`, `PC-IAC-025` |
| **HU de Redes (VPC, Subredes, VPN, Endpoints)** | `PC-IAC-003`, `PC-IAC-004`, `PC-IAC-010`, `PC-IAC-020`, `PC-IAC-022` (Dominio Networking exclusivo) |
| **HU de Seguridad (KMS, IAM Roles, Security Groups, NACL)** | `PC-IAC-003`, `PC-IAC-004`, `PC-IAC-016`, `PC-IAC-020` (Cifrado KMS, Mínimo Privilegio), `PC-IAC-022` (Dominio Seguridad exclusivo) |
| **HU de Ingesta IoT / Finca Patrón / Telemetría** | `PC-IAC-003`, `PC-IAC-004`, `PC-IAC-010`, `PC-IAC-011`, `PC-IAC-017`, `PC-IAC-020` (X.509 certs, store-and-forward 24h, TTL, cifrado KMS), `PC-IAC-022`, `PC-IAC-023` |
| **HU de Serverless / Inferencia (S3, Lambda, Rekognition)** | `PC-IAC-003`, `PC-IAC-004`, `PC-IAC-010`, `PC-IAC-011`, `PC-IAC-016`, `PC-IAC-020` (Bucket privado, DLQ SQS, IAM específico sin `*`), `PC-IAC-022`, `PC-IAC-023` |
| **HU de CI/CD, Pipeline y Gobernanza de Despliegue** | `PC-IAC-006`, `PC-IAC-008`, `PC-IAC-016` (OIDC sin llaves), `PC-IAC-018` (fmt, tflint, trivy), Control de Ventana de Cosecha (Change Freeze) |

