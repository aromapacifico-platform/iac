# Contexto Integral del Proyecto AromaPacífico (FNC 2026)

Este documento resume el contexto arquitectónico, técnico y de gobernanza para la plataforma de trazabilidad cafetera **AromaPacífico**, diseñado para la **Federación Nacional de Cafeteros (FNC)**.

---

## 1. Visión General del Reto y Antecedentes

- **Origen:** En 2020 se diseñó un piloto que nunca se desplegó. En 2026, la FNC retoma la iniciativa modernizando la arquitectura, ajustando los supuestos de telecomunicaciones, actualizando costos e incorporando automatización e inteligencia artificial.
- **Alcance Geográfico:** 200 fincas cafeteras repartidas en tres departamentos: **Cauca**, **Huila** y **Tolima**.
- **Actores y Aplicaciones:** 
  1. *Aplicación del Caficultor:* Monitoreo de cultivo/secado y alertas tempranas (pantallas simplificadas para adopción rural).
  2. *Aplicación del Transportador:* Reporte de posición cada 5 minutos en ruta.
  3. *Portal Web de Consulta:* Consulta de trazabilidad de sacos (60 kg) mediante código QR/identificador único para caficultores, centros de acopio y compradores internacionales.

---

## 2. Diferencias Clave: Diseño 2020 vs. Arquitectura 2026

| Dimensión | Enfoque 2020 (Superado) | Arquitectura 2026 (Adoptada) |
|---|---|---|
| **Conectividad en Finca** | Asumía cobertura celular total y constante. | **Store-and-Forward:** Si no hay señal celular, el nodo retiene lecturas hasta por **24 horas** en memoria flash y drena al recuperar enlace. No se instalan radiobases costosas. |
| **Nube y Región** | Propuestas genéricas o São Paulo (`sa-east-1`). | **AWS `us-east-1` (N. Virginia)** por menor costo y latencia directa vía cables submarinos de Miami. Región de contingencia: **`us-east-2` (Ohio)** para consulta del saco (RTO 4h, RPO 15min). |
| **Segunda Nube** | No contemplada o duplicación completa. | **Microsoft Azure** como segunda nube preparada (interconexión y federación de identidad listas), sin duplicar costos ni cargas. |
| **Drones** | Vuelos aislados sin gobernanza. | **Servicio Integral de 5 Capacidades:** Delimitación de polígono, Confirmación de alerta, Fumigación autorizada (aprobación humana con MFA), Verificación post-vuelo y Estimación de cosecha. |
| **Centros de Acopio** | Aislados sin red local. | **LAN segmentada** con VLANs (Gerencia, Soporte, Logística, Transporte, Visitantes) y túnel VPN redundante hacia la VPC de AWS. |
| **Puerto de Buenaventura**| Despliegue de infraestructura propia. | **Cero infraestructura FNC:** Integración pura vía API de naviera; solo se registra el evento de entrega del saco. |
| **Inferencia / IA** | Cómputo permanente costoso. | **Serverless Orientado a Eventos:** Ingesta de imagen en S3 → Event Notification → AWS Lambda → AWS Rekognition administrado → persistencia en DynamoDB. Cero cómputo ocioso. |
| **Gobernanza de IaC** | Scripts sueltos sin control. | **Terraform >= 1.10** modular, estado S3 con bloqueo KMS nativo, pipeline CI/CD con GitHub Actions y autenticación OIDC sin llaves fijas. |

---

## 3. Plan de Direccionamiento IP y Redes

Para prevenir solapamientos, el direccionamiento está estrictamente reservado:

### 3.1. Redes On-Premise de Centros de Acopio
El segundo octeto identifica al departamento:
- **Cauca:** `10.41.0.0/16`
- **Huila:** `10.42.0.0/16`
- **Tolima:** `10.43.0.0/16`

*Subredes estándar en cada centro:*
- `10.X.1.0/24`: Gerencia
- `10.X.2.0/24`: Soporte
- `10.X.3.0/24`: Logística y recepción de sacos
- `10.X.4.0/24`: Transporte y patio
- `10.X.5.0/24`: Visitantes (aislada de gerencia y logística)
- `10.X.10.0/24`: Servidores locales e impresoras de códigos
- `10.X.20.0/24`: Borde de enlace VPN hacia la nube

