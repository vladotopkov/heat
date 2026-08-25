BEGIN;

-- ============================================================
-- TYPE C
-- Б.15, Б.16, Б.21, Б.22
--
-- Б.15 / Б.21:
--   OUTER_DIAMETER
--   CHANNEL_HEIGHT
--   CHANNEL_WIDTH
--   THERMAL_RESISTANCE
--
-- Б.16 / Б.22:
--   OUTER_DIAMETER
--   BURIAL_DEPTH
--   AXIS_DISTANCE
--
-- Для выбора строки пользователь выбирает только OUTER_DIAMETER.
-- Остальные параметры хранятся как характеристики строки.
-- ============================================================


-- ============================================================
-- 1. Разрешаем dimension существовать без вопроса пользователю
-- ============================================================

ALTER TABLE qh_dimensions
ALTER COLUMN question_code DROP NOT NULL;


-- ============================================================
-- 2. Добавляем признак:
--    участвует ли dimension в выборе строки
-- ============================================================

ALTER TABLE qh_table_dimensions
ADD COLUMN IF NOT EXISTS is_selector boolean NOT NULL DEFAULT true;


-- ============================================================
-- 3. Вопрос OUTER_DIAMETER
--    Если уже создан для TYPE A, ничего не произойдет
-- ============================================================

INSERT INTO questions (
    code,
    label,
    description,
    phase,
    input_type,
    unit,
    selection_order,
    option_source,
    is_active
)
VALUES (
    'OUTER_DIAMETER',
    'Наружный диаметр трубопровода',
    'Выберите наружный диаметр трубопровода',
    'ROW_SELECTION',
    'select',
    'мм',
    100,
    'QH_ROWS',
    true
)
ON CONFLICT (code)
DO UPDATE SET
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    phase = EXCLUDED.phase,
    input_type = EXCLUDED.input_type,
    unit = EXCLUDED.unit,
    option_source = EXCLUDED.option_source,
    is_active = EXCLUDED.is_active;


-- ============================================================
-- 4. DIMENSION: наружный диаметр
--    Это SELECTOR, поэтому связан с вопросом
-- ============================================================

INSERT INTO qh_dimensions (
    code,
    question_code,
    value_type,
    unit,
    description
)
VALUES (
    'OUTER_DIAMETER',
    'OUTER_DIAMETER',
    'NUMBER',
    'мм',
    'Наружный диаметр трубопровода'
)
ON CONFLICT (code)
DO UPDATE SET
    question_code = EXCLUDED.question_code,
    value_type = EXCLUDED.value_type,
    unit = EXCLUDED.unit,
    description = EXCLUDED.description;


-- ============================================================
-- 5. DIMENSION: высота канала
--    Только характеристика нормативной строки
-- ============================================================

INSERT INTO qh_dimensions (
    code,
    question_code,
    value_type,
    unit,
    description
)
VALUES (
    'CHANNEL_HEIGHT',
    NULL,
    'NUMBER',
    'м',
    'Высота канала'
)
ON CONFLICT (code)
DO UPDATE SET
    question_code = NULL,
    value_type = EXCLUDED.value_type,
    unit = EXCLUDED.unit,
    description = EXCLUDED.description;


-- ============================================================
-- 6. DIMENSION: ширина канала
-- ============================================================

INSERT INTO qh_dimensions (
    code,
    question_code,
    value_type,
    unit,
    description
)
VALUES (
    'CHANNEL_WIDTH',
    NULL,
    'NUMBER',
    'м',
    'Ширина канала'
)
ON CONFLICT (code)
DO UPDATE SET
    question_code = NULL,
    value_type = EXCLUDED.value_type,
    unit = EXCLUDED.unit,
    description = EXCLUDED.description;


-- ============================================================
-- 7. DIMENSION: термическое сопротивление
-- ============================================================

INSERT INTO qh_dimensions (
    code,
    question_code,
    value_type,
    unit,
    description
)
VALUES (
    'THERMAL_RESISTANCE',
    NULL,
    'NUMBER',
    'м·°C/Вт',
    'Термическое сопротивление трубопровода'
)
ON CONFLICT (code)
DO UPDATE SET
    question_code = NULL,
    value_type = EXCLUDED.value_type,
    unit = EXCLUDED.unit,
    description = EXCLUDED.description;


