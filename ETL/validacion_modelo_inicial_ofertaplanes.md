# Validación del modelo multidimensional inicial – OfertaPlanes (RaSa)

## Alcance y fuentes utilizadas

- **Modelo evaluado:** `modelo_inicial_ofertaplanes.dbml` (203 líneas).
- **Caso de negocio:** `caso_rasa_ofertaplanes.md`.
- **Guía:** `Guia_Modelo_Dimensional_ETL.pdf` (páginas 1 a 3: instrucciones, análisis requeridos y respuestas del negocio).
- **Diccionario de datos:** hoja `Diccionario` del diccionario de RaSa. En el directorio de trabajo no existe un archivo llamado `diccionario_datos_rasa`; se utilizó el diccionario disponible (`Diccionario.xlsx`), que contiene las cuatro fuentes F1 a F4.
- **Criterios aplicados:** `criterios_validacion_ofertaplanes.md`, únicamente C1 a C7.

No se utilizó `modelo_ia_ofertaplanes.dbml` ni se comparó el modelo inicial con ninguna otra propuesta. No se asignan puntuaciones numéricas. Esta validación no reconstruye el modelo ni genera una versión corregida.

**Nota sobre el diccionario:** las cuatro tablas documentadas son `FuenteAreasDeServicio_Copia_E`, `FuenteCondicionesDePago_Copia_E`, `FuentesPlanesBeneficio_Copia_E` y `FuenteTiposBeneficio_Copia_E`. No existe en el diccionario una tabla de proveedores ni de niveles de servicio; el proveedor solo aparece como `idProveedor_T` dentro de la fuente de planes-beneficio.

---

## C1. Cumplimiento de los análisis requeridos

**Parte del modelo relacionada:** `Hecho_OfertaPlanes` y todas las dimensiones, con énfasis en `Dim_AreaDeServicio` (geografía), `Dim_Proveedor`, `Dim_TipoBeneficio` y `Dim_Plan`.

**Resultado:** Cumple parcialmente

### Respuesta a las preguntas de verificación

| Pregunta | Respuesta |
|---|---|
| i. ¿El modelo permite comparar el copago y el coseguro entre proveedores para un mismo tipo de beneficio? | **Sí para proveedores individuales; no para grupos de proveedores.** El hecho guarda `ID_Proveedor`, `ID_TipoBeneficio`, `ValorCopago` y `ValorCoseguro`, lo que permite agrupar por tipo de beneficio y comparar valores entre proveedores. No existe ningún atributo de agrupación de proveedores ni nombre de proveedor respaldado por las fuentes. |
| ii. ¿Permite ver qué áreas de servicio cubren los planes y cuántos proveedores hay en cada área? | **Sí.** El hecho relaciona plan, área y proveedor. Es posible listar áreas cubiertas y contar proveedores distintos por área, siempre que se controlen las versiones SCD de área y se cargue el universo completo de áreas de F1. |
| iii. ¿Algún análisis necesita información que no está en las fuentes F1 a F4? | **Parcialmente.** El condado (`idGeografía_T`, `Condado`) y la población (`PoblacionAct`) sí están en F1. Sin embargo: (a) la población de F1 es "actual", no histórica por año; (b) el nombre del proveedor no existe en el diccionario, solo el identificador en F3; (c) no hay fuente de agrupación de proveedores ni de niveles de servicio. |
| iv. ¿El análisis sería viable con el grano propuesto? | **Sí para 1.a, 2.a, 2.b y 2.c; parcial para 3.a; no para 3.b.** El grano implícito (plan × tipo de beneficio × área × fecha) soporta los análisis de copago/coseguro y cobertura. No soporta el análisis por condado ni la comparación con habitantes porque esos atributos no están en el modelo. |

### Detalle por análisis

| Análisis | Viabilidad | Sustento |
|---|---|---|
| **1.a** Copago/coseguro entre proveedores para un mismo tipo de beneficio | **Resoluble con salvedades** | Las medidas y las llaves necesarias existen (`dbml:155-162`). Limitaciones: no hay "grupo de proveedores" y el nombre del proveedor no proviene de F1-F4. La comparación debe hacerse dentro de una misma versión anual del tipo de beneficio. |
| **2.a** Cobertura de planes respecto a las áreas en un rango de años | **Resoluble condicionada** | Requiere que `Dim_AreaDeServicio` contenga todas las áreas de F1, no solo las que aparecen en F3; de lo contrario, las áreas sin oferta no existen y la cobertura se sobreestima. |
| **2.b** Cobertura total de proveedores sobre TODAS las áreas | **Resoluble condicionada** | Misma condición anterior: sin el universo completo de áreas, las áreas no cubiertas son invisibles. Además debe tratarse el área desconocida (Id = 0) para no distorsionar el universo. |
| **2.c** Áreas cubiertas por menos de dos proveedores | **Resoluble condicionada** | Requiere el universo completo de áreas y conteo de proveedores distintos, no de filas. Con el área desconocida (Id = 0) debe decidirse explícitamente si participa. |
| **3.a** Cantidad y cuáles planes por área, estado o condado | **Parcial** | Por área y por estado sí (`Dim_AreaDeServicio.Estado`, `dbml:132`). Por **condado no**, porque el modelo no incluye `Condado` ni `idGeografía_T`. |
| **3.b** Concentración de planes vs. cantidad de habitantes | **No resoluble** | No hay condado ni población en el modelo. Además, aun incorporando `PoblacionAct` de F1, sería población actual y no del año analizado. |

