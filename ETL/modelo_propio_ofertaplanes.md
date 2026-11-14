# Modelo multidimensional del proyecto – RaSa / OfertaPlanes
Astrid Lorena Roa Avila

Se propone un modelo dimensional para el proceso de negocio **OfertaPlanes** de RaSa, que
se realiza de forma anual. El objetivo es analizar los valores de copago y coseguro de los
beneficios ofrecidos por los proveedores, la cobertura de los planes sobre las áreas de
servicio y la concentración de planes por área, estado y condado, conservando la historia
de los atributos de las dimensiones.

El documento sigue los mismos cinco pasos del trabajo de AlpesCuisine: criterios de
evaluación, modelo propio, modelo generado con IA, validación con IA y modelo final ajustado.

---

## 1. Criterios de calidad

Los criterios completos, con sus preguntas de verificación, están en
`criterios_validacion_ofertaplanes.md`. Respecto a AlpesCuisine se agregó **C7. Historia de
los atributos de las dimensiones**, porque la guía la exige de forma explícita.

| Criterio | Qué evalúa | Cómo se verifica |
|---|---|---|
| C1. Cumplimiento de los análisis | Que el modelo responda 1.a, 2.a, 2.b, 2.c, 3.a y 3.b | Matriz de trazabilidad y una consulta de ejemplo por análisis |
| C2. Definición del grano | Qué representa cada fila y si es coherente con un proceso anual | Grano escrito en cada hecho y restricción única sobre sus llaves |
| C3. Hechos y medidas | Que las medidas sean medidas y su aditividad | Tabla de medidas con aditividad y agregación permitida |
| C4. Dimensiones y atributos | Que las dimensiones sean conceptos del negocio con atributos descriptivos | Revisión contra el diccionario de datos |
| C5. Relaciones y llaves foráneas | FK completas, cardinalidad 1:N, roles y relación área–condado | Diagrama y referencias del DBML |
| C6. Consistencia | Nombres, tipos, dimensiones conformadas | Revisión del DBML |
| C7. Historia de atributos | Tipo de SCD por dimensión y vigencias | Columnas de vigencia y regla de búsqueda por año |
| C8. Buenas prácticas | Estrella sin copos de nieve, casos especiales, nada no sustentado | Notas del modelo y miembros especiales |

---

## 2. Modelo propio

### Paso 1. Proceso de negocio

El proceso es **OfertaPlanes**: cada año los proveedores publican planes que ofrecen tipos
de beneficio en áreas de servicio, con un valor de copago, un valor de coseguro, sus
condiciones de pago y, cuando aplica, un límite cuantitativo. Se eligió porque la guía lo
define como el proceso a modelar y porque todos los análisis (copagos, cobertura y
concentración) se originan en la oferta de planes.

Se decidió trabajar con **una sola tabla de hechos** para mantener el modelo simple y
enfocado en el proceso que pide la guía.

### Paso 2. Definición del grano

`Hecho_OfertaPlanes`: una fila por **plan, tipo de beneficio y área de servicio ofrecido
en un año**.

Es el nivel más detallado de F3 (IdPlan, IdTipoBeneficio, IdAreaDeServicio y fecha), y a ese
nivel se registran el copago, el coseguro y el límite cuantitativo. Además respeta que el
proceso es anual. El hecho tiene una llave técnica y una restricción única sobre las llaves
del grano, para evitar duplicados (las fuentes aún pueden tenerlos).

### Paso 3. Definición de dimensiones

| Dimensión | Llave subrogada (PK) | Llave natural | Atributos | Historia (SCD) | Fuente |
|---|---|---|---|---|---|
| Dim_Fecha | ID_Fecha | Fecha | Dia, Mes, NombreMes, Trimestre, Semestre, **Anio** | No aplica (calendario) | Generada |
| Dim_Proveedor | ID_Proveedor | IdProveedor | NombreProveedor (si existe) | Tipo 1 | F1, F3 |
| Dim_Plan | ID_Plan | IdPlan | Atributos descriptivos del plan que traiga F3 | Tipo 1 | F3 |
| Dim_TipoBeneficio | ID_TipoBeneficio | IdTipoBeneficio + AnioVigencia | NombreBeneficio, Condiciones (Yes/No), UnidadLimite, FechaInicioVigencia, FechaFinVigencia, EsVersionActual | **Tipo 2 anual** | F2 |
| Dim_AreaDeServicio | ID_AreaDeServicio | IdAreaDeServicio + FechaInicioVigencia | NombreAreaDeServicio, Estado, CubreEstadoCompleto, FechaInicioVigencia, FechaFinVigencia, EsVersionActual | **Tipo 2** | F1 |
| Dim_CondicionPago | ID_CondicionPago | IdCondicionPago | TipoCondicion (Copago/Coseguro), DescripcionCondicion | Tipo 1 | F4 |

