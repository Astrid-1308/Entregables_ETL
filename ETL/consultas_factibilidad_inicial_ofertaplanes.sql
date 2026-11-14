-- =====================================================================
-- Consultas de factibilidad practica
-- Caso: RaSa / OfertaPlanes
-- Base: modelo_inicial_ofertaplanes.sqlite
-- Modelo de referencia: modelo_inicial_ofertaplanes.dbml
--
-- Notas generales:
-- * No se modifica la base: solo se ejecutan SELECT.
-- * Las medidas de Hecho_OfertaPlanes estan almacenadas como TEXT.
--   Por eso se usa CAST(... AS REAL) o CAST(... AS INTEGER) al agregar.
-- * Las dimensiones son SCD2: para tomar la version vigente en el ano de
--   la oferta se une por la clave subrogada que ya trae el hecho
--   (ID_TipoBeneficio, ID_AreaDeServicio, ID_Fecha), no por la clave natural.
-- * El area desconocida tiene IdAreaDeServicio = '0'. En las consultas de
--   cobertura se excluye y se documenta el supuesto.
-- * Las consultas Q1 y Q8 usan el valor menor como base del porcentaje.
--   Es un supuesto porque el caso no define la base de comparacion.
-- =====================================================================


-- =====================================================================
-- Q1a. Competencia desleal (1.a): pares de planes de proveedores distintos,
--      mismo ano, mismo tipo de beneficio y misma area, con diferencia
--      mayor al 20 % en copago o coseguro.
--      Base del porcentaje: el menor de los dos valores.
--      Los pares con base 0 quedan fuera porque NULLIF evita division por 0.
--      Para acotar a un proveedor o grupo de proveedores, agregar en el
--      WHERE final, por ejemplo:
--        AND (o1.proveedor = 'PRV01' OR o2.proveedor = 'PRV01')
-- =====================================================================
WITH ofertas AS (
    SELECT f.Anio                         AS anio,
           t.IdTipoBeneficio              AS beneficio,
           a.IdAreaDeServicio             AS area,
           h.ID_Proveedor                 AS proveedor,
           h.ID_Plan                      AS plan,
           AVG(CAST(h.ValorCopago   AS REAL)) AS copago,
           AVG(CAST(h.ValorCoseguro AS REAL)) AS coseguro
    FROM Hecho_OfertaPlanes h
    JOIN Dim_Fecha          f ON h.ID_Fecha          = f.ID_Fecha
    JOIN Dim_TipoBeneficio  t ON h.ID_TipoBeneficio  = t.ID_TipoBeneficio
    JOIN Dim_AreaDeServicio a ON h.ID_AreaDeServicio = a.ID_AreaDeServicio
    WHERE a.IdAreaDeServicio <> '0'
    GROUP BY f.Anio, t.IdTipoBeneficio, a.IdAreaDeServicio,
             h.ID_Proveedor, h.ID_Plan
)
SELECT o1.anio,
       o1.beneficio,
       o1.area,
       o1.proveedor AS proveedor_1,
       o1.plan      AS plan_1,
       o2.proveedor AS proveedor_2,
       o2.plan      AS plan_2,
       ROUND(o1.copago, 2)    AS copago_1,
       ROUND(o2.copago, 2)    AS copago_2,
       ROUND(ABS(o1.copago - o2.copago) * 100.0
             / NULLIF(MIN(o1.copago, o2.copago), 0), 2) AS dif_copago_pct,
       ROUND(o1.coseguro, 2)  AS coseguro_1,
       ROUND(o2.coseguro, 2)  AS coseguro_2,
       ROUND(ABS(o1.coseguro - o2.coseguro) * 100.0
             / NULLIF(MIN(o1.coseguro, o2.coseguro), 0), 2) AS dif_coseguro_pct
FROM ofertas o1
JOIN ofertas o2
  ON o1.anio      = o2.anio
 AND o1.beneficio = o2.beneficio
 AND o1.area      = o2.area
 AND o1.proveedor < o2.proveedor
WHERE (ABS(o1.copago - o2.copago) * 100.0
       / NULLIF(MIN(o1.copago, o2.copago), 0) > 20)
   OR (ABS(o1.coseguro - o2.coseguro) * 100.0
       / NULLIF(MIN(o1.coseguro, o2.coseguro), 0) > 20)
