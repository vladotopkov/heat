BEGIN;

-- ============================================================
-- TYPE H
-- Г.8
--
-- Сложный типоразмер трубы
--
-- SELECTOR:
--   PIPE_SIZE
--
-- METADATA:
--   PRESSURE_PIPE_INNER_DIAMETER
--   PRESSURE_PIPE_OUTER_DIAMETER
--   PRESSURE_PIPE_WALL_THICKNESS
--   SHELL_OUTER_DIAMETER
--   SHELL_WALL_THICKNESS
--
-- qh:
--   RETURN  = 50 °C
--   SUPPLY  = 65 °C
--
-- TWO_PIPE_TOTAL отсутствует
-- ============================================================


-- ============================================================
-- 1. Удаляем старую конфигурацию dimensions для Г.8
-- ============================================================

DELETE FROM qh_table_dimensions
WHERE table_id IN (
    SELECT id
    FROM qh_tables
    WHERE code = 'Г.8'
);


-- ============================================================
-- 2. Привязываем dimensions к Г.8
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
    x.is_selector
FROM qh_tables t
JOIN (
    VALUES
        ('PIPE_SIZE',                     1, true),

        ('PRESSURE_PIPE_INNER_DIAMETER',  2, false),
        ('PRESSURE_PIPE_OUTER_DIAMETER',  3, false),
        ('PRESSURE_PIPE_WALL_THICKNESS',  4, false),

        ('SHELL_OUTER_DIAMETER',          5, false),
        ('SHELL_WALL_THICKNESS',          6, false)

) AS x(dimension_code, sequence_no, is_selector)
    ON true

JOIN qh_dimensions d
    ON d.code = x.dimension_code

WHERE t.code = 'Г.8';


COMMIT;