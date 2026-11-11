> Codex adaptation: read repository AGENTS.md for current interfaces, versions and authorized scope.

# 📄 Regla de For_Each y Control de Recursos

**ID:** PC-IAC-010  
**Tipo:** Recursos / Estabilidad  
**Pilares AWS Well-Architected:** Operational Excellence, Security  
**Versión:** 1.0  
**Fecha:** 10 de diciembre de 2025

---

## 1. Propósito y Alcance

Esta regla define los metargumentos y bloques de ciclo de vida (`lifecycle`) obligatorios para controlar la creación, modificación y destrucción de los recursos, priorizando la estabilidad del estado de Terraform.

**Aplicable a:** Todos los bloques `resource` en `main.tf` y otros archivos de recursos dentro de los Módulos de Referencia y el Módulo Raíz.

---

## 2. Metargumentos de Colección

### 2.1. Uso Mandatorio de `for_each`

El metargumento **`for_each`** es la opción preferida y obligatoria para la creación de múltiples instancias de un recurso a partir de una colección.

* **Razón:** Asegura que los identificadores de recursos sean nombres lógicos (keys del mapa/set) y no índices numéricos, previniendo la corrupción del estado de Terraform si se elimina o reordena un elemento.
* **Requisito:** `for_each` debe usarse con colecciones de tipo `map` o `set`.

### 2.2. Uso Restringido de `count`

El metargumento **`count`** solo está permitido en las siguientes excepciones:

* Cuando solo se crea una instancia condicionalmente (`count = var.enable_resource ? 1 : 0`).
* Para recursos que deben ser secuenciales y la ordenación es inmutable.

---

## 3. Bloque `lifecycle`

El bloque `lifecycle` debe usarse para proteger los recursos críticos y gestionar el comportamiento de las actualizaciones.

### 3.1. Protección de Destrucción (`prevent_destroy`)

El atributo `prevent_destroy = true` es obligatorio para cualquier recurso cuya eliminación podría causar una interrupción grave o irrecuperable.

* **Mandatorio para:** Buckets S3 de estado (`tfstate`), bases de datos (RDS), *key pairs*, VPCs principales, etc.

    ```hcl
    resource "aws_db_instance" "example" {
      # ... configuración de la base de datos
      lifecycle {
        prevent_destroy = true # Obligatorio para recursos críticos
      }
    }
    ```

### 3.2. Ignorar Cambios (`ignore_changes`)

El uso de `ignore_changes` está fuertemente restringido, ya que puede llevar a una deriva de configuración difícil de rastrear.

* **Permitido solo para:** Atributos que son modificados por agentes externos a Terraform (ej. el escalado automático de ECS/ASG).
* **Prohibido para:** Configuraciones gestionadas directamente por la IaC (ej. tamaño de instancias, reglas de *ingress*).

---

## 4. Dependencias Explícitas vs Implícitas

### 4.1. Dependencias Implícitas (Preferidas)

Debe priorizarse siempre la dependencia implícita, que ocurre cuando se hace referencia a un atributo de otro recurso (ej. `vpc_id = aws_vpc.this.id`).

### 4.2. Uso Restringido de `depends_on`

El metargumento **`depends_on`** solo se debe usar para resolver dependencias ocultas o *race conditions* que no pueden resolverse mediante una referencia de atributo.

* **Razón:** Su uso excesivo oculta el verdadero gráfico de dependencias.

---

## 5. Criterios de Cumplimiento

✅ Se utiliza `for_each` en lugar de `count` para la creación de colecciones de recursos.  
✅ Los recursos críticos utilizan el bloque `lifecycle` con `prevent_destroy = true`.  
✅ Se evita el uso de `ignore_changes` a menos que sea para atributos gestionados por agentes externos.  
✅ Se utiliza `depends_on` solo para resolver dependencias ocultas no manejables por referencias implícitas.

---

## 6. Relación con Pilares AWS Well-Architected

| Pilar | Cómo contribuye esta regla |
| :--- | :--- |
| **Operational Excellence** | El uso de `for_each` asegura la estabilidad del estado y facilita la adición/eliminación de elementos sin corruptar recursos. |
| **Security** | El uso obligatorio de `prevent_destroy` para recursos clave (ej. Buckets de estado, DBs) impide la eliminación accidental que podría exponer datos o causar indisponibilidad. |