ORDER BY o1.anio, o1.beneficio, o1.area, o1.proveedor, o2.proveedor;


-- Q1a-resumen. Cantidad de pares que cumplen la condicion anterior.
WITH ofertas AS (
    SELECT f.Anio                         AS anio,
           t.IdTipoBeneficio              AS beneficio,
           a.IdAreaDeServicio             AS area,
           h.ID_Proveedor                 AS proveedor,
           h.ID_Plan                      AS plan,
           AVG(CAST(h.ValorCopago   AS REAL)) AS copago,
           AVG(CAST(h.ValorCoseguro AS REAL)) AS coseguro
    FROM Hecho_OfertaPlanes h
    JOIN Dim_Fecha          f ON h.ID_Fecha          = f.ID_Fecha
    JOIN Dim_TipoBeneficio  t ON h.ID_TipoBeneficio  = t.ID_TipoBeneficio
    JOIN Dim_AreaDeServicio a ON h.ID_AreaDeServicio = a.ID_AreaDeServicio
    WHERE a.IdAreaDeServicio <> '0'
    GROUP BY f.Anio, t.IdTipoBeneficio, a.IdAreaDeServicio,
             h.ID_Proveedor, h.ID_Plan
)
SELECT COUNT(*) AS pares_mayores_20pct
FROM ofertas o1
JOIN ofertas o2
  ON o1.anio      = o2.anio
 AND o1.beneficio = o2.beneficio
 AND o1.area      = o2.area
 AND o1.proveedor < o2.proveedor
WHERE (ABS(o1.copago - o2.copago) * 100.0
       / NULLIF(MIN(o1.copago, o2.copago), 0) > 20)
   OR (ABS(o1.coseguro - o2.coseguro) * 100.0
       / NULLIF(MIN(o1.coseguro, o2.coseguro), 0) > 20);


-- =====================================================================
-- Q1b. Evidencia puntual 2018, TB01, areas A01 y A02.
--      Muestra los valores crudos que alimentan la comparacion.
-- =====================================================================
SELECT f.Anio AS anio,
       t.IdTipoBeneficio AS beneficio,
       a.IdAreaDeServicio AS area,
       h.ID_Proveedor AS proveedor,
       h.ID_Plan AS plan,
       h.ValorCopago,
       h.ValorCoseguro
FROM Hecho_OfertaPlanes h
JOIN Dim_Fecha          f ON h.ID_Fecha          = f.ID_Fecha
JOIN Dim_TipoBeneficio  t ON h.ID_TipoBeneficio  = t.ID_TipoBeneficio
JOIN Dim_AreaDeServicio a ON h.ID_AreaDeServicio = a.ID_AreaDeServicio
WHERE f.Anio = '2018'
  AND t.IdTipoBeneficio = 'TB01'
  AND a.IdAreaDeServicio IN ('A01', 'A02')
ORDER BY a.IdAreaDeServicio, h.ID_Proveedor, h.ID_Plan;


-- =====================================================================
-- Q2. Evolucion anual de copago y coseguro.
--     Se usa AVG porque las medidas son valores por oferta; sumarlas no
--     representa el valor de la oferta. Se excluyen nulos implicitamente.
-- =====================================================================
SELECT f.Anio AS anio,
       COUNT(*) AS ofertas,
       ROUND(AVG(CAST(h.ValorCopago   AS REAL)), 2) AS copago_prom,
       MIN(CAST(h.ValorCopago   AS INTEGER))       AS copago_min,
       MAX(CAST(h.ValorCopago   AS INTEGER))       AS copago_max,
       ROUND(AVG(CAST(h.ValorCoseguro AS REAL)), 2) AS coseguro_prom,
       MIN(CAST(h.ValorCoseguro AS INTEGER))       AS coseguro_min,
       MAX(CAST(h.ValorCoseguro AS INTEGER))       AS coseguro_max
FROM Hecho_OfertaPlanes h
JOIN Dim_Fecha f ON h.ID_Fecha = f.ID_Fecha
GROUP BY f.Anio
ORDER BY f.Anio;


