> Codex adaptation: read repository AGENTS.md for current interfaces, versions and authorized scope.

# 📄 Regla de Estructura de Llamada a Módulos (Ordering)

**ID:** PC-IAC-013  
**Tipo:** Estructura / Consistencia  
**Pilares AWS Well-Architected:** Operational Excellence  
**Versión:** 1.0  
**Fecha:** 10 de diciembre de 2025

---

## 1. Propósito y Alcance

Esta regla define la estructura y el orden obligatorio para la declaración de atributos dentro de los bloques `module { ... }`. Su cumplimiento garantiza la legibilidad inmediata del código, permitiendo a los mantenedores identificar rápidamente las dependencias y la configuración esencial del módulo.

**Aplicable a:** Todos los bloques `module` en el Módulo Raíz (IaC Root) y en cualquier otro módulo que consuma otro módulo de referencia.

---

## 2. Orden Obligatorio de Atributos en el Bloque `module`

Todos los bloques `module` deben declarar sus atributos en el siguiente orden estricto. Se debe incluir una línea en blanco (`\n`) para separar cada sección.

| # | Atributo o Sección | Propósito | Regla de Referencia |
| :--- | :--- | :--- | :--- |
| **A** | `source` y `version` | Ruta del código fuente y versión. | PC-IAC-001 |
| **B** | `providers` | Inyección del *provider* principal (`aws.principal`). | PC-IAC-005 |
| **C** | Variables de Gobernanza | Variables obligatorias para Nomenclatura y Tags (`client`, `project`, `environment`). | PC-IAC-003, PC-IAC-004 |
| **D** | Variables Transversales | Configuraciones compartidas o inyecciones de *Data Sources* (`vpc_id`, `region`). | PC-IAC-011 |
| **E** | Variables de Configuración | Estructuras de configuración complejas o específicas del recurso (`sg_rules`). | PC-IAC-002, PC-IAC-009 |
| **F** | Metargumentos | Ciclo de vida del módulo (`count`, `for_each`, `depends_on`). | PC-IAC-010 |

---

## 3. Estructura y Ejemplo

### 3.1. Estructura de Código

```hcl
module "example" {
  source = "../"

  providers = {
    aws.project = aws.principal
  }

  client        = var.client
  project       = var.project
  environment   = var.environment
  
  vpc_id        = module.vpc.vpc_id 
  private_subnets = data.aws_subnets.app_private.ids

  instance_type = "t3.medium"
  sg_rules = local.sg_rules_transformed


}
```

## 4. Criterios de Cumplimiento

✅ El bloque `module` sigue el orden estricto (A, B, C, D, E, F).  
✅ Las variables de Gobernanza (C) son declaradas antes que la Configuración Específica (E).  
✅ El bloque `providers` (B) está inmediatamente después de la fuente.  
✅ Se usan líneas en blanco para separar las secciones principales (B, C, D, E, F).

---

## 5. Relación con Pilares AWS Well-Architected

| Pilar | Cómo contribuye esta regla |
| :--- | :--- |
| **Operational Excellence** | El orden estricto facilita la lectura rápida del código y reduce el tiempo necesario para comprender y auditar la configuración, previniendo errores. |