Decisiones:
- **Dim_CondicionPago con dos roles** (condición del copago y condición del coseguro): una
  sola tabla para un mismo concepto, como se hizo con las restricciones en AlpesCuisine.
- **Proveedor como dimensión propia conectada al hecho** y no colgada de Dim_Plan, para
  evitar un copo de nieve y porque 1.a, 2.b y 2.c se analizan por proveedor.
- **Miembro 0 = Desconocido en todas las dimensiones.** En Dim_AreaDeServicio es obligatorio:
  F3 trae IdAreaDeServicio que no existen en F1 y el negocio pidió no omitirlos.

### Paso 4. Identificar los hechos

**Hecho_OfertaPlanes**

| Columna | Tipo | Descripción |
|---|---|---|
| ID_OfertaPlanes | PK técnica | Identificador de la fila |
| ID_Fecha | FK → Dim_Fecha | Fecha de la oferta; define el año |
| ID_Proveedor | FK → Dim_Proveedor | Proveedor que ofrece el plan |
| ID_Plan | FK → Dim_Plan | Plan ofrecido |
| ID_TipoBeneficio | FK → Dim_TipoBeneficio | Versión del tipo de beneficio vigente en el año |
| ID_AreaDeServicio | FK → Dim_AreaDeServicio | Área donde se ofrece (0 si es desconocida) |
| ID_CondicionCopago | FK → Dim_CondicionPago (rol) | Condición del copago |
| ID_CondicionCoseguro | FK → Dim_CondicionPago (rol) | Condición del coseguro |
| ValorCopago | Medida **no aditiva** | Valor del copago. Se agrega con promedio, mínimo o máximo |
| ValorCoseguro | Medida **no aditiva** | Porcentaje de coseguro (0–100) |
| LimiteCuantitativo | Medida **no aditiva** | Límite del beneficio; 333 por defecto si viene vacío o en cero |
| CantidadOfertas | Medida **aditiva** | Vale 1; cuenta ofertas plan–beneficio–área |

¿Por qué copago y coseguro son medidas y no atributos? Son valores numéricos que se miden en
cada oferta y se comparan y agregan (promedio, máximo, diferencia porcentual en 1.a). Pero
no tienen sentido sumados entre filas, por eso se documentan como no aditivos.

### Diagrama del modelo

Esquema en estrella: `Hecho_OfertaPlanes` en el centro y seis dimensiones a su alrededor.
`Dim_CondicionPago` se conecta dos veces (copago y coseguro). El diagrama está en
`modelo_ofertaplanes.drawio` y el código en `modelo_inicial_ofertaplanes.dbml`.

---

## 3. Manejo de la historia de los atributos

| Dimensión | Tipo | Justificación |
|---|---|---|
| Dim_TipoBeneficio | SCD Tipo 2, vigencia anual | El negocio confirmó que cada tipo de beneficio tiene un solo valor de condiciones y unidad de límite **por año**, y esos valores pueden variar entre años. Se guarda una versión por año. |
| Dim_AreaDeServicio | SCD Tipo 2 | F1 trae información por año (2017, 2018 y 2019). El nombre del área o si cubre el estado completo pueden cambiar. |
| Dim_Proveedor, Dim_Plan, Dim_CondicionPago | SCD Tipo 1 | No hay evidencia de cambios en sus atributos; se sobrescriben. |

Regla de carga: el hecho toma la llave subrogada de la versión cuya vigencia contiene la
fecha de la oferta (`FechaInicioVigencia <= Fecha < FechaFinVigencia`). Así un análisis de
2017 ve las condiciones de 2017 aunque hayan cambiado en 2019.

---

## 4. Trazabilidad: qué responde cada elemento