-- Q2b. Evolucion de un tipo de beneficio que cambio de version (TB01).
--      Permite ver la condicion y la unidad de limite vigentes por ano.
SELECT f.Anio AS anio,
       t.IdTipoBeneficio AS beneficio,
       t.UnidadLimite,
       t.Condiciones,
       COUNT(*) AS ofertas,
       ROUND(AVG(CAST(h.ValorCopago   AS REAL)), 2) AS copago_prom,
       ROUND(AVG(CAST(h.ValorCoseguro AS REAL)), 2) AS coseguro_prom
FROM Hecho_OfertaPlanes h
JOIN Dim_Fecha         f ON h.ID_Fecha         = f.ID_Fecha
JOIN Dim_TipoBeneficio t ON h.ID_TipoBeneficio = t.ID_TipoBeneficio
WHERE t.IdTipoBeneficio = 'TB01'
GROUP BY f.Anio, t.IdTipoBeneficio, t.UnidadLimite, t.Condiciones
ORDER BY f.Anio;


-- =====================================================================
-- Q3. Version historica de un area de servicio (A02 cambio de nombre).
--     El hecho guarda la clave subrogada de la version; por eso el join
--     por ID_AreaDeServicio devuelve el nombre vigente en cada ano.
-- =====================================================================
SELECT f.Anio AS anio,
       a.IdAreaDeServicio AS area,
       a.NombreArea,
       a.Estado,
       a.FechaInicio,
       a.FechaFin,
       a.EsActual,
       COUNT(*) AS ofertas
FROM Hecho_OfertaPlanes h
JOIN Dim_Fecha          f ON h.ID_Fecha          = f.ID_Fecha
JOIN Dim_AreaDeServicio a ON h.ID_AreaDeServicio = a.ID_AreaDeServicio
WHERE a.IdAreaDeServicio = 'A02'
GROUP BY f.Anio, a.IdAreaDeServicio, a.NombreArea, a.Estado,
         a.FechaInicio, a.FechaFin, a.EsActual
ORDER BY f.Anio;


-- =====================================================================
-- Q4. Ofertas asociadas al area desconocida (IdAreaDeServicio = '0').
-- =====================================================================
SELECT h.ID_OfertaPlanes,
       f.Anio AS anio,
       a.IdAreaDeServicio AS area,
       a.NombreArea,
       h.LimiteCuantitativo,
       h.ValorCopago,
       h.ValorCoseguro
FROM Hecho_OfertaPlanes h
JOIN Dim_Fecha          f ON h.ID_Fecha          = f.ID_Fecha
JOIN Dim_AreaDeServicio a ON h.ID_AreaDeServicio = a.ID_AreaDeServicio
WHERE a.IdAreaDeServicio = '0'
ORDER BY f.Anio, h.ID_OfertaPlanes;


-- =====================================================================
-- Q5. Limites cuantitativos con valor '333', agrupados por ano y beneficio.
--     '333' es el valor por defecto de la regla de negocio 2.
-- =====================================================================
SELECT f.Anio AS anio,
       t.IdTipoBeneficio AS beneficio,
       COUNT(*) AS ofertas,
       GROUP_CONCAT(DISTINCT h.LimiteCuantitativo) AS valores_limite
FROM Hecho_OfertaPlanes h
JOIN Dim_Fecha         f ON h.ID_Fecha         = f.ID_Fecha
JOIN Dim_TipoBeneficio t ON h.ID_TipoBeneficio = t.ID_TipoBeneficio
WHERE h.LimiteCuantitativo = '333'
GROUP BY f.Anio, t.IdTipoBeneficio
ORDER BY f.Anio, t.IdTipoBeneficio;


-- Q5b. Conteo total de filas con limite '333'.
SELECT COUNT(*) AS filas_limite_333
FROM Hecho_OfertaPlanes
WHERE LimiteCuantitativo = '333';


