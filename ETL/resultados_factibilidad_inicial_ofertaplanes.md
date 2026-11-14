# Resultados de factibilidad práctica — modelo inicial OfertaPlanes

**Base analizada:** `modelo_inicial_ofertaplanes.sqlite`  
**Modelo de referencia:** `modelo_inicial_ofertaplanes.dbml`  
**Caso:** `caso_rasa_ofertaplanes.md`  
**Consultas ejecutables:** `consultas_factibilidad_inicial_ofertaplanes.sql`

## 1. Alcance y método

Se evaluaron los seis análisis del caso y un conjunto de requerimientos derivados. Todas las consultas se ejecutaron contra la base entregada, sin modificar su estructura ni sus datos. La base conserva 7 tablas y los conteos originales: `Dim_Fecha` 1095, `Dim_Proveedor` 6, `Dim_Plan` 12, `Dim_CondicionPago` 8, `Dim_TipoBeneficio` 18, `Dim_AreaDeServicio` 25 y `Hecho_OfertaPlanes` 175. `PRAGMA integrity_check` devolvió `ok` y `PRAGMA foreign_key_check` no devolvió filas.

Las medidas de `Hecho_OfertaPlanes` están almacenadas como `TEXT`; por eso todas las agregaciones usan `CAST(... AS REAL)` o `CAST(... AS INTEGER)`. Las dimensiones `Dim_TipoBeneficio` y `Dim_AreaDeServicio` son SCD2: el hecho guarda la clave subrogada de la versión vigente, de modo que unir por `ID_TipoBeneficio` o `ID_AreaDeServicio` recupera la versión histórica correcta. Unir por la clave natural (`IdTipoBeneficio`, `IdAreaDeServicio`) duplicaría filas, porque hay 18 versiones para 6 tipos de beneficio y 25 versiones para 9 áreas naturales (8 áreas más la desconocida).

**Supuestos usados en las consultas**

1. El porcentaje de diferencia de 1.a se calcula sobre el menor de los dos valores comparados. El caso no define la base; con otra base el resultado cambia cerca del umbral del 20 %. Los pares con base 0 quedan fuera mediante `NULLIF`.
2. El universo de áreas de cobertura es el conjunto de áreas naturales con una versión vigente en el año, excluyendo el área desconocida (`IdAreaDeServicio = '0'`). Si se contara solo las áreas presentes en los hechos, la cobertura sería artificialmente 100 %.
3. “Cobertura total de los proveedores” se evaluó en dos lecturas: cobertura colectiva (todos los proveedores juntos cubren todas las áreas) y cobertura individual (cada proveedor cubre todas las áreas).
4. Los conteos de planes usan `COUNT(DISTINCT ID_Plan)`. Contar filas de oferta sobrecuenta porque un plan puede aparecer en varias áreas, beneficios o versiones.

## 2. Resumen ejecutivo

| Requerimiento | Clasificación | Facilidad | Evidencia principal |
|---|---|---|---|
| 1.a Competencia por copago/coseguro > 20 % | **Factible** | Media | 86 pares de planes en el mismo año, beneficio y área |
| 2.a Cobertura de planes por áreas y años | **Factible** | Media | 7/8 áreas en 2017 (87,5 %); 6/8 en 2018 y 2019 (75 %) |
| 2.b Cobertura total de proveedores | **Factible** | Media | Ningún proveedor cubre las 8 áreas; cobertura colectiva máxima 87,5 % |
| 2.c Áreas con menos de dos proveedores | **Factible** | Media | A05 y A06 con 1 proveedor; A07 sin planes; A08 con 1 en 2017 y 0 después |
| 3.a Planes por área/estado/condado | **Parcialmente factible** | Alta en área/estado; no aplica en condado | 19 filas área-año; 7 filas estado-año; no existe columna Condado |
| 3.b Planes vs. población | **No factible** | No aplica | No existen columnas de condado ni población en ninguna tabla |
| Evolución anual de copago/coseguro | **Factible** | Alta | Promedios 2017–2019 y máximos 2018 |
| Versión histórica de beneficio/área | **Factible** | Alta, con riesgo de duplicación | TB01 cambia de unidad; A02 cambia de nombre |
| Área desconocida y límite 333 | **Factible** | Alta | 4 filas con área 0; 18 filas con límite 333 |
| Cobertura por proveedor | **Factible** | Media | 18 filas proveedor-año; máximo 4/8 áreas |
| Planes por área/estado y duplicación | **Factible** | Media | 25 filas vs. 10 planes distintos en Estado Centro 2017 |
| Población, si el modelo la almacena | **No factible** | No aplica | Búsqueda de columnas devuelve 0 filas |