### Evidencia

- El hecho contiene `ID_Proveedor` (`modelo_inicial_ofertaplanes.dbml:155`), `ID_Plan` (`:156`), `ID_TipoBeneficio` (`:157`), `ID_AreaDeServicio` (`:158`), `ValorCopago` (`:161`) y `ValorCoseguro` (`:162`).
- Las relaciones e1, e5 y e6 conectan el hecho con tipo de beneficio, proveedor y área (`dbml:186`, `:200`, `:203`).
- `Dim_AreaDeServicio` solo contiene `NombreArea` y `Estado` como atributos descriptivos (`dbml:132-133`).
- El diccionario de F1 incluye `idGeografía_T` ("Identificador del condado"), `Condado` y `PoblacionAct` ("Número de habitantes actuales"), campos que no fueron incorporados al modelo.
- El diccionario de F3 incluye `idNivelServicio_T`, que tampoco está representado en el modelo.
- El caso pide explícitamente los análisis por "estados o condados" y "cantidad de habitantes del área" (`caso_rasa_ofertaplanes.md:22-23`).
- La regla de negocio 1 indica que las áreas de servicio no cubren todos los condados (`caso:35`), lo que refuerza la necesidad de una geografía completa.

### Análisis

El modelo cubre el núcleo del proceso (oferta de planes por beneficio y área) y permite los análisis de competencia y cobertura. Sin embargo, la dimensión de área quedó reducida a `NombreArea` y `Estado`, omitiendo la jerarquía geográfica y la población que F1 sí provee. El análisis 3.a queda incompleto y el 3.b no puede responderse. Adicionalmente, la ausencia de nombre y agrupación de proveedores limita la lectura de 1.a: se pueden comparar identificadores, pero no identificar proveedores ni analizar grupos.

Hay dos limitaciones de información que el modelo no puede resolver por sí solo: la población de F1 es actual (no histórica) y no existe una fuente de nombres o grupos de proveedores dentro de F1-F4. La primera afecta la interpretación temporal de 3.b; la segunda afecta la identificabilidad de los proveedores en 1.a.

### Impacto sobre los análisis requeridos

- **3.b no se puede responder:** no se puede evaluar si la concentración de planes corresponde o no a la cantidad de habitantes, que es precisamente el objetivo del análisis.
- **3.a queda a medias:** se puede ver por estado, pero no por condado, lo que impide localizar concentraciones a la granularidad solicitada.
- **2.a, 2.b y 2.c pueden arrojar resultados falsos** si la dimensión de área no se carga con todas las áreas de F1.
- **1.a queda limitada** a comparaciones anónimas por identificador y sin análisis por grupo de proveedores.

### Recomendación

Incorporar a `Dim_AreaDeServicio` (o a una dimensión geográfica relacionada) los atributos `idGeografía_T`, `Condado` y `PoblacionAct`, y documentar que la población es actual. Agregar una fuente o atributo de nombre y agrupación de proveedores, o dejar explícito que 1.a se resuelve solo por identificador. Documentar que `Dim_AreaDeServicio` debe cargarse con el universo completo de F1, incluido el miembro Desconocido (Id = 0), para que los análisis de cobertura sean válidos.

---

## C2. Definición del grano

**Parte del modelo relacionada:** `Hecho_OfertaPlanes` y sus relaciones.

**Resultado:** Cumple parcialmente

### Respuesta a las preguntas de verificación

| Pregunta | Respuesta |
|---|---|
| i. ¿Qué representa una fila de la tabla de hechos? | **No está declarado.** Por las llaves se infiere "una oferta de un plan, de un tipo de beneficio, en un área de servicio, en una fecha". Sin embargo, la fuente F3 también identifica el nivel de servicio (`idNivelServicio_T`) y el modelo no lo incluye, por lo que no puede determinarse si la fila es por nivel de servicio o si los niveles se colapsan. La PK `ID_OfertaPlanes` es un identificador técnico y no una clave compuesta que declare el grano. |
| ii. ¿El grano tiene sentido para un proceso que se realiza una vez al año? | **Sí, con matiz.** `Dim_Fecha` permite derivar el año (`Anio`, `dbml:108`) y el hecho guarda la fecha de la oferta. El grano es más fino que el anual (fecha completa), lo cual es compatible con el proceso anual, pero el modelo no declara que la fecha represente la oferta anual ni que el año sea la unidad de análisis. |
| iii. ¿Todas las llaves y medidas pertenecen a ese nivel de detalle? | **Parcialmente.** Las 7 llaves foráneas y las 4 medidas son coherentes con el nivel plan-beneficio-área-fecha. El problema es que falta la llave de nivel de servicio que forma parte de la identidad de la fila en F3; si existen varias filas por nivel para una misma combinación plan-beneficio-área-fecha, el modelo las colapsa o las duplica sin control. |

### Evidencia