-- ============================================================
-- 8. DIMENSION: глубина залегания трубопровода
-- ============================================================

INSERT INTO qh_dimensions (
    code,
    question_code,
    value_type,
    unit,
    description
)
VALUES (
    'BURIAL_DEPTH',
    NULL,
    'NUMBER',
    'м',
    'Глубина залегания трубопровода'
)
ON CONFLICT (code)
DO UPDATE SET
    question_code = NULL,
    value_type = EXCLUDED.value_type,
    unit = EXCLUDED.unit,
    description = EXCLUDED.description;


-- ============================================================
-- 9. DIMENSION: расстояние между осями трубопроводов
-- ============================================================

INSERT INTO qh_dimensions (
    code,
    question_code,
    value_type,
    unit,
    description
)
VALUES (
    'AXIS_DISTANCE',
    NULL,
    'NUMBER',
    'м',
    'Расстояние между осями трубопроводов'
)
ON CONFLICT (code)
DO UPDATE SET
    question_code = NULL,
    value_type = EXCLUDED.value_type,
    unit = EXCLUDED.unit,
    description = EXCLUDED.description;


-- ============================================================
-- 10. Очищаем старую конфигурацию dimensions
--     только для Б.15, Б.16, Б.21, Б.22
-- ============================================================

DELETE FROM qh_table_dimensions
WHERE table_id IN (
    SELECT id
    FROM qh_tables
    WHERE code IN (
        'Б.15',
        'Б.16',
        'Б.21',
        'Б.22'
    )
);


-- ============================================================
-- 11. Б.15
--
-- SELECTOR:
--   OUTER_DIAMETER
--
-- METADATA:
--   CHANNEL_HEIGHT
--   CHANNEL_WIDTH
--   THERMAL_RESISTANCE
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
        ('OUTER_DIAMETER',      1, true),
        ('CHANNEL_HEIGHT',      2, false),
        ('CHANNEL_WIDTH',       3, false),
        ('THERMAL_RESISTANCE',  4, false)
) AS x(dimension_code, sequence_no, is_selector)
    ON true
JOIN qh_dimensions d
    ON d.code = x.dimension_code
WHERE t.code = 'Б.15';


-- ============================================================
-- 12. Б.16
--
-- SELECTOR:
--   OUTER_DIAMETER
--
-- METADATA:
--   BURIAL_DEPTH
--   AXIS_DISTANCE
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
        ('OUTER_DIAMETER', 1, true),
        ('BURIAL_DEPTH',   2, false),
        ('AXIS_DISTANCE',  3, false)
) AS x(dimension_code, sequence_no, is_selector)
    ON true
JOIN qh_dimensions d
    ON d.code = x.dimension_code
WHERE t.code = 'Б.16';


-- ============================================================
-- 13. Б.21
--
-- SELECTOR:
--   OUTER_DIAMETER
--
-- METADATA:
--   CHANNEL_HEIGHT
--   CHANNEL_WIDTH
--   THERMAL_RESISTANCE
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
        ('OUTER_DIAMETER',      1, true),
        ('CHANNEL_HEIGHT',      2, false),
        ('CHANNEL_WIDTH',       3, false),
        ('THERMAL_RESISTANCE',  4, false)
) AS x(dimension_code, sequence_no, is_selector)
    ON true
JOIN qh_dimensions d
    ON d.code = x.dimension_code
WHERE t.code = 'Б.21';


-- ============================================================
-- 14. Б.22
--
-- SELECTOR:
--   OUTER_DIAMETER
--
-- METADATA:
--   BURIAL_DEPTH
--   AXIS_DISTANCE
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
        ('OUTER_DIAMETER', 1, true),
        ('BURIAL_DEPTH',   2, false),
        ('AXIS_DISTANCE',  3, false)
) AS x(dimension_code, sequence_no, is_selector)
    ON true
JOIN qh_dimensions d
    ON d.code = x.dimension_code
WHERE t.code = 'Б.22';


COMMIT;