## 3. Análisis obligatorios

### 3.1. 1.a — Competencia desleal por diferencias mayores al 20 %

**Pregunta analítica.** Para un año y un tipo de beneficio, ¿qué pares de planes de proveedores distintos, ofrecidos en la misma área, presentan diferencias mayores al 20 % en copago o en coseguro?

**Tablas y atributos necesarios.** `Hecho_OfertaPlanes` (`ID_Fecha`, `ID_Proveedor`, `ID_Plan`, `ID_TipoBeneficio`, `ID_AreaDeServicio`, `ValorCopago`, `ValorCoseguro`), `Dim_Fecha` (`Anio`), `Dim_TipoBeneficio` (`IdTipoBeneficio`), `Dim_AreaDeServicio` (`IdAreaDeServicio`). Opcionalmente `Dim_Proveedor` (`NombreProveedor`) para mostrar nombres y `Dim_CondicionPago` para validar los roles.

**SQL.** `Q1a` construye una CTE con el promedio de copago y coseguro por año, beneficio, área, proveedor y plan; luego hace un auto-join de esa CTE consigo misma por año, beneficio y área, exigiendo proveedores distintos (`o1.proveedor < o2.proveedor`) y calculando la diferencia relativa con `NULLIF`. Para acotar a un proveedor o grupo, se agrega un filtro sobre `o1.proveedor`/`o2.proveedor` en el `WHERE` final. `Q1a-resumen` cuenta los pares. `Q1b` muestra los valores crudos de 2018 para TB01 en A01 y A02.

**Ejecución.** La consulta se ejecutó sin errores y devolvió **86 pares** que superan el 20 % en copago o coseguro. Algunos casos concretos:

| Año | Beneficio | Área | Proveedor 1 / Plan | Copago | Coseguro | Proveedor 2 / Plan | Copago | Coseguro | Diferencia |
|---|---|---|---|---|---|---|---|---|---|
| 2018 | TB01 | A01 | PRV01 / PLN001 | 100 | 10 | PRV02 / PLN003 | 200 | 10 | copago 100 % |
| 2018 | TB01 | A02 | PRV01 / PLN001 | 100 | 10 | PRV02 / PLN003 | 100 | 30 | coseguro 200 % |

El segundo caso muestra la ambigüedad del cálculo: con base en el menor (10) la diferencia es 200 %; con base en el mayor (30) es 66,67 %; con base en el promedio (20) es 100 %. Las tres lecturas superan el 20 %, pero cerca del umbral la clasificación puede cambiar. Además, los 86 pares no son 86 hallazgos independientes: un mismo proveedor o plan puede aparecer en varios pares, y un proveedor con varios planes genera varios pares.

El caso no exige que los planes comparados estén en la misma área; se agregó el área como control porque comparar valores de áreas distintas mezcla mercados. Si se elimina ese control, la consulta sigue siendo posible, pero la interpretación de “competencia” se vuelve más discutible.

**Factibilidad.** **Factible.** El modelo tiene las dos medidas, el año, el tipo de beneficio, el área, el proveedor y el plan. También tiene los dos roles de condición de pago, aunque la comparación de valores no requiere unirlos.

**Facilidad.** **Media.** La relación es clara, pero la consulta requiere: (i) decidir si se compara a nivel de plan o de proveedor; (ii) definir la base del porcentaje; (iii) tratar los valores 0 con `NULLIF`; (iv) controlar el área para no comparar mercados distintos; y (v) evitar duplicados por los múltiples planes del mismo proveedor. Es una consulta posible pero fácil de interpretar de forma incorrecta si no se explicitan los supuestos.

### 3.2. 2.a — Cobertura de planes con respecto a las áreas de servicio

**Pregunta analítica.** Para el rango 2017–2019, ¿qué porcentaje de las áreas de servicio tiene al menos una oferta de plan en cada año?

**Tablas y atributos necesarios.** `Hecho_OfertaPlanes` (`ID_Fecha`, `ID_AreaDeServicio`), `Dim_Fecha` (`Anio`), `Dim_AreaDeServicio` (`IdAreaDeServicio`, `FechaInicio`, `FechaFin`, `EsActual`).