- Columnas del hecho: `ID_OfertaPlanes` (PK), `ID_Fecha`, `ID_Proveedor`, `ID_Plan`, `ID_TipoBeneficio`, `ID_AreaDeServicio`, `ID_CondicionCopago`, `ID_CondicionCoseguro`, `ValorCopago`, `ValorCoseguro`, `LimiteCuantitativo`, `CantidadOfertas` (`dbml:153-164`).
- La nota de la tabla de hechos no define el grano; solo describe las relaciones y la ambigüedad de nullability (`dbml:166-173`).
- El diccionario de F3 incluye `idPlan_T`, `idTipoBeneficio_T`, `idAreaDeServicio_T`, `idCondicionesDePagoCopago_T`, `idCondicionesDePagoCoseguro_T`, `idProveedor_T`, `Fecha`, `idNivelServicio_T`, `valorCopago`, `valorCoseguro` y `cantidadLimite`.
- El caso define el proceso como anual (`caso:5-7`) y los análisis piden rangos de años (`caso:19-23`).
- No se declara una restricción de unicidad sobre la combinación de llaves del hecho; solo existe la PK subrogada.

### Análisis

El grano es inferible, pero no está definido de manera inequívoca. La ausencia de una declaración explícita y de una clave única compuesta es un hallazgo, porque dos implementaciones distintas podrían cargar el mismo hecho con granos diferentes (con o sin nivel de servicio, con o sin versión de dimensión) y producir conteos distintos. Además, la omisión de `idNivelServicio_T` puede provocar pérdida de detalle o duplicación de medidas si la fuente tiene más de un nivel de servicio por plan-beneficio-área-fecha.

La existencia de `CantidadOfertas` refuerza la ambigüedad: no está claro si "oferta" es la fila del hecho o el plan; una fila por beneficio y área no equivale a una oferta de plan.

### Impacto sobre los análisis requeridos

- Los conteos de planes y de ofertas (2.b, 2.c, 3.a) pueden variar según cómo se interprete la fila.
- Si el nivel de servicio se colapsa, los valores de copago, coseguro y límite podrían mezclarse o perderse.
- Sin una clave única declarada, no se puede garantizar la ausencia de duplicados, lo que afecta todos los análisis.

### Recomendación

Declarar explícitamente el grano del hecho y la combinación de llaves que lo identifica. Definir si `idNivelServicio_T` forma parte del grano; si forma parte, incorporarlo como llave (y evaluar su dimensión o su tratamiento como atributo degenerado). Documentar que `CantidadOfertas` cuenta filas del grano y no planes distintos.

---

## C3. Hechos y medidas

**Parte del modelo relacionada:** medidas `ValorCopago`, `ValorCoseguro`, `LimiteCuantitativo`, `CantidadOfertas`.

**Resultado:** Cumple parcialmente

### Respuesta a las preguntas de verificación

| Pregunta | Respuesta |
|---|---|
| i. ¿Las medidas pertenecen al proceso representado? | **Sí, en su mayoría.** `ValorCopago`, `ValorCoseguro` y `LimiteCuantitativo` provienen de la fuente de planes-beneficio (F3: `valorCopago`, `valorCoseguro`, `cantidadLimite`) y describen la oferta. `CantidadOfertas` no existe en la fuente: es una medida derivada (constante 1 por fila) y su significado depende del grano. |
| ii. ¿Las medidas pueden duplicarse al cambiar el nivel de análisis (por ejemplo, de área a estado)? | **Sí, hay riesgo alto.** Un mismo plan puede ofrecerse en varias áreas del mismo estado; cada área genera una fila y, al agregar por estado, el plan y sus valores se repiten. También se duplican si se suman versiones SCD de la misma área o del mismo tipo de beneficio sin filtrar por vigencia. |
| iii. ¿Las medidas son aditivas, semiaditivas o no aditivas? | **No está declarado y la clasificación es mixta.** `ValorCopago` y `ValorCoseguro` no son aditivas (se comparan, promedian o toman mínimo/máximo; sumarlas no tiene sentido). `LimiteCuantitativo` tampoco es aditiva. `CantidadOfertas` sería aditiva solo al grano declarado, pero no equivale a "cantidad de planes". En el DBML todas las columnas son `varchar`, por lo que además no hay tipo numérico que permita agregarlas directamente. |

### Evidencia

- Medidas en el hecho: `dbml:161-164`.
- Origen en el diccionario de F3: `valorCopago`, `valorCoseguro`, `cantidadLimite`.
- `Dim_AreaDeServicio.Estado` (`dbml:132`) permite agregar por estado, lo que expone la duplicación plan×área.
- `Dim_TipoBeneficio` y `Dim_AreaDeServicio` tienen `FechaInicio`, `FechaFin` y `EsActual` (`dbml:72-74`, `:134-136`), lo que implica varias filas por miembro natural si no se filtra la versión vigente.
- La regla de negocio 6 fija máximos de copago y coseguro para 2018 (`caso:40`), lo que sugiere escalas distintas y refuerza que no son magnitudes sumables.
- La regla de negocio 2 indica que el límite sin valor o en cero se reemplaza por 333 (`caso:36`); el modelo no documenta ese tratamiento.

### Análisis

Las tres medidas de valor son correctas como atributos del proceso, pero el modelo no declara su naturaleza no aditiva y las almacena como texto. `CantidadOfertas` es una medida técnica de conteo, no un hecho del negocio, y su semántica es ambigua: puede confundirse con cantidad de planes cuando en realidad cuenta filas (plan-beneficio-área). El riesgo de duplicación al pasar de área a estado es real y estructural: la relación entre plan y área es de muchos a muchos y el hecho la materializa en filas separadas.

