Actúa como especialista en inteligencia de negocios, data warehousing y modelado multidimensional.

Tu tarea es generar el modelo multidimensional final del proceso OfertaPlanes de RaSa. Debes aplicar las decisiones que tomé sobre las recomendaciones de la evaluación con IA (validacion_modelo_inicial_ofertaplanes.md) y de la validación práctica (resultados_factibilidad_inicial_ofertaplanes.md). Las decisiones ya están tomadas: no las cambies, no agregues recomendaciones nuevas y no omitas ninguna.

Utiliza como fuentes:
- caso_rasa_ofertaplanes.md y Guia_Modelo_Dimensional_ETL.pdf como fuentes del caso de negocio.
- Diccionario.xlsx para los nombres y tipos reales de las columnas de origen de F1 (FuenteAreasDeServicio_Copia_E), F2 (FuenteTiposBeneficio_Copia_E), F3 (FuentesPlanesBeneficio_Copia_E) y F4 (FuenteCondicionesDePago_Copia_E).
- modelo_inicial_ofertaplanes.dbml como base estructural de la propuesta que será ajustada.
- validacion_modelo_inicial_ofertaplanes.md como evidencia de la evaluación conceptual realizada con IA usando los criterios C1 a C7 de criterios_validacion_ofertaplanes.md.
- resultados_factibilidad_inicial_ofertaplanes.md como evidencia de la validación práctica.

Aplica las siguientes decisiones de diseño. Cada una corresponde a una recomendación (R) de la evaluación y a su decisión: Adoptada, Modificada o Descartada.

R1. Incorporar condado y población de F1 (C1, C4; hallazgo 1). Decisión: Modificada.
- En F1 cada fila relaciona un área de servicio con un condado (idGeografía_T), de modo que un área cubre varios condados. Por eso no se agregan Condado ni PoblacionAct directamente a Dim_AreaDeServicio, porque eso rompería una fila por área.
- Crea Dim_Geografia con llave subrogada ID_Geografia, llave natural IdGeografia (idGeografía_T) y los atributos Condado, Estado, PoblacionAct, AreaMillasCuadradas (Area) y Densidad. Es SCD Tipo 1, porque F1 solo trae la población actual.
- Crea la tabla puente Puente_AreaGeografia (ID_AreaDeServicio, ID_Geografia) que relaciona cada versión de área con sus condados. Así la composición de cada área queda asociada a la versión vigente en cada año.
- Documenta que 3.b se resuelve con la población actual y no con la del año analizado, y que las áreas no cubren todos los condados del país (regla 1), así que el universo geográfico es el de las áreas modeladas.

R2. Declarar el grano e incluir el nivel de servicio (C2; hallazgo 2). Decisión: Adoptada.
- El grano de Hecho_OfertaPlanes es una fila por plan, tipo de beneficio, área de servicio y nivel de servicio ofrecido en una fecha de oferta (proceso anual).
- Agrega IdNivelServicio (idNivelServicio_T) como dimensión degenerada en el hecho, porque F1 a F4 no traen atributos descriptivos del nivel de servicio.
- Declara el grano en una nota de la tabla, con la PK técnica ID_OfertaPlanes y una restricción única sobre (ID_Fecha, ID_Plan, ID_TipoBeneficio, ID_AreaDeServicio, IdNivelServicio).

R3. Asegurar los roles de condición de pago (C5; hallazgo 3). Decisión: Adoptada.
- Conserva una sola Dim_CondicionPago usada con dos roles en el hecho: ID_CondicionCopago e ID_CondicionCoseguro.
- TipoCondicion solo admite Copago o Coseguro. Los registros "Anticipado" de F4 no se cargan, según la indicación de RaSa.
- Documenta en las notas que la carga valida que ID_CondicionCopago apunte a una fila de tipo Copago e ID_CondicionCoseguro a una de tipo Coseguro, porque el esquema por sí solo no lo garantiza.

R4. Definir la historia de las dimensiones (C7; hallazgo 4). Decisión: Adoptada.
- Dim_TipoBeneficio y Dim_AreaDeServicio son SCD Tipo 2 con vigencia anual: AnioVigencia, FechaInicioVigencia, FechaFinVigencia y EsVersionActual. Declara unicidad sobre (IdTipoBeneficio, AnioVigencia) y (IdAreaDeServicio, AnioVigencia).
- Documenta que las vigencias se derivan del campo Fecha de F1 y F2, y que el hecho se asocia con la versión cuyo AnioVigencia coincide con el año de la oferta, no con EsVersionActual.
- Dim_Proveedor, Dim_Plan y Dim_CondicionPago son SCD Tipo 1, porque las fuentes no muestran cambios en sus atributos.

