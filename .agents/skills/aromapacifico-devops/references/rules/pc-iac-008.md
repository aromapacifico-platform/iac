> Codex adaptation: read repository AGENTS.md for current interfaces, versions and authorized scope.

# 📄 Regla de Gestión de Estado (Backend)

**ID:** PC-IAC-008  
**Tipo:** Estado  
**Pilares AWS Well-Architected:** Security, Operational Excellence  
**Versión:** 1.0  
**Fecha:** 10 de diciembre de 2025

---

## 1. Propósito y Alcance

Esta regla define el estándar obligatorio para la configuración del *backend* (gestión de estado) en Terraform. Su cumplimiento asegura la persistencia, la integridad, el cifrado y el bloqueo del archivo de estado (`terraform.tfstate`).

**Aplicable a:** El bloque `backend` en el Módulo Raíz (IaC Root) y la prohibición de su uso en Módulos de Referencia.

---

## 2. Requisitos de Ubicación y Estándar de Backend

### 2.1. Ubicación (Obligatorio)

El bloque `backend` **debe** declararse exclusivamente en el **Módulo Raíz** (IaC Root) o en los directorios de ambiente que despliegan la infraestructura.

* **Prohibición:** Está **estrictamente prohibido** declarar el bloque `backend` en cualquier Módulo de Referencia.

### 2.2. Estándar de Backend S3

El único *backend* soportado es **AWS S3** para centralizar la gestión de estado.

* **Seguridad (Obligatorio):** Debe utilizarse el atributo `encrypt = true` para asegurar que el archivo de estado esté cifrado en reposo.
* **Integridad (Obligatorio):** Debe configurarse el bloqueo de estado mediante `use_lockfile = true` (o la configuración de DynamoDB, si se gestiona fuera de la IaC).

---

## 3. Modalidades de Configuración (Local vs Pipeline)

### 3.1. Configuración Estática Local (Uso de `profile`)

Para el desarrollo y pruebas locales, se permite la configuración estática del `backend` que incluye el `bucket`, `key`, `region` y el `profile` de AWS.

* **Uso:** Debe ser utilizado únicamente en entornos de desarrollo (`dev`) o local.

    ```hcl
    # Ejemplo de Backend Estático (Uso Local)
    backend "s3" {
      bucket       = "nombre-del-bucket-estado"
      key          = "ruta/a/terraform.tfstate"
      region       = "us-east-1"
      encrypt      = true
      use_lockfile = true
      profile      = "pra_backend_dev" # Solo para uso local/perfiles
    }
    ```

### 3.2. Configuración Dinámica (Uso en Pipelines)

Cuando el *backend* es administrado por el *pipeline* de CI/CD (ej. Azure DevOps, GitLab, Jenkins), la configuración debe ser **parcial o vacía**, confiando en que el *pipeline* inyectará las variables sensibles y de acceso.

* **Uso:** En entornos `qa`, `pdn` o cuando se utiliza `assume_role` para el despliegue.

    ```hcl
    # Ejemplo de Backend Vacío (Uso en Pipeline)
    terraform {
      # ... required_providers
      backend "s3" {} # Los atributos se inyectan en el 'terraform init' del pipeline
    }
    ```

---

## 4. Criterios de Cumplimiento

✅ El bloque `backend` reside solo en el Módulo Raíz (IaC Root).  
✅ Se utiliza exclusivamente el *backend* S3.  
✅ Se configura `encrypt = true` para el cifrado del estado.  
✅ Se incluye un mecanismo de bloqueo de estado (`use_lockfile` o similar).  
✅ El `backend` puede ser estático (con `profile`) o dinámico (vacío o parcial).

---

## 5. Relación con Pilares AWS Well-Architected

| Pilar | Cómo contribuye esta regla |
| :--- | :--- |
| **Security** | El requisito de `encrypt = true` asegura la confidencialidad del estado, el cual puede contener datos sensibles sobre la infraestructura. |
| **Operational Excellence** | El bloqueo de estado (lockfile) previene la corrupción del estado por ejecuciones simultáneas. La ubicación única en el Root simplifica la gestión. |