**SQL.** `Q6` arma dos CTE: `universo`, que cuenta las áreas naturales con una versión vigente en cada año usando los rangos `FechaInicio`/`FechaFin` de la dimensión, y `cubiertas`, que cuenta las áreas distintas con hechos. El `LEFT JOIN` entre ambas permite reportar áreas sin oferta. Se excluye `IdAreaDeServicio = '0'`.

**Ejecución.** Resultado:

| Año | Áreas en el universo | Áreas cubiertas | Cobertura |
|---|---:|---:|---:|
| 2017 | 8 | 7 | 87,50 % |
| 2018 | 8 | 6 | 75,00 % |
| 2019 | 8 | 6 | 75,00 % |

En 2017 falta A07; en 2018 y 2019 faltan A07 y A08. La dimensión contiene A07 y A08 con versiones válidas en esos años, aunque no tengan hechos; por eso el universo se puede construir correctamente. Si el ETL hubiera cargado solo las áreas presentes en los hechos, el universo sería 7, 6 y 6, y la cobertura habría dado 100 % en los tres años: una respuesta falsa.

**Factibilidad.** **Factible.** La dimensión SCD2 y el hecho permiten reconstruir el universo por año y compararlo con las áreas cubiertas.

**Facilidad.** **Media.** La consulta es clara, pero exige un supuesto importante: el universo debe salir de la dimensión, no de los hechos. Además, hay que decidir si el área desconocida cuenta como área (aquí se excluyó) y manejar los rangos de vigencia como texto ISO. Sin ese cuidado, el resultado es engañosamente optimista.

### 3.3. 2.b — Cobertura total de los proveedores

**Pregunta analítica.** ¿Algún proveedor, o el conjunto de proveedores, ha cubierto con sus planes todas las áreas de servicio en algún año?

**Tablas y atributos necesarios.** `Hecho_OfertaPlanes` (`ID_Fecha`, `ID_Proveedor`, `ID_AreaDeServicio`), `Dim_Fecha` (`Anio`), `Dim_Proveedor` (`ID_Proveedor`), `Dim_AreaDeServicio` (`IdAreaDeServicio`, `FechaInicio`, `FechaFin`).

**SQL.** `Q7` cruza todos los proveedores con el universo de áreas de cada año y cuenta las áreas distintas cubiertas por proveedor. `Q6` responde la lectura colectiva. La lectura individual se obtiene de `Q7`; la colectiva, de `Q6`.

**Ejecución.** `Q7` devolvió 18 filas (6 proveedores × 3 años). Ninguna fila tiene `cubre_todas = 'Si'`. El máximo es 4 de 8 áreas: PRV02 en los tres años y PRV01 en 2017; PRV01 baja a 3 en 2018 y 2019, PRV03 llega a 3, PRV04 y PRV05 a 2, y PRV06 a 1. La cobertura colectiva de `Q6` es 7/8 en 2017 y 6/8 en 2018 y 2019.

**Factibilidad.** **Factible**, pero la pregunta es ambigua. Si “cobertura total de los proveedores” significa que **cada proveedor** cubra todas las áreas, la respuesta es **No** (Q7). Si significa que **todos los proveedores juntos** cubran todas las áreas, la respuesta también es **No** (Q6), porque A07 y A08 quedan sin oferta en distintos años.

**Facilidad.** **Media.** La consulta individual requiere un `CROSS JOIN` proveedores × universo y un `LEFT JOIN` para incluir proveedores sin oferta; la colectiva es más simple. El riesgo principal es no definir la lectura y reportar una conclusión distinta según la interpretación. También hay que excluir el área desconocida y contar áreas naturales distintas (`COUNT(DISTINCT IdAreaDeServicio)`) para no duplicar por versiones SCD.

### 3.4. 2.c — Áreas cubiertas por menos de dos proveedores

**Pregunta analítica.** ¿Qué áreas han tenido, en cada año, menos de dos proveedores ofreciendo planes? ¿Y qué áreas no han tenido ningún plan?

**Tablas y atributos necesarios.** `Hecho_OfertaPlanes` (`ID_Fecha`, `ID_Proveedor`, `ID_AreaDeServicio`), `Dim_Fecha` (`Anio`), `Dim_AreaDeServicio` (`IdAreaDeServicio`, `FechaInicio`, `FechaFin`).

