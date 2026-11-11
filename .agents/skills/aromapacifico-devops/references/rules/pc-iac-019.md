> Codex adaptation: read repository AGENTS.md for current interfaces, versions and authorized scope.

# 📄 Regla de Uso Restringido de Remote State

**ID:** PC-IAC-019  
**Tipo:** Integración / Estado  
**Pilares AWS Well-Architected:** Operational Excellence, Security  
**Versión:** 1.0  
**Fecha:** 10 de diciembre de 2025

---

## 1. Propósito y Alcance

Esta regla restringe el uso de `terraform_remote_state` como mecanismo de comunicación entre dominios, priorizando el uso de Data Sources para reducir el acoplamiento y mejorar la flexibilidad.

**Aplicable a:** El Módulo Raíz (IaC Root) de dominios que necesiten consumir infraestructura de otros dominios.

---

## 2. Prioridad de Comunicación Entre Dominios

### 2.1. Data Sources como Mecanismo Principal (Obligatorio)

El mecanismo **principal y preferido** para la comunicación entre dominios debe ser el uso de **Data Sources** (referencia **PC-IAC-017**).

* **Ventajas:**
  - Menor acoplamiento entre estados de Terraform
  - No requiere exponer todos los outputs del estado remoto
  - Más flexible ante cambios en la estructura del estado
  - Permite filtrado específico de recursos por tags o atributos

### 2.2. Remote State como Excepción Justificada

El uso de `data "terraform_remote_state"` está **fuertemente restringido** y solo se permite bajo las siguientes condiciones:

1. **Complejidad Técnica:** Cuando obtener la información mediante Data Sources es técnicamente prohibitivo o excesivamente complejo.
2. **Requisito de Múltiples Outputs:** Cuando se necesitan múltiples outputs relacionados que no tienen un mecanismo de consulta directo mediante Data Sources.
3. **Documentación Obligatoria:** La razón de la excepción debe estar documentada explícitamente en el `README.md` del dominio consumidor.

---

## 3. Restricciones de Uso de Remote State

### 3.1. Documentación Obligatoria

Si se utiliza `terraform_remote_state`, debe incluirse un comentario en el código y una sección en el README explicando:
- Por qué no se pudo usar un Data Source
- Qué outputs específicos se están consumiendo
- La justificación técnica de la decisión

**Ejemplo de documentación en código:**
```hcl
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "estado-networking"
    key    = "networking/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### 3.2. Limitación de Outputs Expuestos

Si un dominio expone su estado vía remote state, debe:
- Exponer **solo** los outputs mínimos necesarios
- Evitar exponer objetos completos de recursos
- Mantener una lista documentada de los outputs públicos en su README

---

## 4. Patrón Recomendado: Data Sources

### 4.1. Ejemplo Correcto (Usando Data Sources)

```hcl
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["${var.client}-${var.project}-${var.environment}-vpc"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  
  filter {
    name   = "tag:Type"
    values = ["private"]
  }
}
```

### 4.2. Ejemplo Excepcional (Remote State con Justificación)

```hcl
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "networking/${var.environment}/terraform.tfstate"
    region = var.region
  }
}

locals {
  vpc_id           = data.terraform_remote_state.networking.outputs.vpc_id
  tgw_attachment_id = data.terraform_remote_state.networking.outputs.tgw_attachment_id
}
```

---

## 5. Criterios de Cumplimiento

✅ La comunicación entre dominios utiliza **Data Sources** como mecanismo principal.  
✅ El uso de `terraform_remote_state` está justificado y documentado en el README.  
✅ Los outputs expuestos vía remote state son granulares y mínimos.  
✅ Se evita la exposición de objetos completos de recursos.

---

## 6. Relación con Pilares AWS Well-Architected

| Pilar | Cómo contribuye esta regla |
| :--- | :--- |
| **Operational Excellence** | El uso de Data Sources reduce el acoplamiento entre dominios, facilitando la evolución independiente de cada uno. |
| **Security** | Limitar el uso de remote state reduce la superficie de exposición de información sensible entre estados. |

---

## 7. Proceso de Revisión

Cuando se proponga el uso de `terraform_remote_state`:

1. **Evaluar Alternativas:** Verificar si existen Data Sources nativos de AWS que puedan resolver el mismo requisito.
2. **Documentar Justificación:** Crear una sección en el README del módulo explicando la decisión.
3. **Revisión por Pares:** El uso de remote state debe ser aprobado en revisión de código.
4. **Marcar para Revisión Futura:** Documentar como deuda técnica si existe la posibilidad de migrar a Data Sources en el futuro.