-- =====================================================================
-- Q6. Cobertura de areas (2.a) por ano.
--     Universo: areas naturales con una version vigente en el ano,
--     excluyendo el area desconocida. El universo se arma con la
--     dimension, no solo con los hechos, para no perder areas sin oferta.
-- =====================================================================
WITH anios AS (
    SELECT DISTINCT Anio FROM Dim_Fecha
),
universo AS (
    SELECT y.Anio AS anio,
           COUNT(DISTINCT a.IdAreaDeServicio) AS total_areas
    FROM anios y
    JOIN Dim_AreaDeServicio a
      ON y.Anio BETWEEN substr(a.FechaInicio, 1, 4)
         AND CASE WHEN a.FechaFin = '9999-12-31' THEN '9999'
                  ELSE substr(a.FechaFin, 1, 4) END
    WHERE a.IdAreaDeServicio <> '0'
    GROUP BY y.Anio
),
cubiertas AS (
    SELECT f.Anio AS anio,
           COUNT(DISTINCT a.IdAreaDeServicio) AS areas_cubiertas
    FROM Hecho_OfertaPlanes h
    JOIN Dim_Fecha          f ON h.ID_Fecha          = f.ID_Fecha
    JOIN Dim_AreaDeServicio a ON h.ID_AreaDeServicio = a.ID_AreaDeServicio
    WHERE a.IdAreaDeServicio <> '0'
    GROUP BY f.Anio
)
SELECT u.anio,
       u.total_areas,
       COALESCE(c.areas_cubiertas, 0) AS areas_cubiertas,
       ROUND(COALESCE(c.areas_cubiertas, 0) * 100.0 / u.total_areas, 2)
           AS cobertura_pct
FROM universo u
LEFT JOIN cubiertas c ON u.anio = c.anio
ORDER BY u.anio;


-- =====================================================================
-- Q7. Cobertura por proveedor (2.b) en cada ano.
--     Compara las areas distintas cubiertas por cada proveedor contra
--     el universo de areas del ano. Responde la lectura individual:
--     "cada proveedor cubre todas las areas".
-- =====================================================================
WITH anios AS (
    SELECT DISTINCT Anio FROM Dim_Fecha
),
universo AS (
    SELECT y.Anio AS anio,
           COUNT(DISTINCT a.IdAreaDeServicio) AS total_areas
    FROM anios y
    JOIN Dim_AreaDeServicio a
      ON y.Anio BETWEEN substr(a.FechaInicio, 1, 4)
         AND CASE WHEN a.FechaFin = '9999-12-31' THEN '9999'
                  ELSE substr(a.FechaFin, 1, 4) END
    WHERE a.IdAreaDeServicio <> '0'
    GROUP BY y.Anio
),
proveedores AS (
    SELECT ID_Proveedor FROM Dim_Proveedor
),
cobertura AS (
    SELECT f.Anio AS anio,
           h.ID_Proveedor AS proveedor,
           COUNT(DISTINCT a.IdAreaDeServicio) AS areas_cubiertas
    FROM Hecho_OfertaPlanes h
    JOIN Dim_Fecha          f ON h.ID_Fecha          = f.ID_Fecha
    JOIN Dim_AreaDeServicio a ON h.ID_AreaDeServicio = a.ID_AreaDeServicio
    WHERE a.IdAreaDeServicio <> '0'
    GROUP BY f.Anio, h.ID_Proveedor
)
SELECT p.ID_Proveedor AS proveedor,
       u.anio,
       u.total_areas,
       COALESCE(c.areas_cubiertas, 0) AS areas_cubiertas,
       CASE WHEN COALESCE(c.areas_cubiertas, 0) = u.total_areas
            THEN 'Si' ELSE 'No' END AS cubre_todas
FROM proveedores p
CROSS JOIN universo u
LEFT JOIN cobertura c
       ON c.proveedor = p.ID_Proveedor
      AND c.anio      = u.anio
ORDER BY u.anio, p.ID_Proveedor;


