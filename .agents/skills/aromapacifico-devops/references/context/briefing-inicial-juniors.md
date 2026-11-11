# Decisiones base del proyecto AromaPacífico

Este documento presenta las decisiones base tomadas por el equipo senior para el proyecto
AromaPacífico. Es información de contexto para el equipo junior, necesaria para ejecutar las
tareas de la Fase 1 en adelante. Las primeras que se abren son la landing zone, la conectividad
sin señal y el direccionamiento de la nube, porque casi todo lo demás depende de ellas.

## 1. Idioma de los entregables

| Tipo de entregable | Idioma |
|---|---|
| Documentos académicos (arquitectura, plan de 100 horas, costos, presentación, sistema de diseño) | Español |
| Diagramas (rótulos, leyendas) | Español |
| Plantillas y ejemplos de release notes | Español |
| Código de infraestructura (IaC), nombres de recursos y variables | Inglés |
| Comentarios de código | Inglés |
| README técnico del repositorio `iac` | Inglés |
| Mensajes de commit y nombres de rama | Inglés |
| Etiquetas (labels) y milestones del tablero de GitHub | Español, sin tildes ni espacios |

El enunciado no define el idioma de entrega, así que esta convención queda registrada aquí como
decisión de gobierno del proyecto.

## 2. Nube principal

La nube principal del proyecto es **Amazon Web Services (AWS)**.

La elección se sostiene en cuatro razones concretas del caso:

Primero, el corazón del piloto es IoT con dispositivos que se desconectan. AWS IoT Core da a cada
nodo de finca y a cada dron su propio certificado X.509, publica por MQTT sobre TLS y permite
revocar un certificado puntual. Eso resuelve de forma directa el requisito de dar de baja un nodo
o un dron perdido para que deje de publicar, sin montar un broker propio.

Segundo, el enunciado pide funciones que se invocan con un disparador y terminan al persistir el
resultado, sin cómputo esperando objetos. La combinación S3 → Lambda → Rekognition es el camino
más corto para eso: el objeto queda en S3, el evento invoca la función y la función llama a un
servicio de visión administrado. Las colas de fallos (DLQ) y los reintentos son nativos.

Tercero, AWS Organizations con políticas de control de servicio (SCP) y políticas de etiquetas
da la landing zone que pide el punto 1: cuentas separadas de seguridad, red, producción y
pruebas, con etiquetas obligatorias que alimentan el costeo por finca, dron, acopio, viaje y
ambiente.

Cuarto, el equipo junior ya adelantó la propuesta de tecnologías sobre AWS
(`borradores-junior/Propuestas-de-Tecnologias.md`). Ese trabajo se aprovecha como insumo, con
las correcciones que piden los issues.

### Región principal

La región principal es **US East (N. Virginia), `us-east-1`**.

Se descarta São Paulo (`sa-east-1`) a pesar de la cercanía geográfica, porque sus precios son
notablemente más altos y el piloto tiene la restricción explícita de inversión moderada. Además,
el tráfico de internet colombiano sale mayoritariamente por los cables submarinos que llegan a
Miami, así que la latencia real hacia el este de Estados Unidos es competitiva. `us-east-1` tiene
todos los servicios que usa el diseño (IoT Core, Lambda, Rekognition, DynamoDB, S3).

Como región de respaldo para la consulta pública del saco (RTO de 4 horas, RPO de 15 minutos) se
usa **US East (Ohio), `us-east-2`**.

Que la plataforma viva fuera de Colombia significa que datos personales de caficultores y
transportadores, y las imágenes enviadas a inferencia, salen del país. El documento de seguridad
y el de inferencia deben decir qué sale, con qué base legal (Ley 1581 de 2012) y qué se queda.

### Segunda nube

La segunda nube preparada es **Microsoft Azure**. Se deja lista sin duplicar la plataforma: un
punto de interconexión, identidad federada y la convención de módulos para poder agregar el
proveedor `azurerm`. No se crea infraestructura en Azure.

## 3. Herramientas de infraestructura como código y CI/CD

La herramienta de infraestructura como código es **Terraform**.

Es agnóstica de proveedor, lo que conserva el trabajo si la segunda nube llega a usarse, y su
verbo central, `terraform plan`, es exactamente lo que pide la Épica 6: un código que genere un
plan. El estado remoto vive en S3 cifrado con KMS y con bloqueo de concurrencia.