**SQL.** `Q8` construye el universo de áreas por año y lo deja como base; luego hace `LEFT JOIN` con el conteo de proveedores distintos por área y año. El `LEFT JOIN` es imprescindible: un `JOIN` interno haría desaparecer las áreas sin planes, que son justamente parte de la respuesta.

**Ejecución.** Resultado (12 filas):

| Año | Área | Proveedores | Situación |
|---|---|---:|---|
| 2017 | A05 | 1 | Un solo proveedor |
| 2017 | A06 | 1 | Un solo proveedor |
| 2017 | A07 | 0 | Sin planes |
| 2017 | A08 | 1 | Un solo proveedor |
| 2018 | A05 | 1 | Un solo proveedor |
| 2018 | A06 | 1 | Un solo proveedor |
| 2018 | A07 | 0 | Sin planes |
| 2018 | A08 | 0 | Sin planes |
| 2019 | A05 | 1 | Un solo proveedor |
| 2019 | A06 | 1 | Un solo proveedor |
| 2019 | A07 | 0 | Sin planes |
| 2019 | A08 | 0 | Sin planes |

**Factibilidad.** **Factible.** El modelo permite contar proveedores distintos por área y año y, con el `LEFT JOIN`, distinguir “un solo proveedor” de “sin planes”.

**Facilidad.** **Media.** La lógica es sencilla, pero el universo SCD y el `LEFT JOIN` son esenciales. Si se consulta solo el hecho, las áreas sin planes desaparecen y la respuesta se sesga. También hay que decidir si el área desconocida se reporta aparte (aquí se excluyó).

### 3.5. 3.a — Planes por área, estado o condado

**Pregunta analítica.** Para el rango 2017–2019, ¿cuántos y cuáles planes hay por área de servicio y por estado o condado?

**Tablas y atributos necesarios.** `Hecho_OfertaPlanes` (`ID_Plan`, `ID_AreaDeServicio`, `ID_Proveedor`, `ID_Fecha`), `Dim_Fecha` (`Anio`), `Dim_AreaDeServicio` (`IdAreaDeServicio`, `NombreArea`, `Estado`). Para condado se necesitaría una columna `Condado` en `Dim_AreaDeServicio` o una jerarquía geográfica; no existe. Para el nombre del plan se necesitaría un atributo descriptivo en `Dim_Plan`; solo existen `ID_Plan` e `IdPlan`.

**SQL.** `Q9` agrupa por año, área, nombre y estado, y cuenta `COUNT(DISTINCT ID_Plan)`, filas de oferta y proveedores distintos. `Q10` agrupa por año y estado para mostrar la diferencia entre filas y planes distintos.

**Ejecución.** `Q9` devolvió 19 filas (7 áreas en 2017; 6 en 2018; 6 en 2019). Ejemplos:

| Año | Área | Estado | Planes distintos | Filas de oferta | Proveedores |
|---|---|---|---:|---:|---:|
| 2017 | A01 | Estado Norte | 6 | 14 | 3 |
| 2017 | A04 | Estado Centro | 8 | 17 | 5 |
| 2017 | A08 | Estado Sur | 1 | 3 | 1 |
| 2018 | A02 | Estado Norte | 5 | 11 | 3 |
| 2019 | A04 | Estado Centro | 8 | 17 | 5 |

`Q10` muestra el efecto de agregar de área a estado:

| Año | Estado | Filas | Planes distintos | Proveedores | Áreas |
|---|---|---:|---:|---:|---:|
| 2017 | Estado Centro | 25 | 10 | 6 | 3 |
| 2017 | Estado Norte | 31 | 10 | 5 | 3 |
| 2017 | Estado Sur | 3 | 1 | 1 | 1 |
| 2018 | Estado Centro | 25 | 10 | 6 | 3 |
| 2018 | Estado Norte | 31 | 10 | 5 | 3 |
| 2019 | Estado Centro | 25 | 10 | 6 | 3 |
| 2019 | Estado Norte | 31 | 10 | 5 | 3 |

En 2017 el Estado Centro tiene 25 filas de oferta pero solo 10 planes distintos; el Estado Norte tiene 31 filas y 10 planes. Contar filas como si fueran planes daría una concentración falsa. Además, en 2018 y 2019 no hay filas del Estado Sur.