-- =====================================================================
-- Q8. Areas cubiertas por menos de dos proveedores (2.c).
--     Incluye areas con cero proveedores (sin planes) usando LEFT JOIN
--     contra el universo. Sin ese LEFT JOIN, las areas sin oferta
--     desaparecen y el analisis queda incompleto.
-- =====================================================================
WITH anios AS (
    SELECT DISTINCT Anio FROM Dim_Fecha
),
universo AS (
    SELECT y.Anio AS anio,
           a.IdAreaDeServicio AS area
    FROM anios y
    JOIN Dim_AreaDeServicio a
      ON y.Anio BETWEEN substr(a.FechaInicio, 1, 4)
         AND CASE WHEN a.FechaFin = '9999-12-31' THEN '9999'
                  ELSE substr(a.FechaFin, 1, 4) END
    WHERE a.IdAreaDeServicio <> '0'
),
prov AS (
    SELECT f.Anio AS anio,
           a.IdAreaDeServicio AS area,
           COUNT(DISTINCT h.ID_Proveedor) AS n_prov
    FROM Hecho_OfertaPlanes h
    JOIN Dim_Fecha          f ON h.ID_Fecha          = f.ID_Fecha
    JOIN Dim_AreaDeServicio a ON h.ID_AreaDeServicio = a.ID_AreaDeServicio
    WHERE a.IdAreaDeServicio <> '0'
    GROUP BY f.Anio, a.IdAreaDeServicio
)
SELECT u.anio,
       u.area,
       COALESCE(p.n_prov, 0) AS proveedores,
       CASE WHEN COALESCE(p.n_prov, 0) = 0 THEN 'Sin planes'
            ELSE 'Un solo proveedor' END AS situacion
FROM universo u
LEFT JOIN prov p
       ON p.anio = u.anio
      AND p.area = u.area
WHERE COALESCE(p.n_prov, 0) < 2
ORDER BY u.anio, u.area;


-- =====================================================================
-- Q9. Planes por area y estado (3.a, parte area/estado).
--     No existe columna Condado en el modelo; esta consulta solo cubre
--     el nivel area/estado. COUNT(DISTINCT ID_Plan) evita contar dos
--     veces el mismo plan cuando aparece en varias filas de oferta.
-- =====================================================================
SELECT f.Anio AS anio,
       a.IdAreaDeServicio AS area,
       a.NombreArea,
       a.Estado,
       COUNT(DISTINCT h.ID_Plan)       AS planes_distintos,
       COUNT(*)                        AS filas_oferta,
       COUNT(DISTINCT h.ID_Proveedor)  AS proveedores
FROM Hecho_OfertaPlanes h
JOIN Dim_Fecha          f ON h.ID_Fecha          = f.ID_Fecha
JOIN Dim_AreaDeServicio a ON h.ID_AreaDeServicio = a.ID_AreaDeServicio
WHERE a.IdAreaDeServicio <> '0'
GROUP BY f.Anio, a.IdAreaDeServicio, a.NombreArea, a.Estado
ORDER BY f.Anio, a.Estado, a.IdAreaDeServicio;


-- =====================================================================
-- Q10. Planes por estado y riesgo de duplicacion area -> estado.
--      Compara filas de oferta contra planes distintos. Un conteo de
--      filas por estado sobrecuenta porque un plan puede ofrecerse en
--      varias areas del mismo estado y porque la dimension es SCD2.
-- =====================================================================
SELECT f.Anio AS anio,
       a.Estado,
       COUNT(*)                            AS filas,
       COUNT(DISTINCT h.ID_Plan)           AS planes_distintos,
       COUNT(DISTINCT h.ID_Proveedor)      AS proveedores_distintos,
       COUNT(DISTINCT a.IdAreaDeServicio)  AS areas_distintas
FROM Hecho_OfertaPlanes h
JOIN Dim_Fecha          f ON h.ID_Fecha          = f.ID_Fecha
JOIN Dim_AreaDeServicio a ON h.ID_AreaDeServicio = a.ID_AreaDeServicio
WHERE a.IdAreaDeServicio <> '0'
GROUP BY f.Anio, a.Estado
ORDER BY f.Anio, a.Estado;


-- =====================================================================
-- Q11. Validacion de los dos roles de condicion de pago.
--      Comprueba que ID_CondicionCopago apunte a tipo Copago y
--      ID_CondicionCoseguro a tipo Coseguro en los datos de prueba.
--      El modelo no impone esa restriccion; la consulta la verifica.
-- =====================================================================
SELECT 'Copago' AS rol,
       c.TipoCondicion,
       COUNT(*) AS filas
FROM Hecho_OfertaPlanes h
JOIN Dim_CondicionPago c ON h.ID_CondicionCopago = c.ID_CondicionPago
GROUP BY c.TipoCondicion
UNION ALL
SELECT 'Coseguro',
       c.TipoCondicion,
       COUNT(*)