La plataforma de CI/CD es **GitHub Actions**, autenticada contra AWS con OIDC (sin llaves de
acceso guardadas). Los ambientes de GitHub dan la aprobación manual antes de aplicar en
producción.

El repositorio de infraestructura como código es `aromapacifico-platform/iac`.

## 4. Qué se codifica en la Épica 6

El enunciado deja elegir entre el módulo de ingesta y el de consulta del saco. Se codifica el
**módulo de ingesta de telemetría**, junto con el módulo reutilizable de una finca patrón. Es el
flujo que más diferencia este piloto del diseño de 2020 (store-and-forward, umbrales
configurables, alertas), y es donde la sustentación va a recibir más preguntas.

La función que se codifica como patrón es la del **objeto de confirmación del foco**: el dron
deja la imagen en S3, la función la lee, llama a Rekognition y escribe el resultado en el
expediente. Tiene los tres permisos que pide el enunciado (leer el objeto, escribir el resultado
e invocar inferencia). Las otras tres funciones quedan diseñadas en la arquitectura y no se
codifican.

Se codifica un solo ambiente con su plan. No se instancian las 200 fincas ni los tres centros de
acopio.

## 5. Estructura de `docs/` en este repositorio

Los nombres de carpeta van en inglés, porque son rutas del repositorio y siguen la misma
convención que el código. El contenido dentro de cada archivo sigue en español.

| Carpeta | Contenido | Se llena en |
|---|---|---|
| `docs/governance-and-decisions/` | Este documento y cualquier decisión base adicional | Fase 0 (senior) |
| `docs/architecture/` (con `diagrams/`) | Los siete puntos del reto y el diagrama completo | Fase 1 |
| `docs/iac/` | Plan de 100 horas y evidencia del código de infraestructura | Fase 2 |
| `docs/costs/` | Hardware de finca, mes normal, mes de cosecha y campaña de drones | Fase 3 |
| `docs/change/` | Plantillas y ejemplos de release notes | Fase 4 |
| `docs/design/` | Sistema de diseño de las tres aplicaciones | Fase 5 |
| `docs/presentation/` | Presentación, banco de preguntas y ensayo | Fase 6 |
| `docs/cross-cutting/` | Registro de supuestos, revisión final y checklist de entrega | Fase 7 (y de forma continua) |

## 6. Borradores del equipo junior

En `docs/governance-and-decisions/borradores-junior/` están los documentos que adelantó el
equipo junior: la fuente de verdad, la propuesta de tecnologías, el plan de tareas y un borrador
del diagrama de flujo de datos. Son insumo, no fuente de verdad. La fuente de verdad es el
enunciado (`docs/case-study/enunciado-original.md`).

Puntos que hay que corregir al usarlos:

- Los diagramas que enlaza la fuente de verdad apuntan a rutas locales de Windows y no existen
  en el repositorio. Los diagramas oficiales se rehacen en `docs/architecture/diagrams/`.
- El plan de tareas cita plantillas en `agentes/templates/` que no existen. Las plantillas de
  release notes se crean en la Fase 4.
- Las cifras de costo y de ahorro (por ejemplo, el ahorro de CapEx en hardware) hay que
  recalcularlas con cotizaciones actuales y fuente visible.
- No cubren algunos requisitos del enunciado: fincas fuera de cobertura sin radiobase nueva ni
  visita semanal, Buenaventura sin infraestructura de la Federación, escalar de 200 a 1.000
  fincas, quién vuela el dron, región de inferencia y qué sale del país, y la tabla de firewall
  con reglas permanentes y temporales. Cada uno tiene su issue.

## 7. Registro de supuestos

Cualquier decisión que un junior tome sin que esté escrita en el enunciado ni en este documento
queda anotada en `docs/cross-cutting/assumptions-log.md`, con esta estructura:

| Supuesto | Justificación | Issue que lo originó | Estado |
|---|---|---|---|
| Ejemplo: el buffer del nodo guarda las lecturas en memoria flash y descarta las más viejas al pasar 24 horas | El enunciado fija las 24 horas pero no dice qué pasa con la lectura número 25 | (número del issue) | Asumido en el diseño |