### 3.2. Redes de VPC en AWS (Landing Zone)
Las VPCs de la plataforma nunca se solapan con los centros de acopio:
- **Desarrollo (`dev`):** `10.50.0.0/16`
- **Pruebas (`test`):** `10.60.0.0/16`
- **Producción (`prod`):** `10.70.0.0/16`

Cada VPC distribuye subredes en 2 Zonas de Disponibilidad (AZs):
- Subredes de Ingesta IoT
- Subredes de Ingesta de Objetos de Dron
- Subredes de Aplicación
- Subredes de Datos (DynamoDB / Bases transaccionales)
- Subredes de Administración
- Subredes de Consulta Pública

---

## 4. Gobernanza y Etiquetas Obligatorias (Tag Policy)

Todo recurso creado en Terraform debe heredar las siguientes 7 etiquetas obligatorias:

| Tag | Tipo | Descripción | Valores Permitidos / Ejemplo |
|---|---|---|---|
| `FincaID` | Costos / IoT | Identificador de la finca o `GLOBAL` para recursos compartidos | `GLOBAL`, `CAU-F001`, `HUI-F023` |
| `DronID` | Operación | Identificador del dron o `NO-APLICA` | `NO-APLICA`, `DRON-01`, `DRON-05` |
| `AcopioID` | Logística | Identificador del centro de acopio | `MULTICENTRO`, `CAUCA`, `HUILA`, `TOLIMA` |
| `ViajeID` | Trazabilidad | Identificador de ruta del transportador | `NO-APLICA`, `VIAJE-2026-001` |
| `Ambiente` | Gobernanza | Entorno en español | `desarrollo`, `pruebas`, `produccion` |
| `Propietario` | Responsable | Equipo responsable | `devops-fnc`, `seguridad-cloud`, `datos-agronomicos` |
| `Proyecto` | Transversal | Nombre fijo del proyecto | `AromaPacifico` |

---

## 5. El Timebox de 100 Horas (Épica 6 de IaC)

La Épica 6 tiene una restricción estricta e inflexible de **100 horas hombre y 2 semanas**:
- **Alcance Permitido en 100h:** Código Terraform ejecutable (módulos, variables, estado remoto, pipeline y `terraform plan` limpio de un ambiente).
- **Fuera de las 100h:** Documentación de arquitectura, cotizaciones de costos, sistema de diseño, release notes y sustentación formal.

### Desglose de Cajas de Arquitectura (E6-01 a E6-08):
- **E6-01 (6h):** Bootstrap del repo, S3 backend KMS, locking nativo, variables y pre-commit.
- **E6-02 y E6-03 (22h):** Módulo `network` (VPC, 7 subredes en 2 AZs, Gateway Endpoints S3/DynamoDB, VPN con acopio).
- **E6-04 (18h):** Módulo `security` (Llaves KMS, roles IAM sin `*`, Security Groups y NACL desde `rule_catalog`).
- **E6-08 (10h):** Pipeline CI/CD GitHub Actions con OIDC federado y control de ventana de cosecha.
- **E6-05 y E6-06 (24h):** Módulos `ingest` y `farm` (IoT Core policies, SQS con DLQ, tabla de telemetría y cosa patrón).
- **E6-07 (16h):** Módulo `function` (Bucket de foco, notificación S3, Lambda, Rekognition IAM, DLQ).
- **E6-Todas (4h):** Ejecución de `plan` limpio del ambiente completo y generación de evidencia.

---

## 6. Políticas de Despliegue y Ventana de Cosecha (Change Freeze)

- **Regla Estricta:** Durante semanas de cosecha, está terminantemente prohibido ejecutar despliegues o cambios en el ambiente de `produccion` entre las **05:00 y las 18:00 (hora local de Colombia)**.
- **Excepción:** Solo se permite aplicar cambios si el Pull Request / Commit lleva la etiqueta explícita de `incident` y cuenta con aprobación de 2 revisores autorizados.
- **Pipeline:** El workflow `iac-cd-platform.yml` valida automáticamente esta ventana mediante el script `check_harvest_window.py`.

