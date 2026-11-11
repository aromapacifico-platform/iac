> Codex adaptation: read repository AGENTS.md for current interfaces, versions and authorized scope.

# 📄 Regla de Separación de Responsabilidades por Dominio

**ID:** PC-IAC-022  
**Tipo:** Arquitectura / Dominio  
**Pilares AWS Well-Architected:** Operational Excellence  
**Versión:** 1.0  
**Fecha:** 10 de diciembre de 2025

---

## 1. Propósito y Alcance

Esta regla refuerza el principio de **Separación de Responsabilidades por Dominio** (Networking, Seguridad, Workload). Prohíbe que un Módulo Raíz cree recursos que caen bajo la responsabilidad de otro dominio.

**Aplicable a:** Todos los bloques `resource` en el Módulo Raíz (Proyectos de Dominio).

---

## 2. Restricciones de Creación Cruzada

### 2.1. Prohibición de Recursos de Seguridad y Networking (Mandatorio)

Un dominio **Workload** (ej. `tesoreria-workload`) no debe declarar bloques `resource` que son responsabilidad de los dominios **Networking** o **Seguridad**.

**Prohibido en Workload:**
- `resource "aws_security_group"` (Seguridad)
- `resource "aws_vpc"` o `aws_subnet` (Networking)
- `resource "aws_iam_role"` (Seguridad/IAM)

### 2.2. Flujo de Datos Obligatorio

El dominio **Workload** debe obtener los recursos de los dominios Networking y Seguridad únicamente a través de:

1. **Data Sources** (referencia **PC-IAC-017**).
2. **Outputs de Módulos** (llamando a módulos de Seguridad/Networking).

**Ejemplo de Corrección:** Si Workload necesita un Security Group, debe usar `data "aws_security_group"` para buscar el SG existente en el dominio Seguridad, no crearlo.

---

## 3. Arquitectura de Dominios

### 3.1. Dominio Networking

**Responsabilidad:** Creación y gestión de la infraestructura de red base.

**Recursos Permitidos:**
- `aws_vpc`
- `aws_subnet`
- `aws_route_table`
- `aws_internet_gateway`
- `aws_nat_gateway`
- `aws_vpc_endpoint`
- `aws_transit_gateway`

**Outputs Esperados:**
- VPC ID
- Subnet IDs (públicas, privadas, datos)
- Route Table IDs
- NAT Gateway IPs

### 3.2. Dominio Seguridad

**Responsabilidad:** Creación y gestión de recursos de seguridad y control de acceso.

**Recursos Permitidos:**
- `aws_security_group`
- `aws_network_acl`
- `aws_iam_role`
- `aws_iam_policy`
- `aws_kms_key`
- `aws_wafv2_web_acl`

**Outputs Esperados:**
- Security Group IDs
- IAM Role ARNs
- KMS Key ARNs

### 3.3. Dominio Workload

**Responsabilidad:** Despliegue de aplicaciones y servicios de negocio.

**Recursos Permitidos:**
- `aws_ecs_cluster`, `aws_ecs_service`, `aws_ecs_task_definition`
- `aws_lambda_function`
- `aws_rds_cluster`, `aws_dynamodb_table`
- `aws_s3_bucket` (aplicación)
- `aws_lb`, `aws_lb_target_group`, `aws_lb_listener`
- `aws_cloudwatch_log_group`

**Recursos PROHIBIDOS:**
- ❌ `aws_vpc`, `aws_subnet`, `aws_security_group`, `aws_iam_role`

---

## 4. Implementación del Patrón

### 4.1. Ejemplo CORRECTO: Workload Consumiendo Networking y Seguridad

**Estructura de Directorios:**
```
proyecto/
├─ networking/
│  ├─ main.tf
│  └─ outputs.tf
├─ security/
│  ├─ main.tf
│  └─ outputs.tf
└─ workload/
   ├─ data.tf
   └─ main.tf
```

**En `workload/data.tf`:**
```hcl
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["${var.client}-${var.project}-${var.environment}-vpc"]
  }
}

data "aws_security_group" "ecs_service" {
  filter {
    name   = "tag:Name"
    values = ["${var.client}-${var.project}-${var.environment}-sg-ecs-service"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  
  filter {
    name   = "tag:Type"
    values = ["private"]
  }
}
```

