Actúa como especialista en inteligencia de negocios, data warehousing y modelado multidimensional. Tu responsabilidad es analizar el caso proporcionado y proponer un modelo multidimensional que permita responder las necesidades analíticas identificadas.

Utiliza como fuentes del caso de negocio:
- caso_rasa_ofertaplanes.md y Guia_Modelo_Dimensional_ETL.pdf para el proceso de negocio, los análisis requeridos y las respuestas del negocio.
- diccionario_datos_rasa para las tablas y columnas disponibles en las fuentes F1 (FuenteAreasDeServicio_Copia_E), F2 (FuenteTiposBeneficio_Copia_E), F3 (FuentePlanesBeneficio_Copia_E) y F4 (FuenteCondicionesDePago_Copia_E).

El proceso de negocio es OfertaPlanes y se realiza de forma anual.

Antes de construir el modelo, identifica los procesos de negocio relevantes, las necesidades analíticas (análisis 1.a, 2.a, 2.b, 2.c, 3.a y 3.b) y el grano de cada tabla de hechos.

Después define las tablas de hechos, sus medidas, las dimensiones necesarias y las relaciones entre ellas. Identifica dimensiones compartidas entre hechos y dimensiones utilizadas con diferentes roles cuando corresponda. Revisa en particular:
- cómo se relacionan las áreas de servicio con los estados y condados, considerando que un área puede cubrir varios condados y que las áreas no cubren todos los condados del país;
- cómo se representan el copago, el coseguro y sus condiciones de pago;
- qué atributos de las dimensiones cambian entre años y qué tipo de dimensión lentamente cambiante (SCD) corresponde a cada una, considerando que el negocio confirmó un solo valor de condiciones y unidad de límite por tipo de beneficio y por año;
- cómo se manejan las áreas de servicio que aparecen en planes beneficio pero no existen en la fuente de áreas (registro Desconocido con identificador 0);
- la inclusión obligatoria de una dimensión de fecha con el nivel año.

Para cada medida indica si es aditiva, semiaditiva o no aditiva y qué agregación es válida.

Utiliza únicamente la información disponible en el caso y en el diccionario. No inventes atributos, fuentes de información ni reglas de negocio. Cuando necesites realizar un supuesto, decláralo explícitamente. Si una necesidad analítica requiere información no disponible en las fuentes (por ejemplo, la cantidad de habitantes), indícalo en lugar de asumir que esa información existe.

No consultes ni utilices modelo_inicial_ofertaplanes.dbml, modelo_ofertaplanes.drawio ni modelo_propio_ofertaplanes.md. La propuesta debe construirse independientemente a partir del caso de negocio.

Para cada necesidad analítica indica si puede resolverse con la información disponible, si puede resolverse parcialmente o si requiere información adicional.

Organiza la explicación en las siguientes partes: proceso de negocio, necesidades analíticas, grano de cada hecho, hechos y medidas, dimensiones, manejo de la historia (SCD), relaciones y decisiones de diseño, supuestos, información adicional requerida y trazabilidad con los análisis.

En la trazabilidad indica para cada análisis qué elementos del modelo permiten atenderlo y cuál es su nivel de factibilidad.

Genera al final un modelo completo utilizando sintaxis DBML válida, en el que cada tabla de hechos incluya una llave foránea por cada dimensión relacionada, y guarda únicamente el código DBML en modelo_ia_ofertaplanes.dbml.

Antes de finalizar comprueba que cada hecho tenga un grano único y explícito, que las medidas correspondan con ese grano, que las dimensiones aporten contexto analítico, que las relaciones sean consistentes, que la historia de los atributos esté definida, que exista la dimensión de fecha y que no se haya utilizado información no sustentada por el caso ni por el diccionario.

Responde en español.