### Impacto sobre los análisis requeridos

- Sumar copagos o coseguros por estado o por proveedor produce totales sin significado y puede inducir conclusiones erróneas sobre competencia desleal.
- Contar `CantidadOfertas` o filas para responder "cuántos planes" infla el resultado; por ejemplo, un plan con cinco beneficios en tres áreas del mismo estado se contaría quince veces.
- Agregar por estado sin deduplicar planes puede exagerar las concentraciones (3.a y 3.b).
- Si no se filtra `EsActual` o la vigencia, las versiones SCD duplican los valores.

### Recomendación

Documentar la clasificación de cada medida (no aditiva, aditiva) y su unidad. Definir que el conteo de planes se hace con `COUNT(DISTINCT ID_Plan)` y no con la suma de filas. Establecer la regla de filtrado de versiones SCD antes de agregar. Tipar numéricamente las medidas. Documentar el tratamiento del límite 333 y su efecto en promedios y comparaciones.

---

## C4. Dimensiones y atributos

**Parte del modelo relacionada:** `Dim_Plan`, `Dim_TipoBeneficio`, `Dim_CondicionPago`, `Dim_Fecha`, `Dim_Proveedor`, `Dim_AreaDeServicio`.

**Resultado:** Cumple parcialmente

### Respuesta a las preguntas de verificación

| Pregunta | Respuesta |
|---|---|
| i. ¿Cada dimensión agrupa atributos de un mismo concepto? | **Sí en general, con excepciones.** Plan, tipo de beneficio, condición de pago, fecha, proveedor y área son conceptos distintos y están separados. Pero `Dim_Plan` no tiene atributos descriptivos (solo dos identificadores), `Dim_AreaDeServicio` mezcla área con estado sin la jerarquía geográfica completa, y `Dim_CondicionPago` mezcla la condición con su tipo (Copago/Coseguro), lo que se cruza con el uso por roles. |
| ii. ¿Cada dimensión tiene llave subrogada y llave natural de la fuente? | **Formalmente sí, pero con debilidades.** Todas las dimensiones tienen `ID_<Dim>` como PK y un `Id<Dim>` adicional que parece ser la llave natural. Sin embargo, el DBML no declara el segundo identificador como `unique` ni `not null`, los nombres no coinciden con las llaves de la fuente (`idPlan_T`, `idTipoBeneficio_T`, etc.) y `Dim_Proveedor` no tiene tabla de origen en el diccionario. `Dim_Fecha` usa `Fecha` como llave natural, lo cual es válido pero no se declara como única. |
| iii. ¿Existe la dimensión Fecha con el nivel año, que es el que más se usa en los análisis? | **Sí.** `Dim_Fecha` contiene `Fecha`, `Dia`, `Mes` y `Anio` (`dbml:104-108`). |
| iv. ¿Hay atributos descriptivos ubicados por error en la tabla de hechos? | **No.** El hecho contiene llaves y medidas; `ID_OfertaPlanes` es una PK subrogada, no un atributo descriptivo. |

### Verificación de atributos contra el diccionario

| Dimensión | Atributo del modelo | Campo en F1-F4 | Resultado |
|---|---|---|---|
| `Dim_Plan` | `ID_Plan`, `IdPlan` | `idPlan_T` (F3) | Existe la llave; no hay atributos descriptivos disponibles en las fuentes. |
| `Dim_Proveedor` | `ID_Proveedor`, `IdProveedor` | `idProveedor_T` (F3) | Existe solo el identificador; no hay tabla de proveedores ni nombre. |
| `Dim_Proveedor` | `NombreProveedor` | **No existe en el diccionario** | **Atributo sin respaldo en F1-F4.** |
| `Dim_TipoBeneficio` | `NombreBeneficio` | `Nombre` (F2) | Existe, con nombre distinto. |
| `Dim_TipoBeneficio` | `Condiciones` | **No hay campo "Condiciones"**; F2 tiene `EsEHB`, `EstaCubiertoPorSeguro`, `TieneLimiteCuantitativo` y los dos `Excluido...` | **Origen ambiguo.** No puede determinarse a qué campo corresponde. |
| `Dim_TipoBeneficio` | `UnidadLimite` | `UnidadDelLimite` (F2) | Existe, con nombre distinto. |
| `Dim_TipoBeneficio` | `FechaInicio`, `FechaFin`, `EsActual` | No existen como tales; F2 tiene `Fecha` (fecha en que se define) | Son atributos derivados para SCD; su regla de derivación no está documentada. |
| `Dim_CondicionPago` | `TipoCondicion` | `Tipo` (F4) | Existe, con nombre distinto. |
| `Dim_CondicionPago` | `Descripcion` | `Descripcion` (F4) | Existe. |
| `Dim_AreaDeServicio` | `NombreArea` | `NombreAreaDeServicio` (F1) | Existe, con nombre distinto. |
| `Dim_AreaDeServicio` | `Estado` | `Estado` (F1) | Existe. |
| `Dim_AreaDeServicio` | `FechaInicio`, `FechaFin`, `EsActual` | F1 tiene `Fecha` (fecha de creación) | Derivados para SCD; regla no documentada. |
| `Dim_AreaDeServicio` | **(ausentes)** `idGeografía_T`, `Condado`, `PoblacionAct`, `Area`, `Densidad` | Existen en F1 | **Atributos de F1 no incorporados**, necesarios para 3.a y 3.b. |
| `Dim_Fecha` | `Fecha`, `Dia`, `Mes`, `Anio` | Derivados de `Fecha` (F3) | Correcto como dimensión de fecha. |
| **(dimensión ausente)** | `idNivelServicio_T` | Existe en F3 | **Sin dimensión ni atributo**; afecta el grano. |

