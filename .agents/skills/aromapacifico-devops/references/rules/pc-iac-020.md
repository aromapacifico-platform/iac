> Codex adaptation: read repository AGENTS.md for current interfaces, versions and authorized scope.

# 📄 Regla de Gobernanza General de Seguridad (Hardenizado de Recursos)

**ID:** PC-IAC-020  
**Tipo:** Seguridad / Cumplimiento  
**Pilares AWS Well-Architected:** Security  
**Versión:** 1.0  
**Fecha:** 10 de diciembre de 2025

---

## 1. Propósito y Alcance

Esta regla establece la obligación general de aplicar las mejores prácticas de **Gobernanza de Seguridad (Hardenizado)** del proveedor cloud (ej. AWS Well-Architected Framework) a todos los recursos de infraestructura declarados. Su objetivo es garantizar que la seguridad sea un requisito por defecto, más allá de las validaciones de sintaxis.

**Aplicable a:** Todos los bloques `resource` y configuraciones dentro de los Módulos de Referencia.

---

## 2. Principios de Seguridad por Defecto

### 2.1. Cifrado en Reposo y en Tránsito (Obligatorio)

* **Reposo:** Todo recurso que almacene datos (ej. S3, RDS, EBS, EFS) debe configurarse con **cifrado en reposo (Encryption at Rest)** activado por defecto (preferiblemente usando claves KMS gestionadas por el cliente).
* **Tránsito:** Las conexiones a servicios web (`ALB`, `CloudFront`) y bases de datos deben forzar el uso de TLS/SSL con versiones de protocolo seguras (cifrado en tránsito).

### 2.2. Principio de Mínimo Privilegio (Mandatorio)

* **Regla:** Todo recurso IAM (Roles, Policies, Users) y reglas de acceso debe adherirse al principio de **mínimo privilegio**.
* **Security Groups:** Las reglas de *Ingress* y *Egress* deben ser **específicas**. Se **prohíbe** el uso de `0.0.0.0/0` en puertos que no sean HTTP/HTTPS públicos, y está prohibido en redes privadas.

### 2.3. Control de Acceso a Metadatos

* **Regla:** Los recursos de cómputo (ej. EC2) deben configurarse para usar los mecanismos de acceso a metadatos más seguros (ej. **IMDSv2** en AWS) para mitigar vulnerabilidades de SSRF.

### 2.4. Privacidad de Red y Bloqueo de Acceso Público

* **S3 Buckets (Bloqueo Total de Acceso Público):** Todos los *buckets* S3 deben configurarse para bloquear el acceso público a nivel de *bucket* (utilizando la configuración de **Block Public Access** de AWS) para prevenir la exposición involuntaria de datos.
* **Conectividad Privada:** El acceso a servicios internos de AWS (ej. S3, DynamoDB) desde redes privadas debe realizarse a través de **VPC Endpoints** (Interface o Gateway), y **nunca** a través de *Internet Gateways* o *NAT Gateways* para estas conexiones internas.

---

## 3. Integración de Servicios de Seguridad

### 3.1. Servicios de Protección de Perímetro

* **Regla:** Los *endpoints* públicos de aplicación (ej. *ALB, API Gateway, CloudFront*) deben incluir una opción de integración con un servicio de protección de perímetro (ej. **WAF**).
* **Validación:** El módulo debe exponer una variable booleana (ej. `enable_waf`) que permita al consumidor activar el servicio de seguridad de borde de forma inmediata.

### 3.2. Gestión de Certificados

* **Regla:** Los servicios que requieran certificados TLS (ej. `CloudFront`, `ALB`) deben utilizar un servicio de gestión de certificados centralizado (ej. **ACM**), y nunca cargar certificados privados directamente en Terraform.

---

## 4. Validación en el Pipeline (Refuerzo de PC-IAC-018)

* **Refuerzo:** El cumplimiento de esta regla debe ser verificado automáticamente en el *pipeline* mediante el **Análisis de Seguridad** obligatorio (**PC-IAC-018**), utilizando herramientas que escaneen el código para detectar el incumplimiento de estas prácticas.

---

## 5. Criterios de Cumplimiento

✅ Todo recurso de almacenamiento utiliza cifrado en reposo.  
✅ Se aplica el principio de mínimo privilegio en IAM y Security Groups.  
✅ Se prohíbe `0.0.0.0/0` en puertos no públicos y redes privadas.  
✅ Los *buckets* S3 aplican la configuración de **Bloqueo Total de Acceso Público**.  
✅ El acceso a servicios de AWS desde subredes privadas se realiza vía **VPC Endpoints**.  
✅ Los *endpoints* públicos incluyen opciones de integración con WAF.

---

## 6. Relación con Pilares AWS Well-Architected

| Pilar | Cómo contribuye esta regla |
| :--- | :--- |
| **Security** | Centraliza la obligación de "Hardenizado" de recursos, asegurando que las mejores prácticas de seguridad sean el estándar por defecto para cada recurso desplegado. |
| **Operational Excellence** | La validación automatizada en el *pipeline* reduce el riesgo de desplegar infraestructura no conforme a la seguridad. |

---

¡Hemos completado veinte reglas de gobernanza! Esta última regla es extremadamente sólida y cubre las áreas de seguridad más importantes de la infraestructura cloud.

¿Desea que continuemos con la **PC-IAC-021: Aislamiento de Acceso al Estado** (la última regla de seguridad crítica, enfocada en el control de acceso al *state* file) o ha finalizado su revisión de las reglas?