| Análisis | Elementos del modelo | Cómo se responde |
|---|---|---|
| 1.a Competencia desleal (copago/coseguro con diferencia > 20 %) | Hecho_OfertaPlanes (ValorCopago, ValorCoseguro), Dim_Proveedor, Dim_TipoBeneficio, Dim_CondicionPago, Dim_Fecha | Por año y tipo de beneficio, se compara el valor de cada proveedor con el de los demás (o con el promedio) y se marcan diferencias mayores al 20 %. |
| 2.a Nivel de cobertura de planes vs áreas | Hecho_OfertaPlanes, Dim_AreaDeServicio, Dim_Fecha | Áreas con al menos un plan ÷ total de áreas de la dimensión vigentes en el año. |
| 2.b ¿Proveedores cubren todas las áreas? | Hecho_OfertaPlanes, Dim_Proveedor, Dim_AreaDeServicio | Por proveedor y año: áreas distintas cubiertas frente al total de áreas. |
| 2.c Áreas cubiertas por menos de dos proveedores | Hecho_OfertaPlanes, Dim_AreaDeServicio, Dim_Proveedor | Por área y año: COUNT(DISTINCT ID_Proveedor) < 2. |
| 3.a Cuántos y cuáles planes por área, estado o condado | Hecho_OfertaPlanes, Dim_Plan, Dim_AreaDeServicio | COUNT(DISTINCT ID_Plan) por área y estado. **Por condado no se puede**, porque un área cubre varios condados y el modelo no guarda esa relación. |
| 3.b Concentración de planes vs habitantes | Hecho_OfertaPlanes, Dim_AreaDeServicio | **Parcialmente factible**: se cuentan planes por área y estado, pero el modelo no guarda los habitantes. Se deja como limitación conocida. |

---

## 5. Casos especiales y supuestos

- **Área desconocida (Id = 0):** se crea el miembro y las ofertas con áreas inexistentes se
  cargan apuntando a él. En 2.a, 2.b y 2.c se excluye para no contarlo como área real.
- **Límite cuantitativo 333:** se asigna en la carga cuando el plan ofrece límite y el valor
  viene vacío o en cero, para identificar el error.
- **Valores estandarizados:** Condiciones solo Yes/No; TipoCondicion solo Copago/Coseguro.
- **Validaciones de rango:** copago ≤ 3500 y coseguro ≤ 100 para 2018.
- **Fechas:** todas en formato YYYY-MM-DD antes de buscar la llave en Dim_Fecha.
- **Duplicados:** se eliminan antes de cargar; la restricción única del grano lo garantiza.
- **Supuesto:** cada fila de F3 tiene una sola condición para el copago y una para el coseguro.
- **Limitación aceptada:** al usar una sola tabla de hechos, el modelo no baja de área de
  servicio a condado ni guarda la población. Esto afecta la parte de condados de 3.a y el
  análisis 3.b. Es un buen punto para revisar en la validación con IA.
- **Por confirmar con el diccionario de datos:** nombres exactos de columnas de origen y los
  atributos descriptivos de plan y proveedor.

---

## 6. Uso de IA (actividades y prompts)

| Actividad | Prompt | Archivo generado |
|---|---|---|
| Pasar el diagrama de draw.io a DBML | `promt_draw_a_dbml.md` | `modelo_inicial_ofertaplanes.dbml` |
| Generar el modelo alternativo con IA | `promt_generacion_modelo_ia.md` | `modelo_ia_ofertaplanes.dbml` |
| Validar el modelo propio con los criterios | `promt_validacion_modelo_propio.md` | `validacion_modelo_inicial_ofertaplanes.md` |
| Validar el modelo IA con los criterios | `promt_validacion_modelo_ia.md` | `validacion_modelo_ia_ofertaplanes.md` |
| Materializar cada modelo en SQLite | `promt_generacion_base_SQLite.md` | `modelo_*_ofertaplanes.sqlite` |
| Validación práctica con consultas | `promt_validacion_practica.md` | `consultas_*` y `resultados_factibilidad_*` |
| Generar el modelo final ajustado | `promt_generacion_modelo_final.md` | `modelo_final_ofertaplanes.dbml` |

Archivos que la IA debe tener en el directorio de trabajo:
`caso_rasa_ofertaplanes.md`, `Guia_Modelo_Dimensional_ETL.pdf`, el diccionario de datos
de RasaTransaccional guardado como `diccionario_datos_rasa` (pdf o xlsx) y
`criterios_validacion_ofertaplanes.md`.

Para el informe, en cada actividad incluya el prompt, la respuesta obtenida y qué decisión
de diseño cambió por esa respuesta. En el modelo final, para cada recomendación de la IA
indique si la **adoptó, la modificó o la descartó**, y por qué.
