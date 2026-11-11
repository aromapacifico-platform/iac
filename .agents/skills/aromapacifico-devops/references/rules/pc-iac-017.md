> Codex adaptation: read repository AGENTS.md for current interfaces, versions and authorized scope.

# 📄 Regla de Comunicación entre Dominios (Data Sources)

**ID:** PC-IAC-017  
**Tipo:** Integración / Flujo de Datos  
**Pilares AWS Well-Architected:** Operational Excellence, Security  
**Versión:** 1.0  
**Fecha:** 10 de diciembre de 2025

---

## 1. Propósito y Alcance

Esta regla define el estándar obligatorio para compartir información entre diferentes dominios de infraestructura (Networking, Seguridad, Observabilidad, Workload). Su objetivo es minimizar el acoplamiento entre estados de Terraform y garantizar que cada dominio solo recupere la información que necesita.

**Aplicable a:** El Módulo Raíz (IaC Root) de los dominios que consumen infraestructura base (Seguridad, Observabilidad, Workload).

---

## 2. Prioridad en la Comunicación

### 2.1. Data Sources (Mandatorio)

El mecanismo principal y obligatorio para la comunicación de datos entre dominios debe ser la recuperación mediante **Data Sources**.

* **Ventajas (Motivo del Mandato):** Data Sources ofrecen menos acoplamiento entre capas, no requieren exponer todos los *outputs* del estado anterior y son más flexibles para cambios.
* **Requisito de PC-IAC-011:** Los *Data Sources* deben usar la configuración explícita (Tags, ID, ARN) para la búsqueda y deben residir solo en el Módulo Raíz del dominio consumidor.

### 2.2. Uso Restringido de Remote State

El uso de `data "terraform_remote_state"` está **restringido** y se considera una alternativa de baja prioridad. Solo se permite si la complejidad del *Data Source* para recuperar el recurso es prohibitiva.

* **Regla:** Si se utiliza *Remote State*, se debe documentar explícitamente la razón de la excepción en el archivo `README.md` del dominio.

---

## 3. Estándar de Búsqueda de Recursos

### 3.1. Uso de Nomenclatura Estándar

El *Data Source* debe utilizar la **Nomenclatura Estándar** definida en **PC-IAC-003** y **PC-IAC-004** para filtrar los recursos.

* **Patrón Obligatorio:** La búsqueda debe construirse utilizando las variables de gobernanza (`client`, `project`, `environment`) para asegurar que se obtienen los recursos correctos del ambiente específico.

    ```hcl
    # Ejemplo de Búsqueda de VPC por Nomenclatura (en security/data.tf)
    data "aws_vpc" "vpc" {
      # ...
      filter {
        name   = "tag:Name"
        values = ["${var.client}-${var.project}-${var.environment}-vpc"]
      }
    }
    ```

### 3.2. Extracción de Colecciones

La recuperación de colecciones de recursos (ej. subredes) debe seguir el estándar de *Splat Expressions* (**PC-IAC-014**) para extraer solo la información requerida (IDs, ARNs).

---

## 4. Flujo de Comunicación (Inyección de Datos)

El resultado de la recuperación del *Data Source* se debe inyectar en el módulo de referencia (Workload, Seguridad, etc.) mediante variables de entrada.

* **Flujo:** `Data Source (Root) → Variable (Root) → Module (Workload)`.

    ```hcl
    # En workload/main.tf
    module "ecs_cluster" {
      # ...
      vpc_id          = data.aws_vpc.vpc.id      # Inyección del Data Source
      private_subnets = data.aws_subnets.private.ids
    }
    ```

---

## 5. Criterios de Cumplimiento

✅ La comunicación entre dominios utiliza **Data Sources**.  
✅ La búsqueda de recursos utiliza los filtros basados en la **Nomenclatura Estándar** (`client`, `project`, `environment`).  
✅ Se restringe el uso de `terraform_remote_state`.  
✅ Los *Data Sources* inyectan valores granulares (`id`, `arn`) en las variables de los Módulos de Referencia.

---

## 6. Relación con Pilares AWS Well-Architected

| Pilar | Cómo contribuye esta regla |
| :--- | :--- |
| **Operational Excellence** | El uso de *Data Sources* como mecanismo principal reduce el acoplamiento y simplifica la gestión de dependencias entre dominios. |
| **Security** | El uso de filtros estrictos y Tags previene que un dominio acceda o utilice infraestructura de un ambiente o proyecto incorrecto. |