### Evidencia

- Definiciones de dimensiones en `dbml:53-146`.
- El diccionario de F1 contiene nueve campos de área, geografía y población; el modelo solo conserva dos descriptivos (`NombreArea`, `Estado`).
- El diccionario de F2 contiene nueve campos; el modelo conserva `Nombre`, `UnidadDelLimite` y agrega `Condiciones`, que no aparece en el diccionario.
- El diccionario de F4 contiene `idCondicionesDePago_T`, `Descripcion` y `Tipo`.
- El diccionario no contiene ninguna tabla de proveedores ni de niveles de servicio.
- La nota del modelo reconoce que no se distingue la llave subrogada de la natural (`dbml:81-82`, y notas equivalentes en las demás dimensiones).

### Análisis

La separación de conceptos es correcta, pero hay tres problemas de fondo. Primero, `Dim_AreaDeServicio` no contiene la información geográfica ni demográfica que F1 sí ofrece, lo que limita los análisis. Segundo, `NombreProveedor` no tiene respaldo en el diccionario: el modelo incorpora un atributo que no puede cargarse desde F1-F4. Tercero, `Condiciones` es un atributo ambiguo: el diccionario no tiene un campo con ese nombre y F2 contiene varios campos booleanos que podrían corresponder; sin una regla de mapeo, el atributo no es trazable.

Además, aunque cada dimensión tiene dos identificadores, el modelo no declara cuál es la llave subrogada y cuál la natural; el DBML solo marca el primero como PK y deja el segundo como columna ordinaria. Esto es una debilidad de definición, no solo de nombres.

### Impacto sobre los análisis requeridos

- La falta de condado y población impide 3.a (por condado) y 3.b.
- La falta de nombre y grupo de proveedores reduce 1.a a una comparación por identificador.
- `Condiciones` sin origen definido puede cargarse de forma inconsistente y afectar filtros por tipo de beneficio.
- `NombreProveedor` no podrá poblarse con F1-F4 y quedará vacío o inventado.
- La ausencia de `idNivelServicio_T` puede alterar el grano y, con ello, los conteos.

### Recomendación

Completar la dimensión de área con la jerarquía geográfica y la población de F1, o crear una dimensión geográfica separada. Resolver el origen de `NombreProveedor` (incorporar una fuente o eliminarlo del alcance) y documentar la ausencia de agrupación de proveedores. Definir el mapeo exacto de `Condiciones` a los campos de F2 y declarar las llaves naturales como únicas y no nulas. Documentar el tratamiento de `idNivelServicio_T`.

---

## C5. Relaciones y llaves foráneas

**Parte del modelo relacionada:** referencias `e0` a `e6` y la doble relación con `Dim_CondicionPago`.

**Resultado:** Cumple parcialmente

### Respuesta a las preguntas de verificación

| Pregunta | Respuesta |
|---|---|
| i. ¿La tabla de hechos tiene una llave foránea por cada dimensión relacionada? | **Sí.** El hecho tiene siete columnas FK para seis dimensiones: fecha, proveedor, plan, tipo de beneficio, área y dos condiciones (copago y coseguro). Las referencias `e0` a `e6` están declaradas (`dbml:183-203`). |
| ii. ¿La cardinalidad es 1:N desde cada dimensión hacia el hecho? | **Sí en la definición.** Las referencias usan `>` (muchos hechos por cada fila de dimensión), equivalente a 1:N desde la dimensión. Sin embargo, el diagrama marca el lado de la dimensión como obligatorio (`ERmandOne`), y el DBML no expresa nullability: si un plan no tiene copago o coseguro, la FK podría quedar nula y la cardinalidad obligatoria no se cumpliría. Tampoco está modelado el miembro desconocido de área (Id = 0) que el caso exige para no perder registros huérfanos. |
| iii. ¿La condición de pago, que se usa para el copago y para el coseguro, está modelada correctamente con roles? | **Parcialmente.** El patrón es el correcto: una sola `Dim_CondicionPago`, dos columnas FK (`ID_CondicionCopago`, `ID_CondicionCoseguro`) y dos referencias con nombres de rol (`e2_copago`, `e3_coseguro`). El problema es que la dimensión conserva `TipoCondicion` (Copago/Coseguro/Anticipado) y nada garantiza que la fila usada en el rol copago sea de tipo Copago ni que la usada en el rol coseguro sea de tipo Coseguro. Además, el diccionario admite el valor "Anticipado", que no corresponde a ninguno de los dos roles. |

### Evidencia

