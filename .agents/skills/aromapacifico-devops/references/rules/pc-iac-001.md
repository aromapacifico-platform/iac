> Codex adaptation: read repository AGENTS.md for current interfaces, versions and authorized scope.

# 📚 Regla de Estructura Obligatoria para Módulos de Referencia en Terraform

**ID:** PC-IAC-001  
**Tipo:** Básica  
**Pilares AWS Well-Architected:** Operational Excellence, Security  
**Versión:** 1.0  
**Fecha:** 10 de diciembre de 2025

---

## 1. Propósito y Alcance

Esta regla define la estructura mínima y obligatoria para cualquier Módulo de Referencia IaC en Terraform. Su cumplimiento garantiza:
- **Consistencia** en la organización de código
- **Mantenibilidad** facilitando el entendimiento y modificación
- **Auditabilidad** con historial de cambios documentado
- **Facilidad de uso** con ejemplos y documentación clara

**Aplicable a:** Todos los módulos Terraform publicados por el equipo.

**Alcance:** Esta regla define únicamente la estructura de archivos y directorios obligatorios. El contenido e implementación de cada módulo se desarrolla según los requisitos específicos del recurso AWS a gestionar.

---

## 2. Estructura del Módulo Raíz

El directorio principal del módulo (`nombre-del-modulo/`) debe contener obligatoriamente los siguientes archivos, cada uno con su responsabilidad definida:

| Archivo | Propósito Principal | Obligatorio |
| :--- | :--- | :--- |
| `.gitignore` | Reglas de exclusión para control de versiones Git. | **SÍ** |
| `CHANGELOG.md` | Historial versionado de cambios del módulo. | **SÍ** |
| `README.md` | Documentación de uso, inputs/outputs y requisitos. | **SÍ** |
| `data.tf` | Declaración de todos los Data Sources utilizados. | **SÍ** |
| `locals.tf` | Transformaciones y valores locales. | **SÍ** |
| `main.tf` | Declaración de recursos y lógica principal. | **SÍ** |
| `outputs.tf` | Declaración de todas las salidas (outputs) del módulo. | **SÍ** |
| `providers.tf` | Declaración y configuración de providers. | **SÍ** |
| `variables.tf` | Declaración de todas las variables de entrada. | **SÍ** |
| `versions.tf` | Requisitos de versión de Terraform y providers. | **SÍ** |

> **Nota:** Si el equipo decide gestionar `required_version` dentro de `providers.tf`, debe mantenerse consistente en todos los módulos. La opción recomendada es usar `versions.tf` dedicado.

---

## 3. Estructura del Directorio de Ejemplo (`sample/`)

El módulo debe incluir un subdirectorio `sample/` que contenga la estructura de archivos para implementación futura.

| Archivo | Propósito Principal | Obligatorio |
| :--- | :--- | :--- |
| `README.md` | Instrucciones de ejecución del ejemplo. | **SÍ** |
| `data.tf` | Data Sources necesarios para el ejemplo. | **SÍ** |
| `main.tf` | Raíz que invoca al módulo de referencia. | **SÍ** |
| `outputs.tf` | Outputs para validar la infraestructura del ejemplo. | **SÍ** |
| `providers.tf` | Providers configurados para el entorno del ejemplo. | **SÍ** |
| `terraform.tfvars` | Valores concretos de variables para ejecutar el ejemplo. | **SÍ** |
| `variables.tf` | Variables de entrada del ejemplo. | **SÍ** |

---

## 4. Árbol de Directorios de Referencia

```
nombre-del-modulo/
├─ .gitignore
├─ CHANGELOG.md
├─ README.md
├─ data.tf
├─ locals.tf
├─ main.tf
├─ outputs.tf
├─ providers.tf
├─ variables.tf
├─ versions.tf
└─ sample/
   ├─ README.md
   ├─ data.tf
   ├─ main.tf
   ├─ outputs.tf
   ├─ providers.tf
   ├─ terraform.tfvars
   └─ variables.tf
```

---

## 5. Contenido Mínimo de Archivos

Cada archivo debe existir y contener al menos un comentario descriptivo:

### Módulo Raíz:

**`.gitignore`**
```
```

**`CHANGELOG.md`**
```markdown

```

**`README.md`**
```markdown

Descripción del módulo
```

**`data.tf`**
```hcl
```

**`locals.tf`**
```hcl
```

**`main.tf`**
```hcl
```

**`outputs.tf`**
```hcl
```

**`providers.tf`**
```hcl
```

**`variables.tf`**
```hcl
```

**`versions.tf`**
```hcl
```

### Directorio `sample/`:

**`README.md`**
```markdown
```

**`data.tf`**
```hcl
```

**`main.tf`**
```hcl
```

**`outputs.tf`**
```hcl
```

**`providers.tf`**
```hcl
```

**`terraform.tfvars`**
```hcl
```

**`variables.tf`**
```hcl
```

---

## 6. Criterios de Cumplimiento

✅ Todos los archivos obligatorios del módulo raíz existen (10 archivos)  
✅ Todos los archivos obligatorios de `sample/` existen (7 archivos)  
✅ Cada archivo contiene al menos un comentario descriptivo  
✅ `.gitignore` incluye reglas básicas para archivos de Terraform  
✅ `CHANGELOG.md` tiene estructura básica  
✅ `README.md` del módulo raíz existe  

---

## 7. Relación con Pilares AWS Well-Architected

| Pilar | Cómo contribuye esta regla |
| :--- | :--- |
| **Operational Excellence** | Estructura consistente que facilita comprensión y mantenimiento del código. |
| **Security** | `.gitignore` previene exposición accidental de secretos y archivos de estado. |

---

## 8. Validación de Estructura

Verificar que existen todos los archivos obligatorios:

```bash
ls -1 nombre-del-modulo/

ls -1 nombre-del-modulo/sample/
```

---

## 9. Referencias

- [Terraform Module Structure](https://developer.hashicorp.com/terraform/language/modules/develop/structure)
- [Keep a Changelog](https://keepachangelog.com/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
