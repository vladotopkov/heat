BEGIN;

-- ============================================================
-- TYPE G
-- Г.3, Г.4
--
-- Комбинация TYPE E + TYPE F:
--
-- OBJECT_KIND:
--   PIPE
--   SURFACE
--
-- Для PIPE:
--   NOMINAL_BORE
--
-- В qh_values:
--   placement_variant = ROOM / TUNNEL
--   density_kind      = LINEAR / SURFACE
--   temperature_c     = температура
-- ============================================================


-- ============================================================
-- 1. Удаляем старую конфигурацию dimensions
--    только для Г.3 и Г.4
-- ============================================================

DELETE FROM qh_table_dimensions
WHERE table_id IN (
    SELECT id
    FROM qh_tables
    WHERE code IN (
        'Г.3',
        'Г.4'
    )
);


-- ============================================================
-- 2. Привязываем dimensions к Г.3 и Г.4
--
-- Сначала спрашиваем:
--   OBJECT_KIND = PIPE / SURFACE
--
-- Если PIPE:
--   затем NOMINAL_BORE
--
-- Если SURFACE:
--   NOMINAL_BORE у строки отсутствует
-- ============================================================

INSERT INTO qh_table_dimensions (
    table_id,
    dimension_id,
    sequence_no,
    is_selector
)
SELECT
    t.id,
    d.id,
    x.sequence_no,
    true
FROM qh_tables t
JOIN (
    VALUES
        ('OBJECT_KIND',  1),
        ('NOMINAL_BORE', 2)
) AS x(dimension_code, sequence_no)
    ON true
JOIN qh_dimensions d
    ON d.code = x.dimension_code
WHERE t.code IN (
    'Г.3',
    'Г.4'
);


COMMIT;