Criterios de validación – Modelo multidimensional OfertaPlanes (RaSa)

Cada modelo se califica con estos siete criterios. Cada criterio trae las preguntas que se usan para verificarlo.

C1. Cumplimiento de los análisis requeridos

Evalúa si el modelo permite responder los análisis propuestos para lograr los objetivos de esta tarea.

i. ¿El modelo permite comparar el copago y el coseguro entre proveedores para un mismo tipo de beneficio?
ii. ¿Permite ver qué áreas de servicio cubren los planes y cuántos proveedores hay en cada área?
iii. ¿Algún análisis necesita información que no está en las fuentes F1 a F4?
iv. ¿El análisis sería viable con el grano propuesto?

C2. Definición del grano

Evalúa la claridad y consistencia del nivel de detalle definido para la tabla de hechos.

i. ¿Qué representa una fila de la tabla de hechos?
ii. ¿El grano tiene sentido para un proceso que se realiza una vez al año?
iii. ¿Todas las llaves y medidas pertenecen a ese nivel de detalle?

C3. Hechos y medidas

Evalúa si las medidas pertenecen al proceso de oferta de planes y cómo se comportan cuando se agregan.

i. ¿Las medidas pertenecen al proceso representado?
ii. ¿Las medidas pueden duplicarse al cambiar el nivel de análisis (por ejemplo, de área a estado)?
iii. ¿Las medidas son aditivas, semiaditivas o no aditivas? Por ejemplo, ¿tiene sentido sumar copagos?

C4. Dimensiones y atributos

Evalúa si las dimensiones representan conceptos del negocio y tienen los atributos necesarios para filtrar y agrupar.

i. ¿Cada dimensión agrupa atributos de un mismo concepto (plan, proveedor, tipo de beneficio, área, condición de pago)?
ii. ¿Cada dimensión tiene llave subrogada y llave natural de la fuente?
iii. ¿Existe la dimensión Fecha con el nivel año, que es el que más se usa en los análisis?
iv. ¿Hay atributos descriptivos ubicados por error en la tabla de hechos?

C5. Relaciones y llaves foráneas

Evalúa si las relaciones entre la tabla de hechos y las dimensiones están completas y bien definidas.

i. ¿La tabla de hechos tiene una llave foránea por cada dimensión relacionada?
ii. ¿La cardinalidad es 1:N desde cada dimensión hacia el hecho?
iii. ¿La condición de pago, que se usa para el copago y para el coseguro, está modelada correctamente con roles?

C6. Consistencia del modelo

Evalúa la coherencia interna del modelo en nombres, tipos y estructura.

i. ¿Las tablas y columnas siguen una misma convención de nombres?
ii. ¿Hay atributos repetidos en más de una dimensión?
iii. ¿Todas las dimensiones están conectadas al hecho?

C7. Historia de los atributos

Evalúa si el modelo guarda los cambios que tienen los atributos de las dimensiones de un año a otro.

i. ¿Se indica qué dimensiones guardan historia y cuáles no, y por qué?
ii. ¿Las dimensiones que cambian por año (tipos de beneficio y áreas de servicio) tienen fechas de vigencia?
iii. ¿El hecho apunta a la versión que estaba vigente en el año de la oferta?
