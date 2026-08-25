BEGIN;

-- ============================================================
-- TYPE D
-- Б.17, Б.18, Б.19, Б.20
-- Сложная конфигурация конкретного типа трубы
-- ============================================================


-- ============================================================
-- 1. ВОПРОСЫ, которые могут понадобиться для выбора строки
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
VALUES

(
    'PIPE_SIZE',
    'Типоразмер трубопровода',
    'Выберите типоразмер трубопровода',
    'ROW_SELECTION',
    'select',
    NULL,
    100,
    'QH_ROWS',
    true
),

(
    'PRESSURE_PIPE_INNER_DIAMETER',
    'Внутренний диаметр напорной трубы',
    'Выберите внутренний диаметр напорной трубы',
    'ROW_SELECTION',
    'select',
    'мм',
    110,
    'QH_ROWS',
    true
),

(
    'PRESSURE_PIPE_OUTER_DIAMETER',
    'Наружный диаметр напорной трубы',
    'Выберите наружный диаметр напорной трубы',
    'ROW_SELECTION',
    'select',
    'мм',
    120,
    'QH_ROWS',
    true
),

(
    'PRESSURE_PIPE_WALL_THICKNESS',
    'Толщина стенки напорной трубы',
    'Выберите толщину стенки напорной трубы',
    'ROW_SELECTION',
    'select',
    'мм',
    130,
    'QH_ROWS',
    true
),

(
    'SHELL_OUTER_DIAMETER',
    'Наружный диаметр трубы-оболочки',
    'Выберите наружный диаметр трубы-оболочки',
    'ROW_SELECTION',
    'select',
    'мм',
    140,
    'QH_ROWS',
    true
),

(
    'SHELL_WALL_THICKNESS',
    'Толщина стенки трубы-оболочки',
    'Выберите толщину стенки трубы-оболочки',
    'ROW_SELECTION',
    'select',
    'мм',
    150,
    'QH_ROWS',
    true
),

(
    'THERMAL_RESISTANCE',
    'Термическое сопротивление трубопровода',
    'Выберите термическое сопротивление трубопровода',
    'ROW_SELECTION',
    'select',
    'м·°C/Вт',
    160,
    'QH_ROWS',
    true
),

(
    'AXIS_DISTANCE',
    'Расстояние между осями трубопроводов',
    'Выберите расстояние между осями трубопроводов',
    'ROW_SELECTION',
    'select',
    'м',
    160,
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
    selection_order = EXCLUDED.selection_order,
    option_source = EXCLUDED.option_source,
    is_active = EXCLUDED.is_active;


-- ============================================================
-- 2. DIMENSIONS
-- ============================================================

INSERT INTO qh_dimensions (
    code,
    question_code,
    value_type,
    unit,
    description
)
VALUES

(
    'PIPE_SIZE',
    'PIPE_SIZE',
    'TEXT',
    NULL,
    'Типоразмер трубопровода'
),

(
    'PRESSURE_PIPE_INNER_DIAMETER',
    'PRESSURE_PIPE_INNER_DIAMETER',
    'NUMBER',
    'мм',
    'Внутренний диаметр напорной трубы'
),

(
    'PRESSURE_PIPE_OUTER_DIAMETER',
    'PRESSURE_PIPE_OUTER_DIAMETER',
    'NUMBER',
    'мм',
    'Наружный диаметр напорной трубы'
),

(
    'PRESSURE_PIPE_WALL_THICKNESS',
    'PRESSURE_PIPE_WALL_THICKNESS',
    'NUMBER',
    'мм',
    'Толщина стенки напорной трубы'
),

(
    'SHELL_OUTER_DIAMETER',
    'SHELL_OUTER_DIAMETER',
    'NUMBER',
    'мм',
    'Наружный диаметр трубы-оболочки'
),

(
    'SHELL_WALL_THICKNESS',
    'SHELL_WALL_THICKNESS',
    'NUMBER',
    'мм',
    'Толщина стенки трубы-оболочки'
),

(
    'THERMAL_RESISTANCE',
    'THERMAL_RESISTANCE',
    'NUMBER',
    'м·°C/Вт',
    'Термическое сопротивление трубопровода'
),

(
    'AXIS_DISTANCE',
    'AXIS_DISTANCE',
    'NUMBER',
    'м',
    'Расстояние между осями трубопроводов'
)

ON CONFLICT (code)
DO UPDATE SET
    question_code = EXCLUDED.question_code,
    value_type = EXCLUDED.value_type,
    unit = EXCLUDED.unit,
    description = EXCLUDED.description;


-- ============================================================
-- 3. Удаляем старые связи только для TYPE D
-- ============================================================

DELETE FROM qh_table_dimensions
WHERE table_id IN (
    SELECT id
    FROM qh_tables
    WHERE code IN (
        'Б.17',
        'Б.18',
        'Б.19',
        'Б.20'
    )
);


-- ============================================================
-- 4. Б.17
--
-- Колонки источника:
-- TYPE SIZE
-- наружный диаметр напорной трубы
-- толщина стенки напорной трубы
-- наружный диаметр оболочки
-- толщина стенки оболочки
-- высота канала
-- ширина канала
-- термическое сопротивление
--
-- CHANNEL_HEIGHT / CHANNEL_WIDTH = metadata
-- Остальные могут определять конкретную строку.
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
        ('PRESSURE_PIPE_OUTER_DIAMETER',  2, true),
        ('PRESSURE_PIPE_WALL_THICKNESS',  3, true),
        ('SHELL_OUTER_DIAMETER',          4, true),
        ('SHELL_WALL_THICKNESS',          5, true),
        ('CHANNEL_HEIGHT',                 6, false),
        ('CHANNEL_WIDTH',                  7, false),
        ('THERMAL_RESISTANCE',             8, true)
) AS x(dimension_code, sequence_no, is_selector)
    ON true