**Factibilidad.** **Parcialmente factible.** El nivel área/estado es factible. El nivel condado no es factible: `Dim_AreaDeServicio` tiene 7 columnas (`ID_AreaDeServicio`, `IdAreaDeServicio`, `NombreArea`, `Estado`, `FechaInicio`, `FechaFin`, `EsActual`) y ninguna es `Condado`. La búsqueda de columnas de condado en las siete tablas (`Q15`) devuelve 0 filas. “Cuáles planes” se puede responder con `ID_Plan`, pero no con un nombre descriptivo, porque `Dim_Plan` no lo almacena.

**Facilidad.** **Alta en área/estado; no aplica en condado.** La consulta por área/estado es un `GROUP BY` directo, pero hay dos trampas: (i) el nombre del área cambia por SCD (A02 es “Área Costera” en 2017 y “Área Costera Norte” en 2018–2019), y (ii) pasar de área a estado multiplica filas; hay que usar `COUNT(DISTINCT ID_Plan)`. El condado no es una consulta difícil: es imposible con la estructura actual.

### 3.6. 3.b — Concentraciones de planes vs. población

**Pregunta analítica.** ¿En qué áreas, estados o condados hay concentraciones de planes que no correspondan con la cantidad de habitantes?

**Tablas y atributos necesarios.** Se necesitarían, además de `Hecho_OfertaPlanes` y `Dim_AreaDeServicio`, una columna de condado y una medida de población (por ejemplo, habitantes del área o del condado). Ninguna existe.

**SQL.** No se construyó. Forzar una consulta con los datos disponibles produciría una comparación sin denominador poblacional y sin granularidad de condado, es decir, una respuesta inventada.

**Ejecución.** No aplica. `Q14` lista las 7 columnas de `Dim_AreaDeServicio`; la búsqueda de `condado`, `poblaci` o `habitante` en las siete tablas (`Q15`) devuelve 0 filas.

**Factibilidad.** **No factible.** Es una limitación estructural del modelo: no hay condado ni población. A esto se suma una limitación de la fuente del negocio: la regla 1 del caso indica que las áreas de servicio no cubren todos los condados del país, de modo que aun con una columna de condado el universo geográfico estaría incompleto.

**Facilidad.** **No aplica.** No es una consulta difícil; es una consulta sin datos. Cualquier intento de aproximarla con el estado o con el conteo de planes sería una sustitución no validada.

## 4. Requerimientos derivados

### 4.1. Diferencia de copago/coseguro > 20 % (derivado de 1.a)

Ya cubierto en 1.a. La conclusión práctica es que la consulta es factible, pero el resultado depende de la base del porcentaje y del nivel de agregación. El modelo no define ninguna de las dos cosas; el analista debe hacerlo explícito. Los 86 pares son evidencia de que la consulta funciona, no un hallazgo de competencia desleal.

### 4.2. Evolución de copago y coseguro por año

**Pregunta.** ¿Cómo evolucionan el copago y el coseguro promedio, mínimo y máximo por año?

**Tablas.** `Hecho_OfertaPlanes` (`ValorCopago`, `ValorCoseguro`, `ID_Fecha`), `Dim_Fecha` (`Anio`).

**SQL.** `Q2` agrupa por año y calcula promedio, mínimo y máximo con `CAST`. `Q2b` repite el análisis para TB01 y muestra la unidad y la condición vigentes.

**Ejecución.**

| Año | Ofertas | Copago prom. | Copago mín.–máx. | Coseguro prom. | Coseguro mín.–máx. |
|---|---:|---:|---:|---:|---:|
| 2017 | 59 | 188,31 | 0–500 | 30,59 | 0–100 |
| 2018 | 58 | 240,52 | 0–3500 | 30,86 | 0–100 |
| 2019 | 58 | 204,74 | 0–500 | 33,10 | 0–100 |

El promedio de copago de 2018 está influido por el máximo 3500; no es un valor típico. Para TB01: 2017 “Visitas”, 171,18 / 24,41; 2018 “Visitas por año”, 264,71 / 45,00; 2019 “Visitas por año”, 210,29 / 35,00.

**Factibilidad.** **Factible.**  
**Facilidad.** **Alta.** Es un `GROUP BY` simple; las únicas precauciones son el `CAST` porque las medidas son `TEXT` y no sumar valores que representan ofertas individuales.

