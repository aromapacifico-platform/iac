> Codex adaptation: read repository AGENTS.md for current interfaces, versions and authorized scope.

# 📄 Regla de Configuración y Alias de Providers

**ID:** PC-IAC-005  
**Tipo:** Providers  
**Pilares AWS Well-Architected:** Operational Excellence, Security  
**Versión:** 1.0  
**Fecha:** 10 de diciembre de 2025

---

## 1. Propósito y Alcance

Esta regla define los estándares obligatorios para la configuración de los bloques `provider "aws"` y la gestión de alias. Su cumplimiento garantiza la consistencia en las credenciales, la asunción de roles y la aplicación de etiquetas globales.

**Aplicable a:** Bloques `provider` en el Módulo Raíz (IaC de Referencia) y la declaración de `configuration_aliases` en los Módulos de Referencia.

---

## 2. Configuración del Provider Principal (Módulo Raíz)

El Módulo Raíz (IaC de Referencia) debe declarar un único *provider* principal que contenga toda la configuración de gobernanza transversal.

### 2.1. Alias Principal (Obligatorio)

El *provider* principal debe utilizar el `alias = "principal"` para estandarizar su identificación y facilitar la inyección a los módulos.

### 2.2. Configuración de Seguridad y Gobernanza

El *provider* principal debe incluir la siguiente configuración obligatoria, gestionada a través de variables de entrada (referencia **PC-IAC-002**):

* **Región:** Declaración obligatoria de `region = var.region`.
* **Asunción de Rol (`assume_role`):** Debe configurarse utilizando una variable de entrada (`var.deploy_role_arn`) para asegurar el principio de menor privilegio en los *pipelines* de despliegue.
* **Etiquetas Globales (`default_tags`):** Debe incluirse el bloque `default_tags` para aplicar la **PC-IAC-004** de forma transversal.

```hcl
provider "aws" {
  region  = var.region
  alias   = "principal"
  
  assume_role {
    role_arn = var.deploy_role_arn
  }

  default_tags {
    tags = var.common_tags # Requisito de PC-IAC-004
  }
}
```

## 3. Uso de Providers en Módulos de Referencia

Los Módulos de Referencia deben consumir el *provider* principal inyectado desde el Módulo Raíz utilizando la siguiente convención.

### 3.1. Alias Consumidor (`aws.project`)

Todo Módulo de Referencia **debe** definir un alias local llamado `aws.project` para consumir el *provider* principal inyectado.

* **Declaración en el Módulo de Referencia:** El módulo debe declarar este alias utilizando `configuration_aliases` en `versions.tf`.

    ```hcl
    # En el versions.tf del Módulo de Referencia
    terraform {
      required_providers {
        aws = {
          source                = "hashicorp/aws"
          version               = ">= 6.72.0, < 7.0.0"
          configuration_aliases = [aws.project] # Alias Consumidor Obligatorio
        }
      }
    }
    ```

### 3.2. Referencia Explícita en Recursos

Cada recurso dentro del Módulo de Referencia **debe** referenciar explícitamente el alias consumidor `aws.project`.

* **Obligatorio:** `provider = aws.project`

    ```hcl
    resource "aws_vpc" "vpc" {
      provider = aws.project # Referencia explícita al alias
      # ...
    }
    ```

---

## 4. Criterios de Cumplimiento

✅ El *provider* principal en el Root utiliza `alias = "principal"` (Sec. 2.1).  
✅ El *provider* principal configura `region`, `assume_role` y `default_tags` (Sec. 2.2).  
✅ Los Módulos de Referencia consumen el *provider* mediante el alias `aws.project` (Sec. 3.1).  
✅ Cada recurso en los Módulos de Referencia referencia explícitamente `provider = aws.project` (Sec. 3.2).

---

## 5. Relación con Pilares AWS Well-Architected

| Pilar | Cómo contribuye esta regla |
| :--- | :--- |
| **Security** | La asunción obligatoria de roles (`assume_role`) asegura que la identidad de despliegue opere con el principio de menor privilegio. |
| **Operational Excellence** | El uso estandarizado de alias (`principal`, `project`) permite el uso de múltiples *providers* de manera controlada. |
