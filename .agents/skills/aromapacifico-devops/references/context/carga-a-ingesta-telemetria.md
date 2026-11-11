# Ingesta de cultivo, secado y posición con alertas y umbrales configurables

**Historia:** [#12](https://github.com/aromapacifico-platform/planning/issues/12). **Responsable:** Juan Ocampo (`juandavid175`). **Fecha:** 7 de noviembre de 2026.  
**Estado:** diseño para revisión. Los tiempos son presupuestos verificables, no mediciones ni SLA de los proveedores. No se desplegaron servicios, aplicaciones o firmware desde esta HU.

## 1. Dependencias y estado real del proyecto

Se revisaron por GitHub MCP los issues, ramas, archivos y PR, incluidos sus commits. No hay una dependencia oficial sin trabajo disponible que impida preparar este diseño.

| Dependencia oficial | Trabajo disponible al revisar | Decisión para #12 |
|---|---|---|
| **#6, conectividad sin señal** | Documento y diagrama en [PR #49](https://github.com/aromapacifico-platform/planning/pull/49), abierta, commit `af64c56128198c4978d23f5f1fc8cc699b6b1ff7`; sin comentarios de revisión al consultar. | Continuar sobre esa propuesta, sin presentarla como aprobada. Si cambia durante revisión, actualizar los contratos de buffer, SBD y ACK. |
| **#7, direccionamiento y data paths** | Cerrada e integrada mediante [PR #46](https://github.com/aromapacifico-platform/planning/pull/46); documento presente en `main`. | Conservar CIDR, ambientes, DynamoDB y camino administrado de ingesta. |

Base integrada: `planning/main` en `4c6fa27a31a5ac5c38c0da5711e36936024ba2cd`, [enunciado](https://github.com/aromapacifico-platform/planning/blob/main/docs/case-study/enunciado-original.md), [decisiones senior](https://github.com/aromapacifico-platform/planning/blob/main/docs/governance-and-decisions/briefing-inicial-juniors.md) y [direccionamiento](https://github.com/aromapacifico-platform/planning/blob/main/docs/architecture/red-direccionamiento-nube.md). También se contrastaron propuestas relacionadas: identidad [PR #50](https://github.com/aromapacifico-platform/planning/pull/50), `e50838f23ec27818ff3497590811106b20e945ee`; firewall [PR #54](https://github.com/aromapacifico-platform/planning/pull/54), `4a0cc3f857fc9440c560b57b6e49ee1f0e036dba`; nodo [PR #55](https://github.com/aromapacifico-platform/planning/pull/55), `0af5496d776dc44d0bd8c437aaa79996427d5b1e`. Seguían abiertas. Son insumos de coherencia, no nuevas dependencias oficiales ni cambios ya aceptados.

`iac/main`, commit `9afc7f5b6ba3c5881f21d36865b3e9faf73e1fbc`, solo contiene README. Por eso se especifican recursos y contratos para [#24](https://github.com/aromapacifico-platform/planning/issues/24), sin afirmar que exista un módulo desplegado.

## 2. Diagrama y presupuesto de menos de cinco minutos

![Ingesta y entrega de alerta con tiempos por tramo](https://github.com/aromapacifico-platform/planning/blob/main/docs/architecture/diagrams/carga-a-ingesta-telemetria.svg)

Fuente editable: [carga-a-ingesta-telemetria.drawio](https://github.com/aromapacifico-platform/planning/blob/main/docs/architecture/diagrams/carga-a-ingesta-telemetria.drawio). El diagrama incluye el ACK de persistencia al nodo, el recibo de entrega de alerta al teléfono, satélite, posición y cambio de umbrales; son confirmaciones distintas.

El reloj inicia en `occurred_at`, al obtener la lectura completa. No inicia cuando llega a Lambda. El intervalo de muestreo de 4 h/1 h no forma parte de los cinco minutos: el objetivo es desde una **lectura efectivamente tomada** fuera de rango. La plataforma no detecta antes una condición que el nodo aún no midió.

| ID | Tramo del recorrido celular disponible | Presupuesto máximo de diseño |
|---|---|---:|
| T1 | Escritura local de la lectura | 2 s |
| T2 | Registro/conexión y subida celular | 118 s |
| T3 | IoT Core, regla y normalización | 10 s |
| T4 | Espera en la cola de lecturas actuales | 20 s |
| T5 | Validación, umbral y transacción de persistencia | 10 s |
| T6 | Activación y despacho desde trabajo durable | 20 s |
| T7 | SNS, proveedor y llegada al teléfono | 60 s |
| T8 | Acuse automático de la aplicación | 5 s |
| **Total hasta recibo automático comprobado** | | **245 s: 4 min 5 s** |

Quedan menos de 55 s de holgura antes de incumplir el límite estricto de 300 s. No se atribuyen garantías contractuales de esos tiempos a LTE-M, Lambda, SNS, FCM, APNs ni al operador. El dimensionamiento y la prueba deben verificarlos **por alerta**, no sustituirlos por el promedio diario. Las colas de recuperación no deben consumir el presupuesto reservado a lecturas actuales.

T1/T2 concretan la ventana activa de hasta 120 s propuesta en #11. T3 incluye arranque e invocación del normalizador; T5 incluye lectura de configuración y transacción. En SQS se configura ventana de batching 0 para no introducir espera deliberada, con margen medido para polling y arranque [A3]. T6 es objetivo para el camino de Streams, no un cron de 20 s. El barrido periódico de recuperación es una red de seguridad; si tarda más, el incumplimiento sigue contando.

En satélite se reemplaza T2 por SBD y la entrega HTTPS del proveedor: se propone un presupuesto combinado de hasta **133 s** en vez de 118 s, manteniendo **260 s** totales como objetivo de prueba. No se declara garantizado: vista al cielo, enlace del proveedor y ruta final del caficultor deben comprobarse. El ACK de regreso al nodo puede recogerse en otra sesión SBD y no forma parte de la recepción de la alerta por la persona.

## 3. Entradas, temas MQTT y reglas

### 3.1 Nodo celular y contexto de confianza

Cada nodo usa su certificado X.509 individual, `ClientId = ThingName`, MQTT/TLS TCP 8883 y QoS 1. La política vincula certificado, Thing y recursos concretos; el cuerpo no puede elegir otra finca. La normalización comprueba ese vínculo y deriva `farm_id` desde el registro autorizado del dispositivo.

Se conserva **Basic Ingest** de #7 con la regla `finca_telemetry_rule`. Los temas lógicos de PR #50 se mantienen como sufijos; los temas físicos de publicación llevan el prefijo reservado [A1].

| Uso | Tema físico / endpoint | Publicador y consumidor |
|---|---|---|
| Cultivo | `$aws/rules/finca_telemetry_rule/aromapacifico/fincas/{ThingName}/telemetria/cultivo` | Solo certificado del nodo autorizado → regla. |
| Secado | `$aws/rules/finca_telemetry_rule/aromapacifico/fincas/{ThingName}/telemetria/secado` | Solo certificado del nodo autorizado → regla. |
| ACK de persistencia y control propio | `aromapacifico/fincas/{ThingName}/config` | Solo rol de despacho → nodo propio; distinguir `message_type=ingest_ack` del control técnico. |
| Posición | `POST /telemetria/posicion`, HTTPS 443 | App del transportador con Cognito → API; no se convierte al conductor en certificado de finca. |
| Satélite | `POST /telemetria/satelite`, HTTPS 443 | Entrega de proveedor autenticada y sobre individual validado → colas comunes. |
| Recibo de alerta | `POST /telemetria/alertas/{alert_id}/recepciones`, HTTPS 443 | App del caficultor autenticada → registro de recepción propio. |

Basic Ingest no sirve para suscribirse a su tema reservado. Por eso el ACK vuelve por el broker ordinario en `/config`. Su tráfico y costo no desaparecen por usar Basic Ingest en subida. PUBACK confirma llegada al motor de reglas, **no** ejecución completa de la acción ni persistencia de negocio [A1].

El nodo se suscribe a su `/config` antes de publicar y usa sesión persistente con recepción QoS 1 para poder recoger ACK al reconectar. El ACK no se publica como mensaje retenido que reemplace una configuración técnica del mismo tema. Si se pierde la sesión o no llega el ACK, el nodo reenvía el mismo evento y obtiene la confirmación de su commit original. Una aceptación del envío de bajada tampoco prueba que el nodo ya la haya leído.

Especificación SQL de la regla, versión `2016-03-23`, para payload JSON compacto:

```sql
SELECT event_id, schema_version, sequence, occurred_at,
       calibration_version, measurements, quality,
       topic(3) AS source_device_id,
       topic(5) AS source_kind,
       clientid() AS mqtt_client_id,
       principal() AS mqtt_principal,
       timestamp() AS edge_received_at_ms
FROM 'aromapacifico/fincas/+/telemetria/+'
WHERE topic(5) = 'cultivo' OR topic(5) = 'secado'
```

El prefijo Basic Ingest no se cuenta al evaluar `topic(n)` [A1–A2]. Se seleccionan campos explícitos: no se toma `source_device_id`, `mqtt_principal` o `farm_id` del cuerpo. La política publica únicamente los dos temas físicos concretos del nodo; el `+` del filtro de la regla no autoriza a un dispositivo a publicar como otro.

La regla invoca el normalizador mediante permiso de Lambda limitado por `SourceArn` y `SourceAccount`. Errores de acción se envían a una cola técnica cifrada; fallos posteriores de la invocación asíncrona también tienen destino de fallo y alarmas. Normalizador y adaptadores no evalúan umbrales agronómicos.

Se propone JSON compacto para MQTT, compatible con la selección SQL; el sobre satelital puede ser binario/CBOR. El tamaño de 180 bytes del borrador de red no se trata como tamaño comprobado de ambos formatos. Presupuesto de almacenamiento: 1 KiB por ítem de lectura normalizada, sujeto a medir con el contrato final.

### 3.2 Sobre normalizado y colas

| Campo | Regla de uso |
|---|---|
| `event_id`, `schema_version`, `sequence` | Identificadores persistentes; no se recrean al reintentar. La secuencia es por dispositivo y sobrevive a reinicio. |
| `device_id`, `farm_id`, `kind` | Identidad de transporte y registro autorizado, no finca elegida libremente en payload. `kind` es cultivo o secado. |
| `occurred_at` | Hora UTC original y calidad de reloj. No se sustituye por hora de recepción para simular puntualidad. |
| `edge_received_at`, `received_at`, `evaluated_at` | Llegada a entrada cloud, persistencia y evaluación; permiten separar retraso del borde y del backend. |
| `measurements`, `units`, `quality`, `calibration_version` | Valores y calidad por variable; no confundir %RH de aire, humedad de suelo y humedad del grano en base húmeda. |
| `transport`, `source_binding` | Celular o SBD y evidencia de identidad validada; solo adaptadores autorizados generan este contexto. |
| `payload_hash` | Huella del contenido canónico, excluyendo contadores de reintento y tiempos de recepción. Mismo ID con otro contenido es conflicto, no actualización. |
| `config_version`, `evaluation_status` | Se añaden en el consumidor después de seleccionar el umbral; el nodo no los impone. |

El normalizador valida esquema, tipos, tamaño y reloj; verifica identidad activa y envía a SQS Standard `telemetry-live` o `telemetry-replay`. Se clasifica como recuperación cuando la lectura ya tenía más de 120 s al entrar a cloud; es un supuesto operativo visible. Un retraso posterior dentro de AWS no rejuvenece ni reclasifica el evento como puntual. Los dos orígenes alimentan el mismo consumidor y almacén, con capacidad de ejecución reservada al camino actual.

Ejemplo ilustrativo de cuerpo de cultivo, antes de agregar contexto confiable del transporte (valores sintéticos, no resultados de sensores ni límites NPK):

```json
{
  "schema_version": 1,
  "event_id": "cultivo-000151",
  "sequence": 151,
  "occurred_at": "2026-11-07T14:00:00Z",
  "calibration_version": "cultivo-v1",
  "measurements": {
    "soil_n_mg_kg": 50,
    "soil_p_mg_kg": 20,
    "soil_k_mg_kg": 80,
    "soil_moisture_pct": 55,
    "soil_temperature_c": 21.5,
    "soil_ph": 5.2,
    "air_rh_pct": 65,
    "air_temperature_c": 31.2
  },
  "quality": {"status": "valid", "clock": "trusted"}
}
```

Con el rango de aire habilitado de 14–30 °C, la temperatura 31,2 °C genera alerta. No se deduce estado NPK normal de esos números sin umbrales publicados. La versión de esquema define unidades y base de humedad; una calidad específica inválida se registra por campo. Secado utiliza `grain_temperature_c` y `grain_moisture_wb_pct`, no los campos de humedad ambiental.

SQS Standard admite duplicados y desorden; no se usa su entrega como garantía de unicidad. Las colas de aplicación, errores y DLQ se cifran, restringen por rol, tienen retención propuesta de 14 días y alarma de edad. Ese plazo cloud no amplía las 24 h del buffer del nodo. Lambda: timeout inicial 30 s, visibilidad SQS 180 s, `maxReceiveCount=5`, respuestas parciales de lote y tamaño inicial de lote 10; ajustar por pruebas. Reintentar recupera datos, pero no borra una infracción de cinco minutos.

Mensajes con identidad revocada se rechazan antes de persistencia de negocio. Datos válidos de protocolo con sensor de calidad inválida se conservan con ese estado, sin inventar un valor ni una alerta agronómica. Un esquema ilegible se aísla y no recibe ACK positivo. La cola de error no es el archivo histórico de cinco años.

### 3.3 Finca sin cobertura: camino SBD completo

El adaptador verifica autenticación de entrega del proveedor, integridad/confidencialidad del sobre del dispositivo y contador contra repetición. Se propone AES-128-GCM por dispositivo y versión de clave, coherente con el contrato AEAD de #6; el IMEI no sustituye una credencial. El canal del proveedor no se presume firmado sin contrato que lo demuestre.

Se propone como contrato de transporte un encabezado de 13 bytes (versión 1, identificador de clave 4, contador 8), nonce de 12 bytes, etiqueta de autenticación de 16 y hasta 159 bytes de contenido cifrado: **máximo 200 bytes MO**. El contenido lleva lectura/hora/calibración y se normaliza al mismo esquema. Deben probarse codificación, unicidad del nonce y provisión del material individual fuera del repositorio/estado. El encabezado se autentica como datos asociados. Se asigna contador persistente a cada mensaje nuevo, no a cada intento: al retransmitir se conserva exactamente el sobre cifrado. Se usan claves direccionales distintas y nonces únicos por clave; perder el contador exige renovar identidad de clave antes de emitir contenido nuevo.

Un contador/sobre ya visto e idéntico se trata como reenvío idempotente: comprobar persistencia y repetir su ACK, sin generar otra alerta. El mismo contador con contenido distinto se rechaza. Se conserva un registro de eventos dentro de la ventana y no se rechaza una lectura legítima desordenada solo porque llegó otra con contador mayor. No se usa una marca máxima que haga imposible recuperar un ACK perdido.

El ACK MT ocupa hasta **50 bytes**: encabezado 13 + nonce 12 + etiqueta 16 + 9 de contenido (secuencia de la lectura 8 y estado 1). El contador de bajada es distinto del de subida; el ACK no admite repetición ni cambio de identidad. Si se añade firma adicional o el formato final no cabe, se recalcula tamaño, tarifa y energía de #6/#11. Esta definición no afirma que el firmware ya la implemente.

El adaptador normaliza y encola en las mismas colas; HTTP 202 al proveedor solo confirma recepción de esa etapa. El ACK al nodo se genera tras la transacción de persistencia y se pone en el servicio de mensajes MT. La desactivación del certificado IoT debe acompañarse del estado inactivo en el registro del adaptador; no se presupone que cortar MQTT bloquee por sí solo SBD.

## 4. Persistencia, ACK e idempotencia

### 4.1 Almacén seleccionado

Se conserva **DynamoDB On-Demand**, región principal `us-east-1`, con cifrado KMS. El volumen calculado, las consultas por finca/viaje/tiempo, escrituras condicionales y transacciones favorecen esta elección. Una base especializada en series temporales podría ayudar a analítica más compleja, pero no es necesaria para el patrón actual y agregaría un segundo almacén operativo. Los reportes extensos utilizan archivos y agregados, sin escanear la tabla transaccional desde el teléfono.

| Tabla lógica | Clave / consulta principal | Retención y acceso |
|---|---|---|
| `telemetry` | PK `DEVICE#{device_id}`, SK `EVENT#{event_id}`; índice de historial por `FARM#{id}#KIND#{kind}#DAY#{fecha}` y hora/ID. | Lectura normalizada, evaluación y versión aplicada; últimos 90 días online, con condición de archivado. Caficultor solo sus fincas. |
| `positions` | Identidad/dispositivo + evento estable; índice por viaje y día con hora/ID. | Coordenadas/precisión separadas de telemetría agronómica; acceso de transporte/acopio autorizado. No consulta pública. |
| `thresholds` | Versiones inmutables, puntero activo por ambiente y auditoría por solicitud. | Conservar versiones y auditoría durante los cinco años del expediente. |
| `ingest_control` | Clave estable de evento y tareas/estado; índices de pendientes por tipo, partición y siguiente intento. | Huella/idempotencia y recibo durable; ACK, alerta y archivo con estados independientes. Mantener evidencia mínima de deduplicación durante cinco años. |

Los índices son de consistencia eventual: la API no interpreta una demora del índice como borrado de una lectura recién confirmada. La comprobación por ID tras ACK usa lectura consistente de la clave base. La identidad del usuario limita la finca/viaje en servidor; pasar un `farm_id` en URL no concede acceso.

### 4.2 Unidad de persistencia

El consumidor lee el puntero de configuración consistentemente, obtiene su versión inmutable y evalúa las variables válidas. Para el piloto se define una versión global por ambiente; no se inventan overrides por finca o departamento. Se fija esta semántica: **aplicar la versión activa al persistir/evaluar**, también para recuperaciones, dejando hora original, retraso y versión utilizados. Cambiar umbrales no reevalúa silenciosamente el historial. Una evaluación retrospectiva sería un trabajo separado y marcado como tal.

Una transacción DynamoDB crea la lectura y su ítem de control/trabajo durable, ambos condicionados a inexistencia, y comprueba que el puntero y el estado autorizado de identidad no cambiaron. Si cambian, vuelve a leer y evaluar antes de intentar el commit. La tarea incluye lo necesario para ACK/alerta sin depender del orden de llegada de dos registros de Streams. Las transacciones tienen costo adicional; no se cuentan como una sola escritura [A4].

**El commit es el punto de ACK de aplicación.** El trabajo de ACK y el de alerta quedan pendientes de forma durable incluso si Lambda muere antes de comunicarlos. DynamoDB Streams activa un despachador que actualiza cada tarea mediante condición/lease para impedir dos trabajadores simultáneos. Un barrido por índice recupera tareas vencidas o perdidas por expiración del stream; no se usa solo el stream como cola permanente. Streams retiene 24 h y los registros de una transacción pueden aparecer intercalados [A4–A5].

| Situación | Comportamiento |
|---|---|
| Mismo ID, mismo hash | Devolver/republicar ACK de la persistencia original. No insertar otra lectura ni crear otra alerta. |
| Mismo ID, distinto hash | Conflicto de integridad; aislar y alertar a operación, sin sobrescribir. |
| Commit fallido | No enviar ACK positivo; reintentar desde cola/nodo. |
| Persistencia hecha, ACK perdido | El reenvío obtiene el ACK original; deduplicación independiente de QoS 1. |
| Entrega SNS hecha, estado no actualizado por un fallo | Puede repetirse el envío. Usar `alert_id` estable y deduplicación en app; no prometer exactamente una vez para SMS. |
| Dato tardío o desordenado | Guardar con `occurred_at` original; la vista actual no reemplaza una lectura más nueva por otra antigua. |

El ACK MQTT propio contiene `message_type=ingest_ack`, ID/secuencia confirmada y hora de persistencia. Solo el rol de despacho puede publicarlo. Puede confirmarse más de un ID de forma explícita, pero no una secuencia mayor que oculte huecos no persistidos. ACK de lectura no significa alerta entregada, vista por el agricultor ni fumigación autorizada.

## 5. Umbrales en plataforma y cambio auditado

| Variable | Configuración inicial según caso | Evaluación |
|---|---|---|
| pH de suelo | Permitido 4,5–6,0; recomendado 4,9–5,6. | Alerta si `<4,5` o `>6,0`. Recomendado no es un segundo límite crítico automático. |
| Temperatura de aire y suelo | Inicial 14–30 °C, recomendado 17–23 °C, como propuesta de correspondencia del rango de cultivo. | Comparar cada campo por separado; Federación confirma esa correspondencia antes de habilitar la política. |
| Humedad relativa del aire | Inicial 40–80 %RH como propuesta de correspondencia de la tabla. | Comparar con la misma unidad; no convertir %RH a humedad del grano. |
| Humedad de suelo | El caso da 40–80 % sin precisar base/metrología. | Conservar ambos límites como referencia pendiente; no activar esta alarma hasta que Federación confirme base y curva del instrumento. Mostrar la falta de configuración. |
| N/P/K | Límites que publique Federación por variable y unidad. | Inicialmente pendientes, sin números inventados. La ausencia de rango genera incidencia de configuración, no estado «normal». |
| Temperatura del grano | Por encima de 40 °C. | Alerta `>40 °C`, solo con calidad válida. |
| Humedad del grano | Cercanía al 12 % en base húmeda para cierre de lote. | Aviso de objetivo según tolerancia aprobada y calibración de #11; no alarma por el mero hecho de estar por encima de 12 % mientras seca ni cierre automático. |

La configuración incluye `version`, unidades/bases, límites, habilitación por variable, severidad y tolerancia de medición cuando corresponda. Las políticas pendientes de dato agronómico no se presentan como habilitadas; se informan como brecha que debe resolverse antes de aceptar la operación del piloto. La HU diseña el mecanismo para cambiar esos valores sin tocar el nodo.

Procedimiento propuesto:

1. Un operador autorizado por Federación se autentica con IAM Identity Center y MFA; solo puede invocar la operación administrativa `UpdateThresholds`, sin permisos directos de escritura a las tablas desde el cliente.
2. La función valida tipos, unidades, `mínimo <= máximo`, variables permitidas, motivo y versión esperada. Captura identidad de sesión en servidor, no confía en un campo `approved_by` enviado libremente.
3. Una transacción agrega versión inmutable, auditoría (actor, solicitud, fecha UTC, motivo, antes/después o huellas) y cambia el puntero activo mediante control de concurrencia. Una solicitud repetida con el mismo ID no crea dos cambios.
4. Los siguientes commits de ingesta leen esa versión y la guardan con su resultado. Si hay una lectura en vuelo durante el cambio, la condición de transacción fuerza consistencia; no se requiere publicar el umbral a los dispositivos.
5. Revertir significa crear otra versión con los valores anteriores y nuevo motivo. No borrar/editar la versión usada por lecturas históricas.

Se habilitan eventos de datos de CloudTrail para las operaciones relevantes de estas tablas y se exporta auditoría a S3 protegido. No se supone que el historial de eventos administrativos por defecto capture todas las escrituras DynamoDB [A9]. Las versiones de umbrales y registros de auditoría se conservan al menos cinco años y se incluyen en el archivo. Los logs no llevan secretos ni números de teléfono completos.

## 6. Detección y entrega al caficultor

### 6.1 Detección

Una lectura válida con una o varias variables fuera de límites habilitados genera una **alerta por lectura**, con lista de variables, `alert_id`, finca, hora original, versión de umbral, severidad y marca de retraso. La tarea se guarda en la misma unidad transaccional. Los reintentos no generan otra alerta; las lecturas distintas no se ocultan por deduplicación. Una ventana de supresión o agrupación futura requeriría decisión visible para no demorar la primera alerta.

La humedad de grano inválida/sin calibración no se convierte en porcentaje confiable. Se crea incidencia técnica y se mantiene la brecha de cobertura de #11 visible. El síntoma visual/plaga entra por el servicio de confirmación del dron, no por esta ingesta; ninguna alerta ejecuta fumigación.

### 6.2 Canal final seleccionado

Se conserva **Amazon SNS**. Se propone un topic privado de aplicación por finca, `aromapacifico-{env}-farm-{farm_id}-alerts`, al que solo publica el rol de despacho; sus suscripciones autorizadas son el número verificado y, cuando exista, el endpoint de app SNS/FCM o APNs. Una alerta se publica en el topic de su finca y se guarda el `MessageId`; SNS distribuye SMS transaccional y push según los destinos registrados. Las suscripciones/contactos se gestionan con autorización y auditoría, no desde el nodo. Es redundancia de aviso, no un segundo motor de umbrales. El historial queda persistido aunque los dos canales fallen. No se usa email como único aviso urgente ni se presupone que el teléfono del productor esté siempre en línea.

SMS permite el escenario con cobertura de mensajería y sin datos disponibles en la app. La aceptación de campo debe probar SMS con el teléfono y operador en LTE/VoLTE, sin dependencia de 2G/3G. Antes de operar se verifica salida del sandbox SNS, país/destino habilitados, identidad de origen exigida por el proveedor, límites de gasto, números autorizados y preferencias del destinatario [A6–A8]. El servicio de SMS y los endpoints push no están configurados desde esta entrega.

El contenido es mínimo: alias de finca, variable, severidad, hora y código de alerta. No incluye cédula, ruta GPS ni historial personal. Contactos/tokens provienen del perfil autorizado, no de un número incluido por el nodo. Las credenciales APNs/FCM quedan fuera del repositorio y del estado; su provisión pertenece a la aplicación/operación.

### 6.3 Qué demuestra recepción

| Estado | Evidencia | ¿Cuenta como recepción comprobada? |
|---|---|---|
| `DETECTADA` / `PENDIENTE` | Registro transaccional de alerta/trabajo. | No. |
| `DESPACHADA` | SNS devuelve `MessageId` y se guarda intento/canal. | No. |
| `ACEPTADA_PROVEEDOR` | SNS o plataforma push acepta el mensaje. | No demuestra llegada al dispositivo. |
| `RECIBIDA_DISPOSITIVO` | La app persiste la alerta y envía recibo autenticado por `alert_id`, usuario y dispositivo; la API guarda su hora de llegada. | Sí, como recepción por app, no lectura humana. Un DLR SMS solo se usa si su semántica acredita entrega final y trae tiempos utilizables. |
| `VISTA` | El caficultor abre la alerta y la app lo registra. | Evidencia humana separada; no se exige reaccionar en cinco minutos. |
| `FALLIDA` / `SIN_CONFIRMACION` | Error definitivo o vencimiento sin recibo verificable. | No se declara éxito. |

La API valida Cognito, vínculo del usuario con la finca y correspondencia del `alert_id`; el recibo es idempotente y solo actualiza entrega. No autoriza escrituras de sacos ni cambiar umbrales. La hora de llegada del recibo al servidor es un límite conservador de recepción; el reloj del móvil no puede fabricar cumplimiento. Permisos de notificación y ejecución en segundo plano se prueban por plataforma; un push aceptado sin ejecución del cliente no produce un recibo ficticio.

SNS puede tardar hasta 72 h en publicar ciertos logs SMS según operador [A6]. No se espera ese log en el camino crítico ni se lo confunde con cinco minutos. Un estado técnico de éxito sin evidencia final suficiente queda sin confirmar. Ensayos con teléfonos instrumentados validan T7; en operación se registra el grado real de evidencia y se informa lo desconocido como tal.

### 6.4 Sin señal, recuperación y deadline

Si el nodo no tiene ruta, mantiene la lectura según #6 hasta 24 h. Si SBD funciona, la falta de señal celular no implica falta de ruta de subida. Si el teléfono del caficultor no tiene ruta de recepción, la alerta queda pendiente; no se sustituye por una entrega al acopio y se la llama entrega al caficultor.

Al recuperar ruta se envían pendientes sin esperar el siguiente muestreo. Se usa `deadline_at = occurred_at + 24 h` para vigilar recuperación y alertas atrasadas, conservando hora original. Drenar al último segundo no garantiza entrega antes del deadline: se priorizan los próximos a vencer y se avisa anticipadamente a 12 h/20 h como #6. Si no se entrega en 24 h, se registra incumplimiento y se escala por los canales disponibles. No hay una garantía posible de recepción en un teléfono inaccesible indefinidamente.

Reintentos de trabajo/notificación propuestos: inmediato, +15 s, +30 s y luego espaciados hasta el deadline, con contador y límites de gasto/operación visibles. Un fallo antes de cinco minutos puede recuperarse, pero si la recepción comprobada supera 300 s, esa alerta sigue siendo tardía. Pasadas 24 h se conserva historia/incidente; cualquier aviso posterior se identifica como atrasado, sin presentarlo como riesgo actual recién detectado.

## 7. Posición del transportador e historial

La app crea `posicion_registrada` cada cinco minutos en viaje y la guarda cifrada offline: 120 posiciones por jornada de 10 h. Envía lotes de hasta 20 puntos por HTTPS con token Cognito y mismo ID original. La API valida actor, viaje asignado en la fecha del evento, límites de coordenadas, precisión y hora; geolocalización no disponible se expresa como nula con motivo, nunca coordenadas cero inventadas.

El adaptador de posición reutiliza el contrato de validación/persistencia idempotente y almacena en `positions`. Puede responder por cada punto `persisted`, `duplicate` o error; responde éxito de persistencia **solo tras commit**, sin usar HTTP 202 como ACK final. Un timeout lleva a reenviar los mismos IDs; no se exige atomicidad de todo el lote. Control de tasa y respuestas parciales evitan monopolizar la ingesta.

La recuperación de ubicación no dispara alertas agronómicas ni estados de sacos por sí sola. Custodia y entregas son eventos de #15, con su RPO propio. El máximo de 24 h del buffer del nodo no se impone al teléfono: conserva pendientes hasta confirmación, como #6. La API no rechaza una posición histórica solo por haber cambiado la asignación actual si existe el vínculo autorizado con su viaje original.

Historial del caficultor: consulta paginada por finca, tipo y rango de fechas, con calidad, hora original/recepción, umbral aplicado y alertas. El reporte del piloto agrega por día/departamento: volumen esperado/recibido, retrasos, faltantes, rangos y entrega de alertas; no entrega recorridos individuales al comprador. Consultas antiguas restauran archivo cuando corresponda; no se promete respuesta instantánea de Deep Archive. Se mantienen resúmenes e índices mínimos de largo plazo para localizar ese historial.

## 8. Carga, capacidad y retención

### 8.1 Volumen del caso

Mes de referencia: **30 días**, secado activo en 100 fincas y 60 transportadores operando 10 h cada día modelado. Es un mes de dimensionamiento, no una afirmación de días laborales reales; si trabajan menos días se sustituye ese factor.

| Flujo | Cálculo diario | Registros/día | Registros/mes de 30 días |
|---|---|---:|---:|
| Cultivo | 200 × 6 | 1.200 | 36.000 |
| Secado activo | 100 × 24 | 2.400 | 72.000 |
| Posición | 60 × 12 × 10 | 7.200 | 216.000 |
| **Total en cosecha** | | **10.800** | **324.000** |
| **Sin secado activo, mismo transporte** | 1.200 + 7.200 | **8.400** | **252.000** |

Promedio de cosecha: `10.800/86.400 = 0,125 registros/s`; telemetría agronómica sola `3.600/86.400 ≈ 0,0417/s`. En las 10 h de viaje, posición promedia `7.200/36.000 = 0,2/s`. Los promedios no son el pico: al coincidir horarios pueden llegar hasta 200 muestras de cultivo, 100 de secado y 60 posiciones, **360 eventos**, antes de reintentos.

Backlog de un día del caso: 3.600 lecturas agronómicas y 7.200 posiciones. A un objetivo de drenaje de 50 lecturas/s, las agronómicas requieren 72 s de capacidad de servicio; no equivale a 72 s garantizados de extremo a extremo. Ubicación tiene su entrada/rate limit aparte. Colas `live/replay` y límites por origen reservan capacidad a datos actuales y evitan que un reenvío masivo o un teléfono con backlog los retrase. Objetivos iniciales para ensayo: 50 registros/s sostenidos de recuperación y ráfaga de 360 eventos, sin throttling sostenido y respetando el presupuesto de lecturas actuales.

Escala a 1.000 fincas con 50 % de secado simultáneo y los mismos 60 transportadores: cultivo 6.000/día, secado 12.000/día, posición 7.200/día; **25.200/día y 756.000/mes**. Si los transportadores también crecen cinco veces: **54.000/día y 1.620.000/mes**. Son dos escenarios, no la misma cifra. Se agregan identidades, claves/particiones y capacidad; no nuevos CIDR por finca. DynamoDB On-Demand no elimina límites de cuenta, partición, índices o velocidad de crecimiento; se verifican cuotas y carga [A10].

### 8.2 Registros no equivalen a mensajes o unidades facturadas

Con presupuesto de **1 KiB por lectura normalizada**, cosecha representa 331.776.000 bytes/mes, aproximadamente **316,41 MiB / 0,309 GiB** de contenido lógico. No incluye índices, atributos adicionales, control, auditoría, réplicas ni compresión. 90 días serían 972.000 registros, aproximadamente **0,927 GiB** de contenido. Cinco años aproximados de 365 días serían 19.710.000 registros, **18,797 GiB**; la retención real se calcula por fechas de calendario.

Dos escrituras transaccionales de ítems de hasta 1 KiB consumen como mínimo 4 unidades de escritura por evento, antes de índices, lecturas condicionales y actualizaciones de estado. Para 324.000 eventos serían **1.296.000 unidades base** bajo esa hipótesis [A4]; un ítem mayor cambia el redondeo. Añadir normalización, colas, ACK, archivo y recibos, no presupuestar una llamada por evento para toda la plataforma.

Máximo de diseño de alertas agronómicas: una por cada una de las 3.600 lecturas/día, no por las 7.200 posiciones ni necesariamente por cada variable. Si `p` es la fracción que genera alerta, son `108.000 × p` alertas/mes. SMS y push son intentos distintos; reintentos y segmentación del SMS se costean aparte. No se inventa una tasa de fuera de rango o costo mensual fijo sin datos del piloto.

El satélite representa una parte de las lecturas, no carga adicional a las mismas 3.600 del caso. #6 dimensiona 200 bytes MO y 50 MT por lectura; el MQTT JSON y el ítem DynamoDB no tienen por qué medir lo mismo. El costo satelital y su sobreconsumo por reenvíos siguen separados en #28/#29.

### 8.3 Archivo de cinco años sin hueco por TTL

Se conserva la propuesta de **90 días de consulta online + archivo S3 de cinco años** de #7, con estas condiciones:

1. Un trabajo diario consulta las particiones conocidas del día/finca/tipo y viajes, genera Parquet por departamento/día/tipo con manifiesto, conteo, IDs y checksum; separa coordenadas de reportes de cultivo y aplica permisos distintos.
2. Verifica escritura, lectura de comprobación, integridad y retención de las versiones S3; incluye versiones de umbral/auditoría necesarias para reconstruir la evaluación. Object Lock requiere versionado y configuración explícita de retención [A11]. No se presume habilitado por crear un bucket.
3. **Solo tras archivo verificado** se marca `archived_at` y se habilita TTL de copia online para `occurred_at + 90 días`. Si no está archivada, no tiene TTL de borrado; el fallo genera alarma y costo adicional visible. No se utiliza la eliminación TTL como único disparador de archivo.
4. S3 aplica transición a almacenamiento frío a objetos compactados que cumplan tamaños/condiciones, conservando cinco años y metadatos de localización. No se manda cada lectura de unos bytes como objeto Deep Archive independiente. Los detalles/costos de ciclo de vida se consolidan en seguridad/costos.

DynamoDB TTL no borra exactamente al vencer: puede demorar días [A5]. No sirve para el límite físico/lógico de 24 h del dispositivo, ni prueba por sí solo cinco años de conservación. Outbox pendiente y evidencia de idempotencia no desaparecen con el TTL de la lectura. Se prueban relectura/conciliación y restauración antes de declarar cumplida la retención.

## 9. Red, seguridad y alcance de IaC

Los endpoints IoT Core, API Gateway y SNS son servicios administrados; no se colocan artificialmente dentro de una subred. Las ENI del consumidor, si se configura en VPC, usan las subredes de ingesta de #7: prod `10.70.1.0/24` y `10.70.101.0/24`; dev/test conservan el mismo patrón con 50/60. DynamoDB se alcanza por Gateway Endpoint desde VPC; no tiene SG propio ni vive físicamente en `10.70.20.0/24`.

El consumidor con VPC solo necesita sus salidas autorizadas hacia DynamoDB y las que realmente use de logs/KMS; no requiere ingreso TCP 8883 «desde IoT». El poller administrado de la integración SQS invoca la función; no es un cliente de red que obligue a abrir un puerto entrante a su ENI. Normalizadores y despachadores sin requisito de recurso privado se proponen fuera de VPC: llaman APIs administradas por TLS e IAM, sin crear NAT ni afirmar que un SG de la VPC filtra esas llamadas. Si se decide meterlos en VPC, se deben añadir endpoints/egress concretos para IoT Data, SNS, SQS y registro, con costo y políticas; no habilitar salida universal como sustituto.

Cambios que deben armonizarse durante la revisión:

| Documento/propuesta | Ajuste necesario |
|---|---|
| PR #50 identidad | Autorizar los **temas físicos Basic Ingest** por nodo; la política actual de sufijos sin prefijo no basta. Mantener recepción propia en `/config`. El rol de despachador sí puede publicar ACK; el dispositivo no puede fabricarlos. |
| PR #54 firewall | Mantener M01 MQTT, M02 posición y M04 satélite. Añadir política explícita de **ingreso de recibos de telemetría de alerta**, HTTPS y Cognito, desde redes móviles variables; justificar el origen público como ingreso de telemetría de entrega. No ampliar M03 de eventos de sacos ni abrir administración. El endpoint nuevo no queda autorizado por mencionarlo aquí. |
| PR #55 nodo | Confirmar prefijo/topic, JSON MQTT, interpretación de ACK y serialización SBD dentro de 200/50 bytes; medir radio, reloj y calidad del sensor. |
| #7 / consolidación #19 | Concretar Basic Ingest y archivo condicionado; sustituir la idea de 8883 a Lambda por invocaciones de servicios; reflejar colas y trabajo durable del diseño. |

El historial autenticado del caficultor también requiere que su API tenga una política de exposición coherente con #9; no se reutiliza la consulta anónima del comprador para devolver datos privados. Mientras M03/criterio de origen y el acceso de aplicaciones sigan por concretar, ese acceso no se declara desplegado ni se añade una excepción de red encubierta.

La HU #24 ya solicita `modules/ingest` (políticas IoT, reglas, tablas de telemetría/umbrales) y `modules/farm` (una identidad patrón). Este diseño añade normalización, colas, consumidores, trabajo durable, ACK y despacho como cajas de la arquitectura. **Antes de codificar el camino completo** deben reflejarse sus recursos, artefactos y horas en #21/#24; no se incorporan funciones de negocio ilimitadas por omisión ni se llama «alerta implementada» a una regla que solo almacena lecturas. Las aplicaciones, firmware y demás funciones de negocio siguen fuera del alcance que el enunciado excluye.

| Parte | Contrato que se entrega a IaC / equipo propietario |
|---|---|
| `modules/ingest` | Nombres de regla, temas y colas; claves/índices, cifrado, Streams, parámetros de retención y tabla de umbrales; bindings de invocación/roles que se incluyan expresamente en el plan. Topic SNS por finca solo si se incluye en el alcance acordado, nunca suscriptores reales cargados por defecto. |
| `modules/farm` | Una instancia con ID, atributos, política y referencia de certificado público; clave privada generada/provisionada fuera de Terraform. La variable de baja debe cortar también el registro del adaptador si ese camino se instancia. |
| Seguridad/red | KMS/IAM, APIs y políticas permanentes aprobadas; sin regla SG ficticia para IoT Core/SNS. |
| Aplicaciones/firmware y operación | Artefactos de normalización/evaluación/ACK, UI y recibos, APNs/FCM/SMS, calibración y alta de contactos. Diseñados aquí, no implementados por este Markdown. |
| #18 observabilidad | Identificadores, timestamps, contadores de expiración y evidencia de entrega para sus SLI/SLO. |

## 10. Comprobación documental y pruebas de aceptación

| Criterio de #12 | Evidencia de esta entrega |
|---|---|
| Lectura → alerta con tiempo por tramo | SVG y Draw.io; tabla T1–T8, 245 s celular y objetivo 260 s satelital; diferencia entre despacho y recepción. |
| Cambio de umbral sin tocar nodo y auditado | Tabla versionada, operación autorizada, transacción con auditoría/puntero, versión persistida por lectura y reversión mediante nueva versión. |
| Carga diaria/mensual y elección de almacén | 10.800/día y 324.000/mes en cosecha; escenarios, recuperación, proyección de almacenamiento y justificación de DynamoDB. |

Validaciones de escritorio de esta entrega: sumas/factores de carga y tiempos; temas/SQL y variables del caso; referencias y enlaces internos; consistencia del diagrama con el documento; XML/SVG y empaquetado. No se ejecutó `terraform plan` ni pruebas de entrega, dado el estado de `iac` y el alcance documental.

Pruebas posteriores necesarias:

1. Una lectura válida en rango se persiste y recibe ACK sin alerta; límites exactos y valores fuera de rango siguen las comparaciones configuradas.
2. Una lectura fuera de rango recorre los ocho tramos con correlación y recibo de app; demostrar `<300 s`, incluyendo arranque y última milla. En SMS medir el teléfono o evidencia final equivalente; SNS `MessageId` no basta.
3. Cambiar umbral con operación autorizada y verificar siguiente evaluación sin tocar dispositivo, auditoría completa, conflicto concurrente y reversión.
4. Reenviar ID idéntico tras perder ACK y comprobar una sola lectura/alerta; un hash distinto se rechaza; matar consumidor/despachador en ventanas de fallo y recuperar trabajo.
5. Ensayar buffer/reinicio y entrega atrasada, caso de 24 h, identidad revocada en MQTT/SBD, nonce/contador repetido y falla de reloj.
6. Inyectar 360 eventos y recuperación del día a la tasa propuesta sin bloquear lecturas actuales; medir colas, throttling y todo consumo facturable.
7. Interrumpir archivo y probar que TTL no borra lecturas sin copia verificada; recuperar datos históricos y su versión de umbral.
8. Desconectar datos del teléfono, probar SMS en LTE y distinguir recibido/despachado/sin confirmación; negar permisos push y verificar que no se inventa un recibo.

Para #18 se propone medir `received_at - occurred_at`, `evaluated_at - occurred_at`, `dispatched_at - occurred_at` y `receipt_recorded_at - occurred_at`, por transporte y canal. Desconocidos y faltantes no cuentan como éxito ni se esconden en promedios. Separar población con ruta completa disponible, recuperación sin señal e incumplimientos de 24 h; la disponibilidad de ruta debe tener evidencia, no inferirse solo de los mensajes que sí llegaron. Añadir edad de cola, outbox pendiente, duplicados, conflictos, errores de sensor, umbrales ausentes, entrega fallida y archivo atrasado.

## 11. Referencias técnicas

Documentación primaria consultada el 7 de noviembre de 2026; las configuraciones y presupuestos particulares son propuestas de #12.

- **[A1] AWS IoT:** [Basic Ingest, prefijos y significado de PUBACK](https://docs.aws.amazon.com/iot/latest/developerguide/iot-basic-ingest.html) y [MQTT, sesiones persistentes y mensajes retenidos](https://docs.aws.amazon.com/iot/latest/developerguide/mqtt.html).
- **[A2] AWS IoT:** [funciones SQL](https://docs.aws.amazon.com/iot/latest/developerguide/iot-sql-functions.html) y [acción Lambda](https://docs.aws.amazon.com/iot/latest/developerguide/lambda-rule-action.html).
- **[A3] AWS Lambda:** [integración SQS](https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html), [parámetros](https://docs.aws.amazon.com/lambda/latest/dg/services-sqs-parameters.html) y [respuesta parcial/errores](https://docs.aws.amazon.com/lambda/latest/dg/services-sqs-errorhandling.html).
- **[A4] DynamoDB:** [transacciones y propagación a streams](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/transaction-apis.html).
- **[A5] DynamoDB:** [Streams y duración de 24 h](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Streams.html) y [TTL](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/TTL.html).
- **[A6] SNS:** [logs y seguimiento de entrega SMS](https://docs.aws.amazon.com/sns/latest/dg/sms_stats_cloudwatch.html).
- **[A7] SNS:** [notificaciones móviles](https://docs.aws.amazon.com/sns/latest/dg/sns-mobile-application-as-subscriber.html).
- **[A8] SNS:** [sandbox de SMS y habilitación](https://docs.aws.amazon.com/sns/latest/dg/sns-sms-sandbox.html).
- **[A9] DynamoDB:** [auditoría con CloudTrail](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/logging-using-cloudtrail.html).
- **[A10] DynamoDB:** [capacidad On-Demand y escalamiento](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/on-demand-capacity-mode.html).
- **[A11] S3:** [Object Lock y versiones](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html).