- Columnas FK del hecho: `dbml:154-160`.
- Referencias: `Ref e0` a `Ref e6` (`dbml:183-203`), incluidas `e2_copago` (`:189`) y `e3_coseguro` (`:194`).
- `Dim_CondicionPago` contiene `TipoCondicion` y `Descripcion` (`dbml:89-90`).
- El diccionario de F4 define `Tipo` como "Copago o Coseguro o Anticipado".
- La regla de negocio 7 y la indicación de RaSa piden dejar el tipo solo en Copago y Coseguro (`caso:41`, `caso:47`), lo que confirma que el valor "Anticipado" debe depurarse, pero el modelo no lo refleja.
- El caso exige crear el área desconocida con Identificador = 0 (`caso:44`); el modelo no lo documenta ni lo prevé como miembro de dimensión.
- El diagrama usa `ERmandOne` en el extremo de la dimensión y `ERmany` en el hecho (por ejemplo, `modelo_ofertaplanes.drawio:52`), lo que el DBML representa como many-to-one.

### Análisis

Las relaciones están completas para las dimensiones existentes y la cardinalidad declarada es la esperada. El punto débil es el rol de la condición de pago: el patrón de dos FKs es correcto, pero la presencia de `TipoCondicion` en la misma tabla crea una redundancia que puede contradecir el rol. Si una fila de tipo Coseguro se usa como copago, el modelo no lo impide y el análisis 1.a mezclaría conceptos. La obligatoriedad marcada en el diagrama también es riesgosa: la fuente F4 incluye condiciones "NoAplica" y "Anticipado", y no se sabe si todos los planes tienen ambas condiciones; forzar la relación puede generar errores de carga o valores inventados.

La falta del miembro desconocido de área es una limitación de integridad referencial: los `IdAreaDeServicio` de F3 que no existen en F1 no podrán relacionarse, y el caso pide explícitamente no omitirlos.

### Impacto sobre los análisis requeridos

- Una asignación cruzada de roles invalida la comparación de copago y coseguro (1.a) y cualquier análisis de condiciones.
- Si la FK obligatoria no puede satisfacerse, se pierden ofertas o se fuerzan valores por defecto, afectando 2.a, 2.c y 3.a.
- Sin el área desconocida, las ofertas con área no catalogada desaparecen o rompen la relación, distorsionando la cobertura.

### Recomendación

Documentar y validar en la carga que `ID_CondicionCopago` apunte a una fila de tipo Copago y `ID_CondicionCoseguro` a una de tipo Coseguro; considerar separar las vistas por rol o eliminar la ambigüedad de `TipoCondicion`. Definir la nullability real de las FKs. Documentar el miembro Desconocido (Id = 0) en `Dim_AreaDeServicio` y la regla de asignación para áreas no encontradas.

---

## C6. Consistencia del modelo

**Parte del modelo relacionada:** nombres de tablas y columnas, atributos repetidos, conexión de dimensiones.

**Resultado:** Cumple parcialmente

### Respuesta a las preguntas de verificación

| Pregunta | Respuesta |
|---|---|
| i. ¿Las tablas y columnas siguen una misma convención de nombres? | **Parcialmente.** Las tablas siguen el prefijo `Dim_` y `Hecho_`, lo cual es consistente. En columnas conviven dos convenciones: llaves subrogadas `ID_<Nombre>` y llaves naturales `Id<Nombre>`; la diferencia depende solo de una mayúscula y un guion bajo, lo que es frágil. Los atributos descriptivos usan PascalCase sin guion bajo. Además, los nombres no coinciden con la fuente (`IdPlan` vs `idPlan_T`, `NombreArea` vs `NombreAreaDeServicio`, `LimiteCuantitativo` vs `cantidadLimite`, `Anio` sin tilde). |
| ii. ¿Hay atributos repetidos en más de una dimensión? | **Sí.** `FechaInicio`, `FechaFin` y `EsActual` aparecen en `Dim_TipoBeneficio` y en `Dim_AreaDeServicio`. La repetición está justificada por el manejo de historia en ambas dimensiones, pero no hay una convención que las prefije por dimensión y el nombre `Fecha` de `Dim_Fecha` convive con esos atributos, lo que puede confundir las uniones. |
| iii. ¿Todas las dimensiones están conectadas al hecho? | **Sí.** Las seis dimensiones tienen al menos una referencia al hecho; `Dim_CondicionPago` tiene dos. |

### Evidencia

- Nombres de tablas y columnas en `dbml:53-164`.
- Atributos SCD repetidos: `dbml:72-74` y `dbml:134-136`.
- Nombres de la fuente en el diccionario: `idPlan_T`, `idTipoBeneficio_T`, `idAreaDeServicio_T`, `idCondicionesDePago_T`, `idProveedor_T`, `NombreAreaDeServicio`, `UnidadDelLimite`, `cantidadLimite`.
- Tipos: todas las columnas son `varchar`, incluso las medidas (`dbml:161-164`). La nota inicial aclara que el diagrama no declaraba tipos y que `varchar` se usó para cumplir la sintaxis de DBML (`dbml:11-12`).
- Relaciones: `dbml:183-203`.

### Análisis

La estructura es consistente (estrella simple, todas las dimensiones conectadas), pero la convención de nombres no está unificada y los tipos no aportan semántica: las medidas están en texto, por lo que no pueden agregarse sin conversión. La repetición de atributos SCD es esperable, pero debería nombrarse de forma que se distinga la dimensión de origen (por ejemplo, prefijos por dimensión) y documentarse. La ambigüedad entre `ID_` e `Id` es especialmente riesgosa porque un cambio de mayúsculas puede alterar el significado.

