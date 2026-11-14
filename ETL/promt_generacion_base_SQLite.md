Actúa como especialista en bases de datos y modelado dimensional.

Tu tarea es construir una base de datos SQLite a partir del modelo contenido en modelo_inicial_ofertaplanes.dbml, con el propósito de utilizarla posteriormente para evaluar de forma práctica la facilidad y factibilidad de responder los análisis requeridos del proceso OfertaPlanes de RaSa.

(Para el modelo IA cambie modelo_inicial_ofertaplanes.dbml por modelo_ia_ofertaplanes.dbml y el nombre de la base por modelo_ia_ofertaplanes.sqlite; para el modelo final use modelo_final_ofertaplanes.dbml y modelo_final_ofertaplanes.sqlite.)

Utiliza como fuentes:
- modelo_inicial_ofertaplanes.dbml para definir exclusivamente la estructura de la base de datos.
- caso_rasa_ofertaplanes.md y Diccionario.xlsx únicamente como contexto para generar datos de prueba coherentes con el negocio.

No consultes ni utilices otros modelos, archivos drawio ni validaciones anteriores.

Debes conservar la estructura del modelo.

No corrijas el diseño.
No agregues tablas, dimensiones, hechos, atributos o relaciones que no existan en el DBML.
No elimines elementos.
No cambies el grano de las tablas.
No modifiques relaciones para facilitar posteriormente las consultas.

Genera datos sintéticos suficientes para probar los análisis del caso.

Los datos deben:
- ser completamente ficticios;
- mantener integridad referencial cuando las relaciones estén definidas;
- cubrir los años 2017, 2018 y 2019;
- incluir varios proveedores, planes, tipos de beneficio, áreas de servicio, estados y condados, y condiciones de pago de tipo Copago y Coseguro;
- incluir versiones históricas en las dimensiones que el modelo define con SCD Tipo 2 (por ejemplo, un tipo de beneficio cuya unidad de límite cambia entre años);
- incluir casos especiales del negocio: ofertas asociadas al área desconocida (Id = 0), límites cuantitativos con valor 333, proveedores con diferencias de copago o coseguro mayores al 20 % para el mismo tipo de beneficio, áreas cubiertas por un solo proveedor y áreas sin planes;
- respetar los máximos de 2018: copago 3500 y coseguro 100;
- permitir realizar agregaciones y filtros cuando el modelo lo soporte;
- no inventar nuevas columnas para representar información que el modelo no puede almacenar.

Cuando un análisis necesite información o un nivel de detalle que no pueda representarse con el modelo, no construyas una solución alternativa ni modifiques la estructura para simular esa capacidad.

Crea la base de datos:
modelo_inicial_ofertaplanes.sqlite

Antes de finalizar verifica que todas las tablas definidas en el DBML existan en SQLite, que la base contenga datos de prueba y que no se hayan incorporado elementos que corrijan o amplíen el modelo original.

No evalúes todavía si el modelo es correcto. La finalidad de esta tarea es únicamente materializar el modelo con datos para poder probarlo posteriormente.