JOIN qh_dimensions d
    ON d.code = x.dimension_code
WHERE t.code = 'Б.17';


-- ============================================================
-- 5. Б.18
--
-- Вместо параметров канала:
-- AXIS_DISTANCE
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
        ('PRESSURE_PIPE_OUTER_DIAMETER',  2, true),
        ('PRESSURE_PIPE_WALL_THICKNESS',  3, true),
        ('SHELL_OUTER_DIAMETER',          4, true),
        ('SHELL_WALL_THICKNESS',          5, true),
        ('AXIS_DISTANCE',                  6, true)
) AS x(dimension_code, sequence_no, is_selector)
    ON true
JOIN qh_dimensions d
    ON d.code = x.dimension_code
WHERE t.code = 'Б.18';


-- ============================================================
-- 6. Б.19
--
-- Здесь дополнительно есть:
-- PRESSURE_PIPE_INNER_DIAMETER
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
        ('PRESSURE_PIPE_INNER_DIAMETER',  2, true),
        ('PRESSURE_PIPE_OUTER_DIAMETER',  3, true),
        ('PRESSURE_PIPE_WALL_THICKNESS',  4, true),
        ('SHELL_OUTER_DIAMETER',          5, true),
        ('SHELL_WALL_THICKNESS',          6, true),
        ('CHANNEL_HEIGHT',                 7, false),
        ('CHANNEL_WIDTH',                  8, false),
        ('THERMAL_RESISTANCE',             9, true)
) AS x(dimension_code, sequence_no, is_selector)
    ON true
JOIN qh_dimensions d
    ON d.code = x.dimension_code
WHERE t.code = 'Б.19';


-- ============================================================
-- 7. Б.20
--
-- Как Б.19, но вместо параметров канала:
-- AXIS_DISTANCE
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
        ('PRESSURE_PIPE_INNER_DIAMETER',  2, true),
        ('PRESSURE_PIPE_OUTER_DIAMETER',  3, true),
        ('PRESSURE_PIPE_WALL_THICKNESS',  4, true),
        ('SHELL_OUTER_DIAMETER',          5, true),
        ('SHELL_WALL_THICKNESS',          6, true),
        ('AXIS_DISTANCE',                  7, true)
) AS x(dimension_code, sequence_no, is_selector)
    ON true
JOIN qh_dimensions d
    ON d.code = x.dimension_code
WHERE t.code = 'Б.20';


COMMIT;