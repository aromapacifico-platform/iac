# Playbook de Ejecución Autónoma de Historias de Usuario (HU)

Este playbook describe el flujo de razonamiento y el protocolo de ejecución técnica que el especialista DevOps de AromaPacífico ejecuta de forma inmediata cuando el usuario proporciona una **Historia de Usuario (HU)**, requerimiento o tarea de infraestructura.

---

## 1. El Algoritmo de 7 Pasos ante una HU

Cuando se recibe un prompt con una Historia de Usuario (ej. *"HU-02: Implementar módulo de red con VPC y endpoints..."*), el agente sigue estrictamente este ciclo:

```
┌────────────────────────────────────────────────────────────────────────┐
│               FLUJO DE RAZONAMIENTO Y EJECUCIÓN DE HU                  │
├─────────┬──────────────────────────────────────────────────────────────┤
│ Paso 1  │ Clasificación de Dominio, Épica y Caja de Arquitectura       │
│ Paso 2  │ Mapeo Exclusivo de Reglas IaC Aplicables (PC-IAC-001 a 026) │
│ Paso 3  │ Definición de Interfaces (Inputs, Outputs, Tags y Naming)    │
│ Paso 4  │ Aislamiento de Dominio y Dependencias (PC-IAC-017/022)       │
│ Paso 5  │ Implementación de Código HCL (Módulo / Root / Locals)        │
│ Paso 6  │ Hardenizado de Seguridad Well-Architected (PC-IAC-020)       │
│ Paso 7  │ Validación, Checklist de DoD y Evidencia de Plan             │
└─────────┴──────────────────────────────────────────────────────────────┘
```

---

### Paso 1: Clasificación de Dominio y Caja de Arquitectura
1. **Identificar el Dominio:**
   - **Networking:** VPC, subredes, tablas de rutas, IGW, NAT, VPC Endpoints, VPN hacia acopios.
   - **Seguridad:** KMS keys, IAM Roles, IAM Policies, Security Groups, NACLs.
   - **Workload / Telemetría:** IoT Core, DynamoDB, SQS/DLQ, Finca Patrón.
   - **Workload / Inferencia:** S3 Buckets, Lambdas, integración Rekognition.
   - **CI/CD / Gobernanza:** GitHub Actions, pre-commit, control de cosecha.
2. **Vincular con la Caja del Diagrama (Épica 6):**
   - E6-01 (Bootstrap/Estado), E6-02/03 (Redes/VPN), E6-04 (Seguridad), E6-05/06 (Ingesta/Finca), E6-07 (Función de Foco), E6-08 (Pipeline).

---

### Paso 2: Mapeo de Reglas IaC Aplicables
Seleccionar las reglas pertinentes de la matriz y justificar su aplicación:
- ¿Es un **Módulo Reutilizable**? Exigir `PC-IAC-001` (10 archivos + 7 en `sample/`), `PC-IAC-023` (responsabilidad única), `PC-IAC-026` (transformación en sample).
- ¿Es integración en el **Root (`environments/<env>`)**? Exigir `PC-IAC-013` (orden de bloque module), `PC-IAC-021` (centralizar en `locals.tf`), `PC-IAC-024` (fuente en `.tfvars`), `PC-IAC-025` (construcción de nombres en root).
- ¿Declara variables? Exigir `PC-IAC-002` (`type`, `description`, `validation`).
- ¿Crea recursos AWS? Exigir `PC-IAC-003` (`${client}-${project}-${environment}-${type}-${key}`), `PC-IAC-004` (etiquetas transversales + `Name` explícito).

---

### Paso 3: Interfaces, Variables y Gobernanza
- Definir variables de entrada estrictamente tipadas con validación.
- Validar que los nombres físicos no excedan 28 caracteres.
- Asegurar que los tags contengan los 7 obligatorios (`FincaID`, `DronID`, `AcopioID`, `ViajeID`, `Ambiente`, `Propietario`, `Proyecto`).

---

### Paso 4: Aislamiento de Dominio y Dependencias
- **Regla PC-IAC-022:** Si la HU es de *Workload*, está **estrictamente prohibido** escribir bloques `resource "aws_security_group"` o `resource "aws_vpc"`. Debe consumirlos por `data` o inputs.
- **Regla PC-IAC-017:** Si la HU necesita comunicarse entre dominios, utilizar Data Sources con filtros por tags estándar o outputs explícitos.

---

### Paso 5: Implementación de Código HCL
Escribir el código en los archivos correspondientes respetando las convenciones:
- Código en inglés (variables, recursos, comentarios).
- Documentación de arquitectura y entregables en español.
- Usar `for_each` sobre mapas de objetos (`PC-IAC-010`).
- Usar bloques `dynamic` en configuraciones variables (`PC-IAC-014`).

---

### Paso 6: Hardenizado de Seguridad Well-Architected (PC-IAC-020)
- **Cifrado KMS:** Configurado con rotación anual.
- **Políticas IAM:** Sin asteriscos (`*`). Acciones y recursos específicos.
- **S3:** Bloqueo de acceso público cuádruple, SSE-KMS y forzar HTTPS vía política.
- **Networking:** Lambdas en subredes privadas asociadas a Security Groups restringidos.

---

### Paso 7: Validación y Criterio de Aceptación (DoD)
Comprobar contra la lista de verificación:
- [ ] `terraform fmt` aplicado con formato impecable.
- [ ] 0 secretos en código (`PC-IAC-016`).
- [ ] `sample/` completo y ejecutable si es módulo (`PC-IAC-026`).
- [ ] 10 archivos en raíz si es módulo (`PC-IAC-001`).
- [ ] Tags obligatorios presentes (`PC-IAC-004`).

---

## 2. Plantilla de Respuesta al Resolver una HU

Al responder al usuario tras implementar una HU, el agente presenta la solución bajo la siguiente estructura ejecutiva:

```markdown
### 1. Resumen de la HU y Alcance Técnico
- **HU:** [Código y Nombre]
- **Dominio:** [Networking | Seguridad | Workload | CI/CD]
- **Caja de Arquitectura:** [E6-xx] | **Estimación:** [X horas]
- **Ambientes:** [dev / test / prod]

### 2. Matriz de Reglas PC-IAC Aplicadas
- **PC-IAC-xxx (Nombre):** Justificación y cómo se cumple en el código.
- ...

### 3. Implementación de Archivos y Código
- [Ruta relativa del archivo modificado/creado] con el código HCL correspondiente.

### 4. Seguridad y Gobernanza Well-Architected
- Cifrado en reposo/tránsito, IAM mínimo privilegio, aislamiento de red.

### 5. Guía de Ejecución y Validación (DoD)
- Comandos exactos para probar el módulo o correr `terraform plan`.
```

