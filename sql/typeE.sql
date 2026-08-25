BEGIN;

-- ============================================================
-- TYPE E
-- Г.1, Г.2, Г.7
--
-- OUTER_DIAMETER = выбирает строку
-- PLACEMENT_VARIANT = выбирает вариант размещения
-- temperature_c = выбирает температурную колонку
-- ============================================================


-- ============================================================
-- 1. Вопрос: вариант размещения
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
    'PLACEMENT_VARIANT',
    'Вариант размещения трубопровода',
    'Выберите вариант размещения трубопровода',
    'TEMPERATURE',
    'select',
    NULL,
    100,
    'STATIC',
    true
)
ON CONFLICT (code)
DO UPDATE SET
    label = EXCLUDED.label,
    description = EXCLUDED.description,
    phase = EXCLUDED.phase,
    input_type = EXCLUDED.input_type,
    unit = EXCLUDED.unit,
    selection_order = EXCLUDED.selection_order,
    option_source = EXCLUDED.option_source,
    is_active = EXCLUDED.is_active;


-- ============================================================
-- 2. Варианты размещения
-- ============================================================

INSERT INTO question_options (
    question_code,
    value,
    label,
    sort_order,
    is_active
)
VALUES
(
    'PLACEMENT_VARIANT',
    'ROOM',
    'Помещение (техническое подполье)',
    10,
    true
),
(
    'PLACEMENT_VARIANT',
    'TUNNEL',
    'Тоннель (проходной канал)',
    20,
    true
)
ON CONFLICT (question_code, value)
DO UPDATE SET
    label = EXCLUDED.label,
    sort_order = EXCLUDED.sort_order,
    is_active = EXCLUDED.is_active;


-- ============================================================
-- 3. Удаляем старую конфигурацию dimensions
--    только для Г.1, Г.2, Г.7
-- ============================================================

DELETE FROM qh_table_dimensions
WHERE table_id IN (
    SELECT id
    FROM qh_tables
    WHERE code IN (
        'Г.1',
        'Г.2',
        'Г.7'
    )
);


-- ============================================================
-- 4. Для Г.1, Г.2, Г.7 строка выбирается
--    по OUTER_DIAMETER
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
    1,
    true
FROM qh_tables t
JOIN qh_dimensions d
    ON d.code = 'OUTER_DIAMETER'
WHERE t.code IN (
    'Г.1',
    'Г.2',
    'Г.7'
);


COMMIT;