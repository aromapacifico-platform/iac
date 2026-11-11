> Codex adaptation: read repository AGENTS.md for current interfaces, versions and authorized scope.

## 📄 Regla de Centralización de Configuración en Locals

**ID:** PC-IAC-021  
**Tipo:** Flujo de Datos / Estructura Root  
**Pilares AWS Well-Architected:** Operational Excellence  
**Versión:** 1.0  
**Fecha:** 10 de diciembre de 2025

---

## 1. Propósito y Alcance

Esta regla prohíbe la declaración de estructuras de datos complejas (colecciones `map(object)`, `list(object)`) directamente dentro de los bloques `module` en el archivo `main.tf` del Módulo Raíz. Su objetivo es mantener `main.tf` limpio y auditable, y centralizar la gestión de configuración en `locals.tf` y archivos `.tfvars`.

**Aplicable a:** Bloques `module` en `main.tf` del Módulo Raíz (Proyectos de Dominio).

---

## 2. Flujo Obligatorio de Configuración Compleja

### 2.1. Definición Inicial y `locals.tf`

Toda configuración compleja y específica del ambiente (ej. la definición del `map(object)` de `instances`) debe residir en los archivos `.tfvars` de ambiente y ser pasada a través de una `variable`.

### 2.2. Uso Obligatorio de `locals.tf` para la Invocación

La variable de configuración compleja **debe** ser pasada al bloque `module` desde un valor `local` y **no directamente** si su contenido excede tres líneas.

* **Flujo Obligatorio:** `var.config (desde .tfvars) -> local.config_transformed (en locals.tf) -> module.resource`
* **Excepción:** Se permiten valores simples (strings, numbers, booleans) directamente en el bloque `module`.

#### Ejemplo de Código Aceptado (PC-IAC-021 CUMPLIDA)

```hcl
locals {
  instances_to_create = merge(var.instances, { 
    base_tags = var.common_tags 
  }) 
}

module "ec2_instances" {
  source = "..."
  instances = local.instances_to_create 
}

```

## 3. Criterios de Cumplimiento

✅ La configuración compleja (`map(object)`, `list(object)`) no está definida directamente en el bloque `module` en `main.tf`.  
✅ La configuración se inyecta desde un valor `local` que la recibe de `var.*` o realiza la transformación (PC-IAC-009).