### 4.3. Versión histórica de un tipo de beneficio o área de servicio

**Pregunta.** ¿Qué condiciones, unidad de límite o nombre de área estaban vigentes en un año anterior?

**Tablas.** `Hecho_OfertaPlanes`, `Dim_TipoBeneficio` (`IdTipoBeneficio`, `UnidadLimite`, `Condiciones`, `FechaInicio`, `FechaFin`, `EsActual`), `Dim_AreaDeServicio` (`IdAreaDeServicio`, `NombreArea`, `Estado`, `FechaInicio`, `FechaFin`, `EsActual`), `Dim_Fecha`.

**SQL.** `Q2b` para TB01; `Q3` para A02. El hecho se une por la clave subrogada de la versión, por lo que el nombre y la unidad son los vigentes en el año de la oferta.

**Ejecución.** TB01 cambia de “Visitas” a “Visitas por año” y de `Condiciones = 'No'` a `'Yes'` entre 2017 y 2018. A02 cambia de “Área Costera” a “Área Costera Norte” entre 2017 y 2018; en 2019 es la versión actual (`EsActual = 'Yes'`). Las 11 ofertas anuales de A02 se conservan en las tres versiones.

**Factibilidad.** **Factible.**  
**Facilidad.** **Alta, con riesgo de duplicación.** Si se une por la clave natural en lugar de la subrogada, cada hecho se multiplica por el número de versiones: 18 versiones para 6 tipos de beneficio y 25 versiones para 9 miembros de la dimensión de área (8 áreas naturales más la desconocida) (`Q12`). La consulta correcta usa las claves subrogadas que ya están en el hecho; el analista debe saberlo.

### 4.4. Ofertas del área desconocida (Id = 0) y límites con valor 333

**Pregunta.** ¿Qué ofertas están asociadas al área desconocida y cuántos límites usan el valor por defecto 333?

**Tablas.** `Hecho_OfertaPlanes` (`ID_OfertaPlanes`, `ID_Fecha`, `ID_AreaDeServicio`, `LimiteCuantitativo`, `ValorCopago`, `ValorCoseguro`), `Dim_Fecha`, `Dim_AreaDeServicio`, `Dim_TipoBeneficio`.

**SQL.** `Q4` filtra `IdAreaDeServicio = '0'`; `Q5` agrupa los límites `'333'` por año y beneficio; `Q5b` cuenta las filas.

**Ejecución.** El área desconocida tiene 4 ofertas: OF0071 (2018, límite 333, copago 50, coseguro 5), OF0074 (2018, límite 100, copago 100, coseguro 10), OF0129 (2019, límite 333, copago 75, coseguro 5) y OF0132 (2019, límite 333, copago 200, coseguro 30). El límite 333 aparece en 18 filas, agrupadas en 12 combinaciones año-beneficio: 2017 TB01 (2), TB02 (2), TB03 (1), TB04 (1); 2018 TB01 (3), TB02 (2), TB03 (1); 2019 TB01 (2), TB02 (1), TB03 (1), TB04 (1), TB06 (1).

**Factibilidad.** **Factible.**  
**Facilidad.** **Alta.** Son filtros simples. La precaución es semántica: 333 es un valor por defecto de la regla de negocio, no un límite real; el modelo lo almacena sin una marca que lo distinga. El analista debe conocer la regla para no interpretarlo como un límite observado.

### 4.5. Cobertura de áreas por proveedor y áreas con menos de dos proveedores

Ya cubierto en 2.b (`Q7`) y 2.c (`Q8`). La evidencia muestra que ningún proveedor cubre las 8 áreas y que A05/A06 tienen un solo proveedor en todos los años, mientras A07 no tiene planes y A08 solo tuvo uno en 2017. La consulta es factible; la dificultad está en construir el universo desde la dimensión y en usar `LEFT JOIN` para no perder las áreas sin oferta.

### 4.6. Planes por área, estado y condado; duplicación al pasar de área a estado

Ya cubierto en 3.a. `Q9` responde área/estado; `Q10` muestra la duplicación: en 2017 el Estado Centro tiene 25 filas de oferta pero 10 planes distintos, y el Estado Norte 31 filas pero 10 planes. El condado no existe en el modelo. La consulta por área/estado es fácil; el riesgo es contar filas en lugar de planes distintos y arrastrar el nombre de la versión SCD equivocada.

