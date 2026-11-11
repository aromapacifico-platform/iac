> Codex adaptation: read repository AGENTS.md for current interfaces, versions and authorized scope.

# 📄 Regla de Data Sources y Consumo de Datos Externos

**ID:** PC-IAC-011  
**Tipo:** Flujo de Datos / Integración  
**Pilares AWS Well-Architected:** Operational Excellence, Security  
**Versión:** 1.0  
**Fecha:** 10 de diciembre de 2025

---

## 1. Propósito y Alcance

Esta regla define los estándares obligatorios para el uso de *Data Sources* (`data`) en Terraform. Su cumplimiento asegura que la recuperación de datos externos sea controlada, segura y que los módulos de referencia reciban datos limpios.

**Aplicable a:** Bloques `data` en el **Módulo Raíz (IaC Root)** y la prohibición de su uso en Módulos de Referencia.

---

## 2. Restricción de Uso (Ubicación)

### 2.1. Uso Exclusivo en IaC Root (Obligatorio)

La declaración de cualquier bloque `data "aws_..." "..."` está **estrictamente prohibida** dentro de los Módulos de Referencia.

* **Flujo Obligatorio:** Los *Data Sources* deben ser declarados solo en el Módulo Raíz. Los resultados (`data.aws_...`) deben ser recuperados y luego pasados al Módulo de Referencia a través de sus variables de entrada (`var.*`).
* **Razón:** Aísla el módulo de la capa de búsqueda de datos, haciéndolo más portable y fácil de probar.

### 2.2. Prohibición de Configuración Interna

Los Módulos de Referencia **nunca** deben contener bloques `data` (excepto *Data Sources* genéricos como `data.aws_region.current`).

---

## 3. Requisitos de Declaración de Data Sources

Todo bloque `data` debe cumplir con los siguientes requisitos:

| Atributo | Obligatorio | Descripción |
| :--- | :--- | :--- |
| **`type` y `name`** | **SÍ** | El nombre lógico debe seguir la convención `snake_case` (**PC-IAC-003**). |
| **Filtros** | **SÍ** | Se deben usar filtros explícitos (ej. `filter`, `tags`, `name`) para obtener el recurso. **Nunca** depender de búsquedas ambiguas. |

### 3.1. Prioridad en la Búsqueda

Se debe priorizar la búsqueda de recursos utilizando el **ARN**, **ID** o una combinación de **Tags** para asegurar que el recurso obtenido es el correcto.

* *Ejemplo Aceptado (Uso de Tags):*

    ```hcl
    data "aws_vpc" "selected" {
      tags = {
        Name = "VPC-Central-Dev"
      }
    }
    ```

---

## 4. Flujo de Datos y Conversión

### 4.1. Conversión de Salidas del Data Source

Si el *Data Source* devuelve una lista o una colección, y el módulo de referencia espera un solo valor (`string`), la conversión debe hacerse de forma segura en el Módulo Raíz.

* **Uso de `one()` (Recomendado):** Está prohibido usar la indexación `[0]` de una lista de resultados, a menos que se use la función `one()` para asegurar que solo existe un resultado.

    ```hcl
    # Uso de one() en el Módulo Raíz
    listener_arn = one(data.aws_lb_listener.selected.arn)
    ```

### 4.2. Inyección a Módulos

El resultado del *Data Source* se debe inyectar como el valor de una variable del módulo de referencia.

```hcl
module "ecs_cluster" {
  source = "..."
  
  vpc_id          = data.aws_vpc.selected.id
  private_subnets = data.aws_subnets.private.ids
}
```

## 5. Criterios de Cumplimiento

✅ Los bloques `data` solo se declaran en el Módulo Raíz.  
✅ Se usan filtros explícitos (ID, ARN o Tags) para garantizar la obtención del recurso correcto.  
✅ Se evita la indexación `[0]` de *Data Sources*, prefiriendo funciones como `one()`.  
✅ El resultado del Data Source se inyecta como `var.*` al Módulo de Referencia.

---

## 6. Relación con Pilares AWS Well-Architected

| Pilar | Cómo contribuye esta regla |
| :--- | :--- |
| **Operational Excellence** | La prohibición de *Data Sources* en módulos de referencia mejora la portabilidad y hace que los módulos sean más fáciles de mantener y probar. |
| **Security** | El requisito de filtros explícitos (Tags/ID) previene la obtención accidental de recursos de ambientes o cuentas incorrectas. |