### Impacto sobre los análisis requeridos

- Nombres ambiguos entre llave subrogada y natural pueden provocar uniones incorrectas y duplicados.
- Medidas en texto impiden que las herramientas de BI las agreguen directamente.
- Atributos SCD repetidos sin prefijo pueden confundir la versión que se está filtrando, afectando los análisis por año.

### Recomendación

Unificar la convención de nombres de columnas (llave subrogada, llave natural, atributos descriptivos y atributos SCD) y documentarla. Tipar las medidas como numéricas. Prefijar los atributos de vigencia por dimensión o documentar su semántica. Mantener la coherencia con los nombres de la fuente mediante una tabla de mapeo.

---

## C7. Historia de los atributos

**Parte del modelo relacionada:** `Dim_TipoBeneficio`, `Dim_AreaDeServicio`, `Dim_Fecha` y las relaciones del hecho con las versiones.

**Resultado:** Cumple parcialmente

### Respuesta a las preguntas de verificación

| Pregunta | Respuesta |
|---|---|
| i. ¿Se indica qué dimensiones guardan historia y cuáles no, y por qué? | **No formalmente.** El modelo no declara el tipo de SCD de cada dimensión ni su justificación. Solo se infiere historia en `Dim_TipoBeneficio` y `Dim_AreaDeServicio` por la presencia de `FechaInicio`, `FechaFin` y `EsActual`; las demás dimensiones no tienen atributos de vigencia, pero tampoco se declara que sean SCD tipo 1 o estáticas. |
| ii. ¿Las dimensiones que cambian por año (tipos de beneficio y áreas de servicio) tienen fechas de vigencia? | **Sí, los atributos existen.** Ambas tienen `FechaInicio`, `FechaFin` y `EsActual`. Pero la fuente F1 solo tiene `Fecha` (fecha de creación) y F2 solo tiene `Fecha` (fecha en que se define el tipo de beneficio); el modelo no documenta cómo se derivan las fechas de vigencia ni si corresponden al año completo. |
| iii. ¿El hecho apunta a la versión que estaba vigente en el año de la oferta? | **No puede garantizarse con el modelo.** El hecho guarda el surrogate de la dimensión (`ID_TipoBeneficio`, `ID_AreaDeServicio`), de modo que estructuralmente puede apuntar a cualquier versión. No existe una regla declarada que obligue a elegir la versión cuya `FechaInicio`/`FechaFin` contenga el año de la oferta, ni una relación entre `Dim_Fecha` y las vigencias. La corrección depende enteramente de la carga. |

### Evidencia

- Atributos SCD en `Dim_TipoBeneficio`: `dbml:72-74`.
- Atributos SCD en `Dim_AreaDeServicio`: `dbml:134-136`.
- La nota del modelo reconoce que el diagrama no rotula el tipo de SCD (`dbml:77-79`, `:139-141`).
- `Dim_Fecha` contiene `Anio` (`dbml:108`), pero no hay ninguna relación entre `Dim_Fecha` y las fechas de vigencia de las dimensiones.
- Las referencias `e1` y `e6` solo unen el hecho con la dimensión; no incluyen condición temporal (`dbml:186`, `:203`).
- El caso pide historia de los atributos (`caso:10-11`) y la regla 5 confirma que las condiciones y la unidad de límite pueden cambiar por año (`caso:39`).
- El diccionario de F1 tiene `Fecha` como fecha de creación; el de F2 tiene `Fecha` como fecha de definición.

### Análisis

El modelo incorpora los atributos necesarios para una dimensión con historia (SCD tipo 2) en las dos dimensiones que el negocio identifica como cambiantes por año. Sin embargo, no declara el tipo de SCD, no justifica por qué las demás dimensiones no guardan historia y no define cómo se calculan las fechas de vigencia a partir de una única fecha de origen. El punto más crítico es la asociación hecho-versión: el surrogate permite apuntar a una versión, pero el modelo no impone que sea la vigente en el año de la oferta. Si la carga asigna siempre la versión actual (`EsActual`), los análisis históricos quedarán mal.

También hay una tensión no resuelta: el proceso es anual y la fuente de áreas solo tenía 2017 y 2018 y faltaba 2019 (`caso:38`), mientras que el modelo usa fechas completas. Sin una regla de derivación, no se sabe si la vigencia es el año calendario, la fecha de creación o un rango construido por el ETL.

### Impacto sobre los análisis requeridos

- Si el hecho apunta a la versión actual en lugar de la vigente, los análisis por rango de años (2.a, 3.a) y las comparaciones entre años muestran atributos que no correspondían a la oferta.
- Sin historia correcta, no se puede comparar la evolución de condiciones y unidades de límite por tipo de beneficio, que es uno de los objetivos del caso.
- La duplicación de versiones sin una regla de filtrado puede inflar los conteos de cobertura y concentración.

### Recomendación

Declarar explícitamente el tipo de historia de cada dimensión y su justificación. Documentar la regla de derivación de `FechaInicio`/`FechaFin`/`EsActual` a partir de la `Fecha` de la fuente y la granularidad anual. Definir y documentar la regla de búsqueda de la versión vigente en el año de la oferta (comparando el año de `Dim_Fecha` con el rango de vigencia) y validarla en la carga. Declarar el tratamiento de las dimensiones sin historia.