### 4.7. Planes en relación con la población, si el modelo la almacena

Ya cubierto en 3.b. `Q15` devuelve 0 filas: no hay columna de población ni de habitantes en ninguna de las siete tablas. No se puede calcular la relación. Es una limitación estructural, agravada por la regla de negocio de que las áreas no cubren todos los condados.

### 4.8. Otras validaciones derivadas

- **Roles de condición de pago (`Q11`).** Las 175 filas tienen un `ID_CondicionCopago` que apunta a tipo “Copago” y un `ID_CondicionCoseguro` que apunta a tipo “Coseguro”; no hay cruces. La consulta es factible y sencilla. Limitación: el esquema no impone esa restricción; la base de prueba fue generada correctamente, pero el modelo permitiría un cruce de roles si el ETL lo hiciera mal.
- **Máximos 2018 (`Q13`).** Copago máximo 3500 y coseguro máximo 100, exactamente los valores de la regla de negocio 6. La consulta es factible; sirve como control de carga.
- **Versiones SCD (`Q12`).** 18 versiones / 6 tipos de beneficio y 25 versiones / 9 miembros de la dimensión de área (8 áreas naturales más la desconocida). Es la evidencia de por qué no se debe unir por clave natural.
- **Planes distintos por año (`Q16`).** 12 planes distintos en cada año, con 59, 58 y 58 ofertas. El número de planes no cambia, pero el número de ofertas sí; esto ayuda a interpretar la cobertura y la concentración.

## 5. Limitaciones diferenciadas

### 5.1. Limitaciones de los datos de prueba

- La base tiene 175 hechos, 12 planes, 6 proveedores y 3 años. Los resultados concretos (86 pares, 7/8 áreas, etc.) describen esta base sintética, no el negocio real.
- No hay duplicados en el grano del hecho, ni claves foráneas nulas, ni cruces de roles Copago/Coseguro. Por eso las consultas no prueban su comportamiento frente a datos sucios; el modelo permite esos defectos, pero la base de prueba no los contiene.
- Solo se probaron los tipos “Copago” y “Coseguro”, que son los que exige la regla de negocio. No se probó un tercer tipo.
- En la base hay una sola fecha por plan/beneficio/área/año. Si el proceso real tuviera varias fechas, `Q1a` promedia y `Q2` cuenta ofertas; las consultas seguirían funcionando, pero el grano de análisis cambiaría.
- No hay ofertas en el Estado Sur en 2018 y 2019. Es una característica de los datos de prueba; el modelo puede representar esas ofertas (A08 existe en la dimensión), pero la base no las tiene.
- El máximo de copago 2018 (3500) es un valor atípico que infla el promedio. Es un dato de prueba, no un problema estructural.

### 5.2. Limitaciones estructurales del modelo

- **No existe condado.** `Dim_AreaDeServicio` solo llega a `Estado`; 3.a queda parcial y 3.b no se puede responder.
- **No existe población.** Ninguna tabla tiene habitantes, población del área ni población del condado; 3.b no se puede responder.
- **Medidas como `TEXT`.** Copago, coseguro y límite se almacenan como texto; toda agregación requiere `CAST`. Si se olvida, una comparación como `'100' > '20'` es lexicográfica, no numérica.
- **`Dim_Plan` sin atributos descriptivos.** Solo tiene `ID_Plan` e `IdPlan`; 3.a puede listar identificadores, pero no nombres o características de los planes.
- **Los roles de condición de pago no están restringidos por el esquema.** `ID_CondicionCopago` e `ID_CondicionCoseguro` son dos claves foráneas a la misma dimensión; nada impide que una apunte a “Coseguro” y la otra a “Copago”. La consulta `Q11` lo verifica, pero el modelo no lo garantiza.
- **No hay un atributo de nivel de servicio en el hecho.** El grano es plan × beneficio × área × fecha; si el negocio distingue niveles de servicio, el modelo no los separa. No es uno de los seis análisis, pero limita análisis futuros.
- **El valor 333 no tiene una marca de “valor por defecto”.** Se almacena igual que un límite real; la regla de negocio debe conocerse para interpretarlo.

### 5.3. Limitaciones de las fuentes del negocio