**En `workload/main.tf`:**
```hcl
module "ecs_cluster" {
  source = "git::https://repo/ecs-cluster.git?ref=v1.0.0"
  
  client      = var.client
  project     = var.project
  environment = var.environment
  
  vpc_id             = data.aws_vpc.selected.id
  subnet_ids         = data.aws_subnets.private.ids
  security_group_ids = [data.aws_security_group.ecs_service.id]
}
```

### 4.2. Ejemplo INCORRECTO: Workload Creando Recursos de Otros Dominios

**En `workload/main.tf` (INCORRECTO):**
```hcl
resource "aws_security_group" "ecs_service" {
  name        = "${var.client}-${var.project}-sg-ecs"
  description = "Security group for ECS service"
  vpc_id      = data.aws_vpc.selected.id
  
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.client}-${var.project}-role-ecs-execution"
}

resource "aws_subnet" "app_private" {
  vpc_id     = data.aws_vpc.selected.id
  cidr_block = "10.0.1.0/24"
}
```

---

## 5. Gestión de Dependencias Entre Dominios

### 5.1. Orden de Despliegue

Los dominios deben desplegarse en el siguiente orden:

1. **Networking** (VPC, Subnets, Route Tables)
2. **Seguridad** (Security Groups, IAM Roles, KMS Keys)
3. **Workload** (ECS, RDS, Lambda, etc.)

### 5.2. Comunicación Entre Dominios

La comunicación debe seguir exclusivamente el patrón definido en **PC-IAC-017**:

```
Networking → outputs/tags → Data Sources → Seguridad
Networking → outputs/tags → Data Sources → Workload
Seguridad → outputs/tags → Data Sources → Workload
```

**Prohibido:**
- ❌ Uso de `terraform_remote_state` sin justificación (referencia **PC-IAC-019**)
- ❌ Hardcodeo de IDs de recursos entre dominios
- ❌ Creación cruzada de recursos

---

## 6. Excepciones Documentadas

### 6.1. Recursos Híbridos

Algunos recursos pueden considerarse híbridos y requieren evaluación caso por caso:

| Recurso | Dominio Recomendado | Justificación |
|---------|---------------------|---------------|
| `aws_lb` (ALB/NLB) | **Workload** | Específico de la aplicación |
| `aws_cloudwatch_log_group` | **Workload** | Logs específicos de la aplicación |
| `aws_s3_bucket` (estado) | **Seguridad** | Bucket de infraestructura crítica |
| `aws_s3_bucket` (app) | **Workload** | Bucket específico de aplicación |
| `aws_route53_zone` | **Networking** | Zona DNS compartida |
| `aws_route53_record` | **Workload** | Registros específicos de aplicación |

### 6.2. Documentación de Excepciones

Si un dominio necesita crear un recurso que normalmente pertenece a otro dominio, debe:

1. Documentar la excepción en el `README.md` del dominio
2. Justificar técnicamente la decisión
3. Obtener aprobación en revisión de código
4. Marcar para revisión futura si es deuda técnica

---

## 7. Criterios de Cumplimiento

✅ El Módulo Raíz solo declara recursos pertenecientes a su Dominio.  
✅ El dominio **Workload** utiliza `data` para obtener Security Groups y VPCs, en lugar de crearlos.  
✅ Los dominios se despliegan en el orden correcto (Networking → Seguridad → Workload).  
✅ La comunicación entre dominios usa Data Sources (referencia **PC-IAC-017**).  
✅ Las excepciones están documentadas y justificadas en el README.

---

## 8. Relación con Pilares AWS Well-Architected

| Pilar | Cómo contribuye esta regla |
| :--- | :--- |
| **Operational Excellence** | La separación clara de responsabilidades facilita el mantenimiento, el debugging y permite que equipos diferentes gestionen dominios independientes sin conflictos. |
| **Security** | La centralización de recursos de seguridad en un dominio único facilita la auditoría, el cumplimiento y la aplicación consistente de políticas de seguridad. |

---

## 9. Beneficios

1. **Modularidad:** Cada dominio puede evolucionar independientemente
2. **Escalabilidad de Equipos:** Equipos diferentes pueden gestionar dominios diferentes
3. **Reducción de Conflictos:** Menos probabilidad de conflictos en el estado de Terraform
4. **Auditoría Simplificada:** Más fácil auditar la seguridad al tener recursos centralizados
5. **Reutilización:** Networking y Seguridad pueden compartirse entre múltiples Workloads
