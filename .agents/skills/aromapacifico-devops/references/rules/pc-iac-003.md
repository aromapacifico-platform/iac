> Codex adaptation: read repository AGENTS.md for current interfaces, versions and authorized scope.

# 📄 Regla de Nomenclatura para Elementos de Terraform y Recursos AWS

**ID:** PC-IAC-003  
**Tipo:** Nomenclatura  
**Pilares AWS Well-Architected:** Operational Excellence, Cost Optimization  
**Versión:** 1.0  
**Fecha:** 10 de diciembre de 2025

---

## 1. Propósito y Alcance

Esta regla define los estándares obligatorios de nomenclatura para asegurar la consistencia tanto en los identificadores internos de HCL como en los nombres físicos de los recursos creados en AWS.

**Aplicable a:**
1.  **Nombres Lógicos HCL:** Variables, Outputs, Locals, Recursos, Data Sources.
2.  **Nombres Físicos de Recursos AWS:** Atributos como `name`, `bucket`, `identifier`, etc.

---

## 2. Nomenclatura Lógica HCL (Identificadores Internos)

Todos los identificadores internos utilizados en el código HCL (archivos `.tf`) deben seguir estrictamente la convención **`snake_case`**.

| Elemento HCL | Formato Obligatorio | Ejemplo Aceptado |
| :--- | :--- | :--- |
| **Recursos** (`resource`) | `snake_case` | `aws_s3_bucket.main_bucket` |
| **Data Sources** (`data`) | `snake_case` | `data.aws_ami.latest_amazon_linux` |
| **Variables** (`variable`) | `snake_case` | `variable "instance_type"` |
| **Outputs** (`output`) | `snake_case` | `output "security_group_id"` |
| **Valores Locales** (`locals`) | `snake_case` | `local.common_tags` |
| **Recurso Principal** | `this` | `resource "aws_vpc" "this"` |

---

## 3. Nomenclatura Física de Recursos AWS (Construcción Obligatoria)

### 3.1. Patrón Obligatorio

Todos los nombres de recursos de AWS deben seguir rigurosamente el siguiente patrón, utilizando **guiones (`-`)** como único separador:

$${client}-{project}-{environment}-{type}-{key}$$

### 3.2. Restricciones y Requisitos

| Componente | Origen (Variable PC-IAC-002) | Restricciones | Longitud Máx. (Estándar) |
| :--- | :--- | :--- | :--- |
| **{client}** | `var.client` | Alfanumérico, minúsculas | Máx 10 caracteres |
| **{project}** | `var.project` | Alfanumérico, minúsculas | Máx 15 caracteres |
| **{environment}** | `var.environment` | `dev`, `qa`, `pdn` (u otros definidos) | |
| **{type}** | Definido en `locals.tf` | Abreviatura estándar del recurso (ej. `s3`, `rds`, `vpc`). | |
| **{key}** | Clave del mapa (si usa `for_each`) o identificador singular. | Alfanumérico, minúsculas | Máx 20 caracteres |

* **Separador Obligatorio:** Guión (`-`). Prohibido usar guiones bajos (`_`) o puntos (`.`).
* **Límite de Caracteres Estándar:** El nombre construido **no debe exceder los 28 caracteres** en total, a menos que las restricciones del servicio AWS lo impidan (en cuyo caso se debe acortar el componente `{key}` o `{project}`).

---

## 4. Implementación Obligatoria en `locals.tf`

### 4.1. Construcción Centralizada (Obligatorio)

La lógica para construir el nombre físico de los recursos debe residir **exclusivamente** en el archivo `locals.tf`. El archivo `main.tf` solo debe consumir la variable local ya construida.

* **Ejemplo de `locals.tf`:**

```hcl
locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  s3_main_bucket_name = "${local.governance_prefix}-s3-primary"

  rds_instance_names = {
    for key, config in var.rds_clusters : key => "${local.governance_prefix}-rds-${key}"
  }
}
```

## 4. Implementación Obligatoria en `locals.tf`

### 4.1. Construcción Centralizada (Obligatorio)

La lógica para construir el nombre físico de los recursos debe residir **exclusivamente** en el archivo `locals.tf`. El archivo `main.tf` solo debe consumir la variable local ya construida.

* **Ejemplo de `locals.tf`:**

```hcl
locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  s3_main_bucket_name = "${local.governance_prefix}-s3-primary"

  rds_instance_names = {
    for key, config in var.rds_clusters : key => "${local.governance_prefix}-rds-${key}"
  }
}
```

## 5. Criterios de Cumplimiento

✅ Los identificadores internos HCL usan **`snake_case`** (`PC-IAC-003, Sec. 2`).  
✅ Los nombres físicos de AWS siguen estrictamente el patrón **`{client}-{project}-{environment}-{type}-{key}`** (`PC-IAC-003, Sec. 3`).  
✅ El nombre es construido y centralizado en el archivo **`locals.tf`** (`PC-IAC-003, Sec. 4`).  
✅ Se usan **guiones (`-`)** como únicos separadores en el nombre físico.  
✅ Se utilizan las **Variables Globales** (`client`, `project`, `environment`) definidas en PC-IAC-002.

## 6. Relación con Pilares AWS Well-Architected

| Pilar | Cómo contribuye esta regla |
| :--- | :--- |
| **Operational Excellence** | Nomenclatura consistente facilita la identificación, el filtrado, la búsqueda y la resolución de problemas en la consola y logs. |
| **Cost Optimization** | La inclusión obligatoria de `{client}` y `{project}` en el nombre permite la atribución de costos y la visibilidad de gastos por proyecto. |