---

## Tabla resumen

| Criterio | Resultado | Hallazgo principal |
|---|---|---|
| **C1. Cumplimiento de los análisis requeridos** | Cumple parcialmente | 3.a no puede analizarse por condado y 3.b no es resoluble porque la dimensión de área no incorpora condado ni población, aunque ambos existen en F1. |
| **C2. Definición del grano** | Cumple parcialmente | El grano no está declarado y no puede determinarse de manera inequívoca; falta `idNivelServicio_T`, que forma parte de la identidad de la fila en F3. |
| **C3. Hechos y medidas** | Cumple parcialmente | No se declara la aditividad; sumar copagos/coseguros no tiene sentido y el conteo de planes se infla al agregar de área a estado. |
| **C4. Dimensiones y atributos** | Cumple parcialmente | `NombreProveedor` no existe en F1-F4, `Condiciones` no tiene campo fuente identificable y faltan los atributos geográficos y demográficos de F1. |
| **C5. Relaciones y llaves foráneas** | Cumple parcialmente | El patrón de roles es correcto, pero `TipoCondicion` no garantiza la correspondencia rol-tipo y no se documenta el área desconocida (Id = 0). |
| **C6. Consistencia del modelo** | Cumple parcialmente | Conviven dos convenciones de llaves (`ID_` e `Id`), los atributos SCD se repiten sin prefijo y todas las medidas están tipadas como texto. |
| **C7. Historia de los atributos** | Cumple parcialmente | Existen fechas de vigencia, pero no se declara el tipo de SCD ni la regla que asegura que el hecho apunta a la versión vigente en el año de la oferta. |

---

## Hallazgos principales

Ordenados de mayor a menor impacto sobre los objetivos del caso.

1. **La dimensión de área de servicio no permite responder 3.a ni 3.b.** `Dim_AreaDeServicio` solo tiene `NombreArea` y `Estado`; F1 aporta `idGeografía_T`, `Condado`, `PoblacionAct`, `Area` y `Densidad`. Sin condado no se puede analizar la concentración por condado y sin población no se puede comparar la concentración con los habitantes. Es el hallazgo de mayor impacto porque deja sin respuesta dos de los seis análisis requeridos. Además, la población de F1 es actual y no histórica, lo que limita el análisis por rango de años.

2. **El grano del hecho no está definido y omite el nivel de servicio.** El modelo no declara qué representa una fila ni una clave única compuesta; la PK `ID_OfertaPlanes` es solo un identificador técnico. F3 incluye `idNivelServicio_T` y el modelo no lo representa, por lo que no se sabe si el nivel de servicio forma parte del grano o se colapsa. Esto afecta todos los conteos y puede producir duplicación o pérdida de detalle.

3. **El rol copago/coseguro no está asegurado.** El patrón de una dimensión con dos FKs es correcto, pero `Dim_CondicionPago.TipoCondicion` no se usa para validar que la fila del rol copago sea de tipo Copago y la del rol coseguro sea de tipo Coseguro. El diccionario admite además el valor "Anticipado", que no corresponde a ninguno de los dos roles. Una asignación cruzada invalida el análisis 1.a.

4. **La historia (SCD) está insinuada pero no definida.** `Dim_TipoBeneficio` y `Dim_AreaDeServicio` tienen `FechaInicio`, `FechaFin` y `EsActual`, pero el modelo no declara el tipo de SCD, no justifica las dimensiones sin historia y no define cómo se derivan las vigencias desde la única `Fecha` de la fuente. Tampoco existe una regla que garantice que el hecho apunta a la versión vigente en el año de la oferta; si la carga usa `EsActual`, los análisis históricos quedan mal.

5. **Las medidas no tienen aditividad declarada y el conteo se infla al agregar.** `ValorCopago`, `ValorCoseguro` y `LimiteCuantitativo` no son aditivas, pero el modelo no lo dice y las almacena como texto. `CantidadOfertas` cuenta filas, no planes; al pasar de área a estado, un plan ofrecido en varias áreas se repite. Los análisis de concentración (3.a, 3.b) y de competencia (1.a) pueden arrojar cifras engañosas.

6. **El proveedor no tiene respaldo completo en las fuentes.** F3 solo aporta `idProveedor_T`; no hay tabla de proveedores en el diccionario, no hay nombre ni agrupación. `Dim_Proveedor.NombreProveedor` no puede poblarse desde F1-F4 y el análisis 1.a no puede identificar proveedores ni analizar grupos, aunque el enunciado los menciona.

7. **Hay atributos sin trazabilidad y llaves naturales débiles.** `Condiciones` no corresponde a ningún campo del diccionario (F2 tiene varios booleanos que podrían ser su origen) y los segundos identificadores (`IdPlan`, `IdProveedor`, etc.) no están declarados como únicos ni no nulos. Esto impide auditar la carga y puede generar duplicados en las dimensiones.

8. **Faltan reglas de negocio documentadas en el modelo.** El caso exige un área desconocida con Id = 0 y el reemplazo del límite cuantitativo vacío o cero por 333; el modelo no menciona ninguna de las dos. La primera afecta la integridad referencial y la cobertura; la segunda afecta la interpretación de `LimiteCuantitativo` y cualquier promedio o comparación de límites.
