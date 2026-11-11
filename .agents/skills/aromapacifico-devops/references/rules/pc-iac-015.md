> Codex adaptation: read repository AGENTS.md for current interfaces, versions and authorized scope.

# 📄 Regla de Consumo de Módulos (Remoto y Versionado)

**ID:** PC-IAC-015  
**Tipo:** Modularización / Versionamiento  
**Pilares AWS Well-Architected:** Operational Excellence, Security  
**Versión:** 2.0 (Ajustada a la Estrategia)  
**Fecha:** 10 de diciembre de 2025

---

## 1. Propósito y Alcance

Esta regla define el estándar obligatorio para el consumo de Módulos de Referencia, reforzando el principio de la organización de que los módulos deben ser **componentes reutilizables versionados y mantenidos centralmente**.

**Aplicable a:** El argumento `source` de todos los bloques `module` en el Módulo Raíz (IaC Root) y en los Módulos de Referencia.

---

## 2. Consumo de Módulos (Remoto Obligatorio)

### 2.1. Versionamiento Remoto (Mandatorio)

Todos los Módulos de Referencia deben ser consumidos desde un origen remoto (ej. Repositorio Git, Registry, S3), cumpliendo con el principio de "Un módulo, un repositorio".

* **Requisito:** La `source` debe apuntar al repositorio central de módulos.

    ```hcl
    # Ejemplo de Consumo Obligatorio
    module "vpc" {
      source = "git::https://repo-url/modulo-vnet.git?ref=v1.2.0" 
      # ...
    }
    ```

### 2.2. Versionamiento Semántico Estricto

Es obligatorio utilizar una referencia de versión explícita basada en **tags SemVer** (`vX.Y.Z`).

* **Prohibido:** Está **estrictamente prohibido** utilizar referencias a ramas de larga duración (`ref=main`, `ref=master`) o *commits* específicos para despliegues en ambientes compartidos (`qa`, `pdn`).
* **Razón:** Garantiza que el código de IaC sea **inmutable** y que los despliegues utilicen exactamente la misma versión auditada.

---

## 3. Excepciones de Uso Local

El uso de referencias locales (`./`, `../`) está fuertemente restringido y solo permitido en las siguientes excepciones temporales:

1.  **Desarrollo Local:** Durante la fase de desarrollo o la corrección de un bug en el módulo, para facilitar el *testing* iterativo.
2.  **Regla de Promoción:** Cualquier módulo con una fuente local debe ser migrado a una referencia remota versionada antes de su despliegue en ambientes compartidos (`qa`, `pdn`).

---

## 4. Criterios de Cumplimiento

✅ La `source` apunta a un repositorio remoto (Git, S3, Registry).  
✅ La referencia de versión utiliza tags de SemVer explícitos (ej. `?ref=v1.2.0`).  
✅ Se prohíbe el uso de `ref=main` o referencias a ramas en ambientes compartidos.  
✅ Se prohíbe el uso de rutas locales, excepto en desarrollo.

---

## 5. Relación con Pilares AWS Well-Architected

| Pilar | Cómo contribuye esta regla |
| :--- | :--- |
| **Operational Excellence** | El versionamiento SemVer y el consumo remoto garantizan la trazabilidad, la inmutabilidad y la reproducibilidad de los despliegues. |
| **Security** | Asegura que el código de IaC en producción ha sido previamente auditado y es inmutable. |
