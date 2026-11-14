# Caso de negocio – RaSa / Infraestructura Visible: proceso OfertaPlanes

## Contexto
Infraestructura Visible solicita modelar multidimensionalmente la base de datos de RaSa
para los análisis del proyecto. El proceso de negocio es **OfertaPlanes**, que se realiza
de forma **anual**: cada año los proveedores ofrecen planes de salud con beneficios en
áreas de servicio, y cada beneficio tiene condiciones de pago (copago y coseguro) y
límites cuantitativos.

El modelo debe incluir la **historia de los atributos de las dimensiones**, permitir la
mayoría de los análisis propuestos e involucrar los datos de las fuentes compartidas para
que sirva también para análisis futuros.

## Análisis requeridos (categoría: tableros de control, proceso: Oferta de planes)

| Tema analítico | Análisis | Fuentes |
|---|---|---|
| Valores de copago y coseguro (competencia desleal) | 1.a Dado un proveedor o grupo de proveedores, identificar posible competencia desleal: proveedores que brindan planes con el mismo tipo de beneficio cuyo valor de copago o coseguro evidencia diferencias mayores al 20 %. | F2, F3, F4 |
| Cobertura de planes | 2.a Dado un rango de años, mostrar el nivel de cobertura de los planes con respecto a las áreas de servicio. | F1, F3 |
| | 2.b ¿Se ha logrado una cobertura total de los proveedores, cubriendo con sus planes TODAS las áreas de servicio? | F1, F3 |
| | 2.c ¿Han existido áreas de servicio que sean cubiertas, a nivel de planes, por menos de dos proveedores? | F1, F3 |
| Concentraciones de planes | 3.a Dado un rango de años, ¿cuántos y cuáles planes hay por áreas de servicio y estados o condados? | F1, F3 |
| | 3.b ¿En qué áreas, estados o condados hay concentraciones de planes que no correspondan con la cantidad de habitantes del área? | F1, F3 |

Nota: el enunciado del análisis 1.a aparece incompleto en la guía; se toma la parte visible.
Las fuentes asociadas a 1.a son una inferencia (tipo de beneficio, copago/coseguro y su condición).

## Fuentes (base RasaTransaccional)
- F1. AreasdeServicio: `FuenteAreasDeServicio_Copia_E`
- F2. TiposBeneficios: `FuenteTiposBeneficio_Copia_E`
- F3. BeneficiosPlanes: `FuentePlanesBeneficio_Copia_E`
- F4. Tablas de referencia: `FuenteCondicionesDePago_Copia_E`

## Respuestas del negocio (reglas que afectan el modelo y la carga)
1. Las áreas de servicio NO cubren todos los condados del país.
2. Límites cuantitativos sin valor o en cero, en planes que los ofrecen → valor por defecto **333**.
3. Se corrigió la fecha 1800 en la fuente de áreas de servicio.
4. La fuente de áreas de servicio tenía solo 2017 y 2018; faltaba 2019.
5. En tipos de beneficio solo debe existir un valor de condiciones y unidad de límite por tipo de beneficio **por año**.
6. Valor máximo 2018: Copago 3500 y Coseguro 100.
7. En condiciones de pago se eliminaron registros con mismo tipo y descripción y distinto identificador.

Indicaciones adicionales de RaSa:
- Planes beneficio: aún existen `IdAreaDeServicio` que no están en la fuente de áreas → crear registro **Desconocido (Identificador = 0)** y NO omitirlos. Fechas con otros formatos → transformar a `YYYY-MM-DD`.
- Tipos de beneficio: valores de condiciones inconsistentes → dejar solo **"Yes" / "No"**.
- Áreas de servicio: se eliminaron duplicados con distinto `IdGeografia` y mismo contenido; áreas negativas → multiplicar por -1 y corregir la escala (ej.: 27540001 → 2754).
- Condiciones de pago: tipo debe quedar solo **Copago** o **Coseguro**.
- Pueden existir duplicados en todas las fuentes → eliminarlos.
