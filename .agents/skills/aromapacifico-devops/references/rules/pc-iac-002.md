> Codex adaptation: read repository AGENTS.md for current interfaces, versions and authorized scope.

# 📄 Regla de Variables Obligatorias y Buenas Prácticas de Declaración

**ID:** PC-IAC-002  
**Tipo:** Variables  
**Pilares AWS Well-Architected:** Operational Excellence, Security  
**Versión:** 1.0  
**Fecha:** 10 de diciembre de 2025

---

## 1. Propósito y Alcance

Esta regla define los estándares obligatorios para la declaración de variables de entrada en el archivo `variables.tf`. Su cumplimiento garantiza:
- **Gobernanza:** Asegura la presencia de variables clave para la construcción de nombres y el tagging.
- **Estabilidad:** Promueve estructuras de datos que previenen la destrucción innecesaria de recursos.
- **Calidad de Datos:** Exige la validación de todos los valores de entrada.

**Aplicable a:** Todas las declaraciones de variables (`variable { ... }`) en cualquier Módulo de Referencia.

---

## 2. Requisitos de Declaración Obligatorios (Metadatos)

Toda variable debe ser declarada con los siguientes atributos para garantizar la correcta documentación y tipificación:

| Atributo | Obligatorio | Descripción |
| :--- | :--- | :--- |
| **`type`** | **SÍ** | Especificar explícitamente el tipo de dato (string, number, bool, list, map, object, tuple). |
| **`description`** | **SÍ** | Una descripción clara y concisa de la variable, su propósito y, si aplica, su formato esperado. |
| **`validation`** | **SÍ** | Se debe incluir al menos un bloque `validation` que asegure la calidad del dato (ej. no nulo, formato regex, o cumplimiento de reglas de negocio). |

> **Nota sobre `default`:** El atributo `default` es **opcional**. Se recomienda utilizarlo solo para valores predecibles que no impactan la infraestructura. Para variables críticas (ej. identificadores de recursos), no debe usarse `default` para forzar la especificación del valor por el usuario.

---

## 3. Variables de Control Globales (Obligatorias en la Raíz)

Todo Módulo de Referencia debe aceptar las siguientes variables de control global, las cuales son requeridas para la construcción de nombres de recursos y la aplicación de etiquetas.

| Nombre de Variable | Tipo | Validación Mínima | Propósito |
| :--- | :--- | :--- | :--- |
| **`client`** | `string` | Condición de `length(var.client) > 0`. | Nombre del cliente/unidad de negocio. |
| **`project`** | `string` | Condición de `length(var.project) > 0`. | Nombre del proyecto específico. |
| **`environment`** | `string` | Condición de `contains(["dev", "qa", "pdn", ...], var.environment)`. | Entorno de despliegue (Desarrollo, QA, Producción, etc.). |

---

## 4. Estabilidad en Variables de Colección de Recursos

### 4.1. Estabilidad para `for_each`

Para la definición de múltiples recursos del mismo tipo (que serán utilizados con el metargumento `for_each`), es **obligatorio** el uso de `map(object)` en lugar de `list(object)` para garantizar la estabilidad:

* **Estructura Obligatoria:** `type = map(object({...}))`
* **Justificación:** El uso de claves únicas en el mapa previene la destrucción y re-creación de recursos cuando un elemento intermedio es eliminado o modificado en el archivo de valores.

### 4.2. Valores Opcionales en Objetos

Los valores que no sean obligatorios o que deban tener un valor por defecto deben utilizar la función `optional()` de Terraform.

* **Ejemplo:** `deployment_maximum_percent = optional(number, 200)`

---

## 5. Requisitos de Validación y Seguridad

### 5.1. Bloques de Validación Obligatorios

Es obligatorio que las variables críticas incluyan validaciones que aseguren:

1.  **No Nulo/Vacío:** Para variables `string` o `list/map` requeridas.
2.  **Cumplimiento de Regla de Negocio:** Validación de formatos (ej. ARN, URL) o rangos numéricos.
3.  **Lógica Interna:** Validación de coherencia entre los campos del objeto (ej. que una clave referenciada exista).

### 5.2. Manejo de Variables Sensibles

Toda variable que contenga información confidencial (ej. contraseñas, claves secretas, tokens) debe incluir el atributo:

```hcl
sensitive = true
```

### 5.3. Uso de Archivos `terraform.tfvars`

* **Prohibición de Secretos:** Los archivos `terraform.tfvars` o `*.auto.tfvars` **no deben contener valores sensibles o secretos en texto plano**.
* **Inyección de Secretos:** Los secretos deben ser inyectados en tiempo de ejecución utilizando mecanismos seguros (ej. Secret Manager, Vault o variables de entorno).

---

## 6. Criterios de Cumplimiento (Checklist)

✅ Toda variable declara explícitamente los atributos `type`, `description` y al menos un bloque `validation`.  
✅ Las variables `client`, `project` y `environment` son declaradas y validadas.  
✅ Se utiliza `map(object)` para colecciones de recursos que utilizan `for_each` (obligatorio para estabilidad).  
✅ Los valores opcionales dentro de bloques `object` utilizan la función `optional()`.  
✅ Las variables que contienen secretos están marcadas con `sensitive = true`.

---

## 7. Relación con Pilares AWS Well-Architected

| Pilar | Cómo contribuye esta regla |
| :--- | :--- |
| **Operational Excellence** | La tipificación estricta y las validaciones previenen errores de despliegue. El uso de mapas mejora la estabilidad del módulo. |
| **Security** | El uso de `sensitive = true` y la prohibición de secretos en `tfvars` protegen información confidencial. |
