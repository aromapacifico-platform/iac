> Codex adaptation: read repository AGENTS.md for current interfaces, versions and authorized scope.

# 📄 Regla de Outputs (Salidas del Módulo)

**ID:** PC-IAC-007  
**Tipo:** Flujo de Datos  
**Pilares AWS Well-Architected:** Operational Excellence, Security  
**Versión:** 1.0  
**Fecha:** 10 de diciembre de 2025

---

## 1. Propósito y Alcance

Esta regla define los estándares obligatorios para la declaración de salidas (`output`) en el archivo `outputs.tf`. Su cumplimiento asegura:

- **Usabilidad:** Exponer solo la información necesaria para el consumo externo.
- **Seguridad:** Prevenir la exposición de secretos o datos internos innecesarios.
- **Consistencia:** Estandarizar la documentación y el formato de las salidas.

**Aplicable a:** Todas las declaraciones de `output` en cualquier Módulo de Referencia.

---

## 2. Requisitos de Declaración Obligatorios

Todo *output* debe declararse con los siguientes atributos:

| Atributo | Obligatorio | Descripción |
| :--- | :--- | :--- |
| **`value`** | **SÍ** | El valor del atributo de recurso que se expone. |
| **`description`** | **SÍ** | Una descripción clara y concisa de la información que se devuelve y su propósito. |
| **`sensitive`** | **NO** | Usar `sensitive = true` solo si el valor es un secreto indispensable. **Por defecto, NO debe usarse.** |

---

## 3. Principios de Granularidad y Contenido

### 3.1. Granularidad Estricta (Solo lo Necesario)

Los *outputs* deben ser **granulares** y exponer solo los identificadores o atributos requeridos por los módulos consumidores.

* **Aceptado (Granular):** Exponer `aws_vpc.this.id` como `vpc_id`.
* **NO Aceptado (Objeto Completo):** Exponer el objeto completo del recurso (`aws_vpc.this`).

### 3.2. Prohibición de Datos Sensibles (Por Defecto)

* **Regla:** El uso de `sensitive = true` está permitido solo si la información expuesta es técnicamente indispensable (ej. una clave API generada por el módulo).
* **Default de Seguridad:** Si un valor **puede** ser recuperado de forma segura de otra manera (ej. *Data Source*, *Secrets Manager*), **no debe** ser expuesto como *output*.

### 3.3. Consistencia de Nomenclatura

Los nombres de los *outputs* deben seguir la convención **`snake_case`** (referencia **PC-IAC-003**) y ser descriptivos.

| Nombre de Output | Descripción |
| :--- | :--- |
| `[nombre_recurso]_id` | Identificador único del recurso (ej. `vpc_id`). |
| `[nombre_recurso]_arn` | ARN del recurso (ej. `s3_bucket_arn`). |
| `[nombre_recurso]_names` | Mapa o lista de nombres si son múltiples recursos (ej. `private_subnet_ids`). |

---

## 4. Implementación y Estructura

Los *outputs* deben utilizar la interpolación de cadenas o colecciones (como `tolist`, `tomap`, `for`) para estandarizar el formato de salida.

### Ejemplo

```hcl
output "vpc_id" {
  description = "El ID de la Virtual Private Cloud (VPC) creada."
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "Lista de IDs de las subredes privadas creadas por el módulo."
  value       = values(aws_subnet.private)[*].id
}
```
## 5. Criterios de Cumplimiento

✅ Todo *output* incluye el atributo `description`.  
✅ El nombre del *output* sigue la convención **`snake_case`**.  
✅ El *output* expone valores granulares (ID, ARN) en lugar de objetos de recursos completos.  
✅ Se evita el uso de `sensitive = true` a menos que sea estrictamente necesario.

---

## 6. Relación con Pilares AWS Well-Architected

| Pilar | Cómo contribuye esta regla |
| :--- | :--- |
| **Security** | El requisito de granularidad y la prohibición por defecto de `sensitive` minimiza la superficie de ataque y la exposición accidental de credenciales o datos internos. |
| **Operational Excellence** | La documentación obligatoria (`description`) y la granularidad aseguran que los módulos consumidores entiendan exactamente qué valor están recibiendo, mejorando la integración. |
