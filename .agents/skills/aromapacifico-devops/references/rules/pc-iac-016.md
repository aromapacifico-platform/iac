> Codex adaptation: read repository AGENTS.md for current interfaces, versions and authorized scope.

# 📄 Regla de Manejo de Secretos y Datos Sensibles

**ID:** PC-IAC-016  
**Tipo:** Seguridad / Variables  
**Pilares AWS Well-Architected:** Security  
**Versión:** 1.0  
**Fecha:** 10 de diciembre de 2025

---

## 1. Propósito y Alcance

Esta regla define los estándares de seguridad obligatorios para el manejo de credenciales, claves, *tokens* o cualquier dato sensible en la IaC. Su cumplimiento garantiza que los secretos no sean almacenados en texto plano en repositorios o en archivos de estado.

**Aplicable a:**
1.  Todo el código fuente y archivos de configuración (`.tfvars`).
2.  Declaraciones de variables (`variables.tf`).

---

## 2. Prohibición de Almacenamiento y Archivos

### 2.1. Nunca Commitear Secretos (Mandatorio)

Está **estrictamente prohibido** almacenar o *commitear* cualquier secreto, clave, contraseña o credencial en texto plano directamente en el repositorio Git.

* **Prohibición de `tfvars`:** Los archivos `terraform.tfvars`, `*.auto.tfvars` o cualquier archivo de variables **no deben** contener valores sensibles.
* **Mecanismo de Inyección:** Los secretos deben ser inyectados en tiempo de ejecución utilizando mecanismos seguros.

### 2.2. Gestión del Archivo de Estado

El estado de Terraform (`terraform.tfstate`) debe estar siempre protegido.

* **Requisito:** El *backend* S3 debe configurarse con `encrypt = true` (referencia **PC-IAC-008**) para asegurar que el estado esté encriptado en reposo.

---

## 3. Manejo de Variables Sensibles en HCL

### 3.1. Atributo `sensitive = true` (Obligatorio)

Toda variable en `variables.tf` que esté destinada a recibir un secreto, clave o contraseña debe incluir el atributo `sensitive = true`.

* **Efecto:** Terraform omitirá el valor del *output* en la consola y lo ofuscará en el archivo de estado, aumentando la seguridad.

    ```hcl
    variable "database_password" {
      description = "Contraseña maestra de la base de datos."
      type        = string
      sensitive   = true # Obligatorio
    }
    ```

### 3.2. Prohibición de Outputs Sensibles

Los Módulos de Referencia deben **evitar exponer secretos** generados como *outputs*.

* **Regla:** Si un secreto es generado internamente, solo se puede exponer si está marcado con `sensitive = true` (referencia **PC-IAC-007**) y si es estrictamente necesario para la operatividad de un módulo posterior.

---

## 4. Mecanismos de Inyección Segura

Se deben utilizar los siguientes mecanismos para inyectar valores sensibles en el *pipeline* de despliegue:

1.  **Servicios de Secretos:** (Recomendado) Utilizar servicios dedicados como AWS Secrets Manager o HashiCorp Vault.
2.  **Variables de Entorno:** Utilizar variables de entorno de CI/CD (ej. `TF_VAR_db_password`), que no son visibles en los logs del plan ni del apply.
3.  **Data Sources Seguros:** En el Módulo Raíz, se puede utilizar un `data` *source* para obtener el secreto en tiempo de ejecución (ej. `data "aws_secretsmanager_secret"...`).

---

## 5. Criterios de Cumplimiento

✅ Los secretos nunca son *commiteados* al repositorio (incluyendo `.tfvars`).  
✅ Las variables que reciben secretos utilizan `sensitive = true`.  
✅ El *backend* S3 está configurado con cifrado (`encrypt = true`).  
✅ La inyección de secretos se realiza a través de variables de entorno o servicios de secretos.

---

## 6. Relación con Pilares AWS Well-Architected

| Pilar | Cómo contribuye esta regla |
| :--- | :--- |
| **Security** | El uso de `sensitive = true` y la prohibición de almacenamiento en Git o `tfvars` mitigan el riesgo de compromiso de credenciales y asegura el principio de *least privilege*. |
| **Operational Excellence** | La inyección estandarizada a través de servicios de secretos mejora el ciclo de vida y la rotación de credenciales. |
