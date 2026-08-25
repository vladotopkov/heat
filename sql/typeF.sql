BEGIN;

-- ============================================================
-- TYPE F
-- В.3, В.4, В.5, В.6, Г.5, Г.6
--
-- В одной таблице:
--
-- PIPE:
--   NOMINAL_BORE
--   qh в Вт/м
--
-- SURFACE:
--   без NOMINAL_BORE
--   qh в Вт/м²
--
-- Общая температурная шкала через temperature_c
-- ============================================================


-- ============================================================
-- 1. qh_values:
--    qh_w_per_m -> универсальное qh_value
-- ============================================================

ALTER TABLE qh_values
RENAME COLUMN qh_w_per_m TO qh_value;


-- ============================================================
-- 2. Добавляем тип плотности:
--
-- LINEAR  = Вт/м
-- SURFACE = Вт/м²
-- ============================================================

ALTER TABLE qh_values
ADD COLUMN density_kind varchar(20) NOT NULL DEFAULT 'LINEAR';

ALTER TABLE qh_values
ADD CONSTRAINT chk_qh_values_density_kind
CHECK (
    density_kind IN (
        'LINEAR',
        'SURFACE'
    )
);


-- ============================================================
-- 3. Обновляем UNIQUE qh_values
--    TYPE A уже добавил temperature_c
-- ============================================================

ALTER TABLE qh_values
DROP CONSTRAINT IF EXISTS uq_qh_values_coordinates;

ALTER TABLE qh_values
ADD CONSTRAINT uq_qh_values_coordinates
UNIQUE NULLS NOT DISTINCT (
    row_id,
    pipeline_role,
    placement_variant,
    density_kind,
    temperature_c,
    supply_temperature_c,
    return_temperature_c
);


-- ============================================================
-- 4. qh_results:
--    результат тоже должен поддерживать Вт/м и Вт/м²
-- ============================================================

ALTER TABLE qh_results
RENAME COLUMN base_qh_w_per_m TO base_qh_value;

ALTER TABLE qh_results
RENAME COLUMN adjusted_qh_w_per_m TO adjusted_qh_value;


ALTER TABLE qh_results
ADD COLUMN density_kind varchar(20) NOT NULL DEFAULT 'LINEAR';

ALTER TABLE qh_results
ADD CONSTRAINT chk_qh_results_density_kind
CHECK (
    density_kind IN (
        'LINEAR',
        'SURFACE'
    )
);


-- На случай если TYPE A уже добавил поле,
-- второй раз оно не создастся.

ALTER TABLE qh_results
ADD COLUMN IF NOT EXISTS calculated_temperature_c numeric;


-- ============================================================
-- 5. Вопрос:
--    что рассчитывается?
--
-- PIPE    = обычный трубопровод
-- SURFACE = криволинейная поверхность >1020 мм
--           или плоская поверхность
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
    'OBJECT_KIND',
    'Тип объекта',
    'Выберите тип объекта',
    'ROW_SELECTION',
    'select',
    NULL,
    90,
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
-- 6. Варианты OBJECT_KIND
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
    'OBJECT_KIND',
    'PIPE',
    'Трубопровод',
    10,
    true
),

(
    'OBJECT_KIND',
    'SURFACE',
    'Криволинейная поверхность диаметром более 1020 мм или плоская поверхность',
    20,
    true
)

ON CONFLICT (question_code, value)
DO UPDATE SET
    label = EXCLUDED.label,
    sort_order = EXCLUDED.sort_order,
    is_active = EXCLUDED.is_active;


-- ============================================================
-- 7. DIMENSION OBJECT_KIND
-- ============================================================

INSERT INTO qh_dimensions (
    code,
    question_code,
    value_type,
    unit,
    description
)
VALUES (
    'OBJECT_KIND',
    'OBJECT_KIND',
    'TEXT',
    NULL,
    'Тип объекта: трубопровод или поверхность'
)
ON CONFLICT (code)
DO UPDATE SET
    question_code = EXCLUDED.question_code,
    value_type = EXCLUDED.value_type,
    unit = EXCLUDED.unit,
    description = EXCLUDED.description;


-- ============================================================
-- 8. Удаляем старую конфигурацию dimensions
--    только для TYPE F
-- ============================================================

DELETE FROM qh_table_dimensions
WHERE table_id IN (
    SELECT id
    FROM qh_tables
    WHERE code IN (
        'В.3',
        'В.4',
        'В.5',
        'В.6',
        'Г.5',
        'Г.6'
    )
);


-- ============================================================
-- 9. Привязываем dimensions ко всем таблицам TYPE F
--
-- OBJECT_KIND:
--   сначала определяем PIPE / SURFACE
--
-- NOMINAL_BORE:
--   нужен только для PIPE
--
-- Для SURFACE у строки просто НЕ будет
-- значения NOMINAL_BORE в qh_row_dimension_values.
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
        ('OBJECT_KIND',  1, true),
        ('NOMINAL_BORE', 2, true)
) AS x(dimension_code, sequence_no, is_selector)
    ON true
JOIN qh_dimensions d
    ON d.code = x.dimension_code
WHERE t.code IN (
    'В.3',
    'В.4',
    'В.5',
    'В.6',
    'Г.5',
    'Г.6'
);


COMMIT;