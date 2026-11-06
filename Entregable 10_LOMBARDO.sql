Use Ventas_Tech_DB



   ---- Parte 1: Analizando la consistencia de ventas — caso guiado

   SELECT
    sucursal,
    AVG(venta) AS media_ventas
FROM dbo.ventas_semana
GROUP BY sucursal;



-- PARTE 2: MEDIA Y MEDIANA

WITH Totales AS (
    SELECT
        id_venta,
        SUM(cantidad * precio_unitario) AS total_venta
    FROM dbo.ventas
    GROUP BY id_venta
)
SELECT
    AVG(total_venta) AS Media,
    (SELECT TOP 1
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY total_venta) OVER()
     FROM Totales) AS Mediana
FROM Totales;



--- IQR
WITH Totales AS (
    SELECT
        id_venta,
        SUM(cantidad * precio_unitario) AS total_venta
    FROM dbo.ventas
    GROUP BY id_venta
),
Cuartiles AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.25)
            WITHIN GROUP (ORDER BY total_venta) OVER () AS Q1,
        PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY total_venta) OVER () AS Q3
    FROM Totales
),
Limites AS (
    SELECT
        Q1,
        Q3,
        Q3 - Q1 AS IQR,
        Q1 - 1.5 * (Q3 - Q1) AS limite_inferior,
        Q3 + 1.5 * (Q3 - Q1) AS limite_superior
    FROM Cuartiles
)
SELECT
    T.id_venta,
    T.total_venta,
    L.Q1,
    L.Q3,
    L.IQR,
    L.limite_inferior,
    L.limite_superior,
    CASE
        WHEN T.total_venta < L.limite_inferior
          OR T.total_venta > L.limite_superior
        THEN 'Outlier'
        ELSE 'Normal'
    END AS clasificacion
FROM Totales T
CROSS JOIN Limites L
ORDER BY T.total_venta DESC;

-- VISUALIZACION DE VENTAS OUTLINER

SELECT
    v.id_venta,
    v.id_producto,
    p.nombre_producto,
    v.cantidad,
    v.precio_unitario,
    (v.cantidad * v.precio_unitario) AS total_producto
FROM dbo.ventas v
INNER JOIN dbo.productos p
    ON v.id_producto = p.id_producto
WHERE v.id_venta IN (1, 11)
ORDER BY v.id_venta;