- **Las áreas no cubren todos los condados** (regla 1). Aun si el modelo tuviera condado, el universo geográfico estaría incompleto; cualquier conclusión de “cobertura total” es relativa a las áreas modeladas.
- **La fuente de áreas tenía solo 2017 y 2018; faltaba 2019** (regla 4). El modelo cargado sí tiene 2019, pero la carga dependió de completar esa fuente. Es una limitación de origen, no de la consulta.
- **El área desconocida (Id = 0) existe porque hay `IdAreaDeServicio` que no están en la fuente de áreas.** Es una regla de negocio que el modelo soporta; las consultas deben decidir si la incluyen o la excluyen.
- **El límite 333 es un valor por defecto** (regla 2). El modelo lo almacena, pero no lo distingue; la interpretación depende del conocimiento de la regla.
- **Las condiciones de pago se limitan a “Copago” y “Coseguro”** (indicación de RaSa). El modelo tiene 8 filas en la dimensión; la consulta de roles funciona, pero no se probó un tercer tipo.

### 5.4. Consultas posibles pero difíciles

- **1.a** es posible, pero exige definir la base del porcentaje, el nivel de agregación (plan o proveedor), el tratamiento de los valores 0 y el control del área. La diferencia entre 200 %, 100 % y 66,67 % para el mismo par (10 vs. 30) muestra que el resultado no es único sin un supuesto.
- **2.a y 2.c** son posibles, pero dependen de construir el universo desde la dimensión SCD2. Si se usan solo los hechos, las áreas sin oferta desaparecen y la cobertura se sobreestima.
- **2.b** es posible, pero la pregunta admite dos lecturas (individual y colectiva); ambas dan “No” en esta base, pero la consulta y la conclusión cambian según la lectura.
- **3.a** es posible a nivel área/estado, pero no a nivel condado. La dificultad no es SQL, sino la ausencia de la columna.

## 6. Conclusiones

1. **El modelo responde cuatro de los seis análisis de forma completa** (1.a, 2.a, 2.b y 2.c), **uno de forma parcial** (3.a, solo área/estado) y **uno no lo responde** (3.b, población).
2. **La cobertura es el análisis más sensible al supuesto del universo.** La dimensión contiene áreas sin hechos (A07 y A08), lo que permite calcular una cobertura real (87,5 % en 2017; 75 % en 2018 y 2019). Si el ETL cargara solo las áreas con oferta, la cobertura sería falsamente 100 %. Esta es una dependencia de carga, no una limitación estructural de la consulta.
3. **La competencia del 1.a es factible, pero no unívoca.** El modelo tiene todos los atributos; la ambigüedad está en la definición del porcentaje y en el nivel de comparación. Los 86 pares son evidencia de ejecución, no una conclusión de negocio.
4. **La cobertura total de proveedores es “No” en ambas lecturas.** Ningún proveedor cubre las 8 áreas; en conjunto, la cobertura máxima es 7/8 en 2017 y 6/8 en 2018 y 2019.
5. **Las áreas con menos de dos proveedores son identificables**, incluyendo las que no tienen ningún plan. A05 y A06 tienen un solo proveedor en todos los años; A07 no tiene planes; A08 tuvo uno en 2017 y ninguno en 2018–2019.
6. **El condado y la población son ausencias estructurales**, no consultas difíciles. No se debe forzar una respuesta con estado o conteo de planes.
7. **El principal riesgo de duplicación está en las dimensiones SCD2 y en el paso de área a estado.** Las claves subrogadas del hecho evitan el primer problema; `COUNT(DISTINCT ID_Plan)` evita el segundo.
8. **No se modifica la base ni se propone un modelo corregido en esta entrega.** La evidencia queda limitada al comportamiento del modelo inicial frente a los datos de prueba.

## 7. Evidencia de ejecución

- `consultas_factibilidad_inicial_ofertaplanes.sql` se ejecutó completo con `sqlite3` sin errores.
- La base conserva las 7 tablas y los conteos originales; `PRAGMA integrity_check` devolvió `ok` y `PRAGMA foreign_key_check` no devolvió filas.
- Resultados clave: 86 pares > 20 %; cobertura 7/8, 6/8 y 6/8; 18 filas proveedor-año sin cobertura total; 12 filas de áreas con menos de dos proveedores; 4 ofertas con área desconocida; 18 filas con límite 333; 175 filas por cada rol de condición de pago; 18 versiones / 6 tipos de beneficio y 25 versiones / 9 áreas; máximos 2018 de 3500 y 100; 0 columnas de condado o población.