R5. Tipar las medidas y declarar su aditividad (C3, C6; hallazgo 5). Decisión: Adoptada.
- ValorCopago, ValorCoseguro y LimiteCuantitativo son decimal(14,2) y no aditivas; su agregación válida es promedio, mínimo y máximo. CantidadOfertas es integer y aditiva; cuenta filas del grano y no planes distintos.
- Documenta que los planes se cuentan con COUNT(DISTINCT ID_Plan) y que la diferencia porcentual de 1.a es una medida derivada que se calcula en las consultas y no se almacena.

R6. Respaldo del proveedor en las fuentes (C4; hallazgo 6). Decisión: Modificada.
- Elimina NombreProveedor de Dim_Proveedor, porque no existe en F1 a F4. Dim_Proveedor queda con ID_Proveedor e IdProveedor (idProveedor_T).
- No crees un atributo de grupo de proveedores. Documenta que 1.a se resuelve por identificador de proveedor y que el grupo de proveedores lo define el usuario en la consulta.

R7. Trazabilidad de atributos y llaves naturales (C4, C6; hallazgo 7). Decisión: Modificada.
- Reemplaza el atributo Condiciones de Dim_TipoBeneficio por los campos de F2 a los que corresponde: EsEHB, EstaCubiertoPorSeguro, TieneLimiteCuantitativo, ExcluidoDelDesembolsoMaximoDentroDeLaRed y ExcluidoDelDesembolsoMaximoFueraDeLaRed, todos con valores Yes o No.
- Renombra NombreBeneficio a Nombre (F2) y UnidadLimite a UnidadDelLimite (F2), y NombreArea a NombreAreaDeServicio (F1).
- Declara las llaves naturales como no nulas, y como únicas en las dimensiones SCD Tipo 1.

R8. Documentar las reglas de negocio de la carga (hallazgo 8 y validación práctica). Decisión: Adoptada.
- Cada dimensión incluye un miembro 0 "Desconocido / No aplica", y en Dim_AreaDeServicio ese miembro recibe las áreas de F3 que no existen en F1. El hecho no usa llaves nulas.
- Agrega en el hecho el indicador EsLimitePorDefecto (Yes/No) para distinguir el límite 333 asignado por regla de un límite real.
- Documenta en las notas: límite 333 por defecto, máximos de 2018 (copago 3500 y coseguro 100), fechas en formato YYYY-MM-DD, eliminación de duplicados en todas las fuentes y carga de Dim_AreaDeServicio con el universo completo de F1 (no solo las áreas con ofertas), para que 2.a, 2.b y 2.c midan la cobertura real.

R9. Unificar la convención de nombres (C6). Decisión: Adoptada.
- Prefijos Dim_, Hecho_ y Puente_; columnas en PascalCase; llave subrogada ID_<Dimensión> y llave natural Id<Dimensión>. En la nota de cada columna de llave natural indica el campo de origen del diccionario.

No incorpores información que no esté sustentada por el caso ni por el diccionario. En particular:
- no agregues atributos al plan, al proveedor o al nivel de servicio que no existan en F1 a F4;
- no agregues historia (SCD Tipo 2) a Dim_Proveedor, Dim_Plan, Dim_CondicionPago ni Dim_Geografia;
- no agregues hechos, tablas puente ni medidas distintas de las indicadas en las decisiones R1 a R9.

Conserva las dimensiones y relaciones de modelo_inicial_ofertaplanes.dbml que no entren en conflicto con estas decisiones.

Genera dos archivos:
1. modelo_final_ofertaplanes.dbml, con el modelo completo en sintaxis DBML válida.
2. ajustes_modelo_final_ofertaplanes.md, con una tabla de columnas: ID, Recomendación de la evaluación, Criterio, Decisión (Adoptada / Modificada / Descartada), Justificación y Cambio aplicado en el modelo (tabla.columna). Usa la decisión y la justificación indicadas arriba, sin cambiarlas; solo completa el cambio aplicado.

Antes de finalizar verifica que:
- la tabla de hechos tenga un grano único y explícito, con clave primaria y restricción única sobre el grano, incluido IdNivelServicio;
- las medidas tengan tipo numérico y su aditividad documentada;
- el hecho tenga una llave foránea por cada rol de dimensión;
- Dim_CondicionPago se use correctamente con sus dos roles;
- Dim_TipoBeneficio y Dim_AreaDeServicio conserven la historia con sus columnas de vigencia;
- Puente_AreaGeografia relacione cada versión de área con sus condados y Dim_Geografia tenga Condado, Estado y PoblacionAct;
- exista la dimensión Fecha con día, mes y año;
- exista el miembro Desconocido (Id = 0) en todas las dimensiones;
- cada recomendación R1 a R9 aparezca en ajustes_modelo_final_ofertaplanes.md;
- no se haya incorporado información no sustentada por el caso ni por el diccionario.

Responde en español.