FROM Hecho_OfertaPlanes h
JOIN Dim_CondicionPago c ON h.ID_CondicionCoseguro = c.ID_CondicionPago
GROUP BY c.TipoCondicion
ORDER BY 1, 2;


-- =====================================================================
-- Q12. Versiones SCD vs claves naturales.
--      Muestra por que un join por clave natural puede duplicar filas:
--      hay mas versiones que entidades naturales.
-- =====================================================================
SELECT 'Dim_TipoBeneficio' AS dimension,
       COUNT(*) AS versiones,
       COUNT(DISTINCT IdTipoBeneficio) AS naturales
FROM Dim_TipoBeneficio
UNION ALL
SELECT 'Dim_AreaDeServicio',
       COUNT(*),
       COUNT(DISTINCT IdAreaDeServicio)
FROM Dim_AreaDeServicio;


-- =====================================================================
-- Q13. Maximos 2018 (regla de negocio 6).
-- =====================================================================
SELECT MAX(CAST(h.ValorCopago   AS INTEGER)) AS max_copago,
       MAX(CAST(h.ValorCoseguro AS INTEGER)) AS max_coseguro
FROM Hecho_OfertaPlanes h
JOIN Dim_Fecha f ON h.ID_Fecha = f.ID_Fecha
WHERE f.Anio = '2018';


-- =====================================================================
-- Q14. Estructura de Dim_AreaDeServicio: evidencia de que no existen
--      Condado ni Poblacion.
-- =====================================================================
SELECT name, type
FROM pragma_table_info('Dim_AreaDeServicio');


-- =====================================================================
-- Q15. Busqueda de columnas de condado o poblacion en las siete tablas.
--      Devuelve 0 filas: el modelo no almacena esa informacion.
-- =====================================================================
SELECT 'Dim_AreaDeServicio' AS tabla, name AS columna
FROM pragma_table_info('Dim_AreaDeServicio')
WHERE lower(name) LIKE '%condado%' OR lower(name) LIKE '%poblaci%'
   OR lower(name) LIKE '%habitante%'
UNION ALL
SELECT 'Hecho_OfertaPlanes', name
FROM pragma_table_info('Hecho_OfertaPlanes')
WHERE lower(name) LIKE '%condado%' OR lower(name) LIKE '%poblaci%'
   OR lower(name) LIKE '%habitante%'
UNION ALL
SELECT 'Dim_Fecha', name
FROM pragma_table_info('Dim_Fecha')
WHERE lower(name) LIKE '%condado%' OR lower(name) LIKE '%poblaci%'
   OR lower(name) LIKE '%habitante%'
UNION ALL
SELECT 'Dim_Plan', name
FROM pragma_table_info('Dim_Plan')
WHERE lower(name) LIKE '%condado%' OR lower(name) LIKE '%poblaci%'
   OR lower(name) LIKE '%habitante%'
UNION ALL
SELECT 'Dim_Proveedor', name
FROM pragma_table_info('Dim_Proveedor')
WHERE lower(name) LIKE '%condado%' OR lower(name) LIKE '%poblaci%'
   OR lower(name) LIKE '%habitante%'
UNION ALL
SELECT 'Dim_TipoBeneficio', name
FROM pragma_table_info('Dim_TipoBeneficio')
WHERE lower(name) LIKE '%condado%' OR lower(name) LIKE '%poblaci%'
   OR lower(name) LIKE '%habitante%'
UNION ALL
SELECT 'Dim_CondicionPago', name
FROM pragma_table_info('Dim_CondicionPago')
WHERE lower(name) LIKE '%condado%' OR lower(name) LIKE '%poblaci%'
   OR lower(name) LIKE '%habitante%';


-- =====================================================================
-- Q16. Planes distintos y ofertas por ano (contexto de 2.a y 3.a).
-- =====================================================================
SELECT f.Anio AS anio,
       COUNT(DISTINCT h.ID_Plan) AS planes_distintos,
       COUNT(*) AS ofertas
FROM Hecho_OfertaPlanes h
JOIN Dim_Fecha f ON h.ID_Fecha = f.ID_Fecha
GROUP BY f.Anio
ORDER BY f.Anio;
