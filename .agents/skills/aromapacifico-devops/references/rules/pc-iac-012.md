> Codex adaptation: read repository AGENTS.md for current interfaces, versions and authorized scope.

# 📄 Regla de Estructuras de Datos y Reutilización en Locals

**ID:** PC-IAC-012  
**Tipo:** Lógica Interna / Estructura  
**Pilares AWS Well-Architected:** Operational Excellence, Cost Optimization  
**Versión:** 1.0  
**Fecha:** 10 de diciembre de 2025

---

## 1. Propósito y Alcance

Esta regla define la estructura, organización y propósito del archivo `locals.tf`. Su objetivo es centralizar los valores calculados, prefijos de nombres y estructuras de datos reutilizables, manteniendo `main.tf` legible y enfocado en la declaración de recursos.

**Aplicable a:** El archivo `locals.tf` en el Módulo Raíz (IaC Root) y en los Módulos de Referencia.

---

## 2. Estructura y Organización del Archivo

### 2.1. Bloque `locals` Único

* **Obligatorio:** Cada archivo `.tf` (principalmente `locals.tf`) solo debe contener **un único** bloque `locals { ... }`. Todos los valores locales deben definirse dentro de este bloque.

### 2.2. Nomenclatura y Orden

* **Nombres:** Los nombres de los valores locales deben seguir la convención **`snake_case`** (**PC-IAC-003**).
* **Orden Lógico:** Los valores dentro del bloque `locals` deben organizarse de forma jerárquica, desde los valores más básicos y reutilizables hasta las estructuras de configuración finales.

---

## 3. Estructuras de Datos Transversales (Módulos de Referencia)

Los módulos de referencia deben definir y centralizar las estructuras de datos que se usan repetidamente, facilitando la implementación de otras reglas.

### 3.1. Mapa de Prefijos de Nomenclatura

Debe definirse un prefijo base de gobernanza que combine las variables de alto nivel para su posterior uso en la construcción de nombres (**PC-IAC-003**).

* **Recomendado:** `governance_prefix = "${var.client}-${var.project}-${var.environment}"`

### 3.2. Mapa de Etiquetas Comunes (Si Aplica)

Si el módulo necesita definir un conjunto de etiquetas base para ser fusionadas con *tags* adicionales (**PC-IAC-004**), estas deben definirse en `locals.tf`.

* **Recomendado:** `base_module_tags = { "managed-by" = "terraform", "module" = "vpc" }`

---

## 4. Gestión de Estructuras Complejas

### 4.1. Transformación de Variables de Entrada

Toda transformación de estructuras de datos complejos (utilizando la lógica de inyección de ARNs y IDs de **PC-IAC-009**) debe resultar en un nuevo valor local con un nombre descriptivo.

* **Patrón:** `var.original_config` se convierte en `local.transformed_config` (o `local.config_with_defaults`).

### 4.2. Aplanamiento de Listas Anidadas (`flatten`)

Cuando las variables de entrada utilizan listas anidadas, la función **`flatten()`** debe usarse en `locals.tf` para simplificar la iteración con `for_each` o `count` en `main.tf`.

* **Propósito:** Evitar lógica compleja en el bloque `resource` y crear una lista simple y consumible de objetos.

    ```hcl
    locals {
      # Uso obligatorio de flatten para colecciones complejas
      all_subnets_flat = flatten([
        for netkwork_key, network in var.subnet_config : [
          for subnet in network.subnets : {
            # ... mapeo de atributos
          }
        ]
      ])
    }
    ```

---

## 5. Criterios de Cumplimiento

✅ Se utiliza un **único** bloque `locals { ... }` por archivo `locals.tf`.  
✅ Los valores locales siguen la convención de nomenclatura `snake_case` (**PC-IAC-003**).  
✅ Se definen prefijos de gobernanza y estructuras de *tags* para reutilización.  
✅ Se utiliza `flatten()` para simplificar listas anidadas de configuración.  
✅ Se crean valores locales intermedios para toda configuración dinámica inyectada (**PC-IAC-009**).

---

## 6. Relación con Pilares AWS Well-Architected

| Pilar | Cómo contribuye esta regla |
| :--- | :--- |
| **Operational Excellence** | La centralización de la lógica en `locals.tf` facilita la depuración, el mantenimiento y la comprensión del código. |
| **Cost Optimization** | La reutilización de prefijos de nombres y mapas de *tags* asegura que la nomenclatura y el etiquetado sean consistentes, optimizando los reportes de costos. |
