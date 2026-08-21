BEGIN;

-- ============================================================
-- ОЧИСТКА ДАННЫХ ДЛЯ ПОВТОРНОГО ЗАПУСКА ДЕМКИ
-- ============================================================

TRUNCATE TABLE
    qh_results,
    questionnaire_answers,
    questionnaire_sessions,
    qh_material_coefficients,
    qh_adjustment_rules,
    qh_values,
    qh_row_dimension_values,
    qh_rows,
    qh_table_dimensions,
    qh_dimensions,
    qh_rule_conditions,
    qh_selection_rules,
    qh_tables,
    temperature_regimes,
    question_options,
    questions
RESTART IDENTITY CASCADE;


-- ============================================================
-- 1. ВОПРОСЫ
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
    'PROJECT_DATE',
    'Дата выполнения проекта по тепловой изоляции',
    'Укажите дату выполнения проекта по тепловой изоляции рассматриваемого участка тепловой сети',
    'TABLE_SELECTION',
    'date',
    NULL,
    10,
    NULL,
    true
),

(
    'NETWORK_TYPE',
    'Тип тепловой сети',
    'Укажите тип рассматриваемой тепловой сети',
    'TABLE_SELECTION',
    'select',
    NULL,
    20,
    'STATIC',
    true
),

(
    'PIPE_TYPE',
    'Тип трубопровода',
    'Укажите конструктивный тип трубопровода',
    'TABLE_SELECTION',
    'select',
    NULL,
    30,
    'STATIC',
    true
),

(
    'LAYING_METHOD',
    'Способ прокладки',
    'Укажите способ прокладки рассматриваемого участка трубопровода',
    'TABLE_SELECTION',
    'select',
    NULL,
    40,
    'STATIC',
    true
),

(
    'ANNUAL_HOURS',
    'Продолжительность работы тепловой сети в год',
    'Укажите количество часов работы рассматриваемого участка тепловой сети в течение года',
    'TABLE_SELECTION',
    'number',
    'ч/год',
    50,
    NULL,
    true
),

(
    'NOMINAL_BORE',
    'Условный проход трубопровода',
    'Выберите условный проход трубопровода по значениям выбранной нормативной таблицы',
    'ROW_SELECTION',
    'select',
    'мм',
    60,
    'QH_ROWS',
    true
),

(
    'REGULATION_TYPE',
    'Тип регулирования температуры сетевой воды',
    'Укажите способ регулирования температуры теплоносителя',
    'TEMPERATURE',
    'select',
    NULL,
    70,
    'STATIC',
    true
),

(
    'TEMPERATURE_REGIME',
    'Температурный график тепловой сети',
    'Выберите проектный температурный график, например 130/70 °C',
    'TEMPERATURE',
    'select',
    '°C',
    80,
    'TEMPERATURE_REGIMES',
    true
),

(
    'MAX_COOLANT_TEMPERATURE',
    'Максимальная температура теплоносителя',
    'Укажите максимальную температуру сетевой воды при количественном регулировании',
    'TEMPERATURE',
    'number',
    '°C',
    90,
    NULL,
    true
);


-- ============================================================
-- 2. СТАТИЧЕСКИЕ ВАРИАНТЫ ОТВЕТОВ - STATIC
-- ============================================================

INSERT INTO question_options (
    question_code,
    value,
    label,
    sort_order,
    is_active
)
VALUES

-- ------------------------------------------------------------
-- Тип тепловой сети
-- ------------------------------------------------------------

(
    'NETWORK_TYPE',
    'TWO_PIPE_WATER_HEATING',
    'Двухтрубная водяная тепловая сеть',
    10,
    true
),

-- ------------------------------------------------------------
-- Тип трубопровода
-- Для Б.7 / Б.9 сейчас оставляем только обычный трубопровод
-- ------------------------------------------------------------

(
    'PIPE_TYPE',
    'STANDARD',
    'Обычный трубопровод',
    10,
    true
),

-- ------------------------------------------------------------
-- Способ прокладки
-- Б.7 / Б.9 относятся к бесканальной прокладке
-- ------------------------------------------------------------

(
    'LAYING_METHOD',
    'UNDERGROUND_CHANNELLESS',
    'Подземная бесканальная прокладка',
    10,
    true
),

-- ------------------------------------------------------------
-- Тип регулирования
-- ------------------------------------------------------------

(
    'REGULATION_TYPE',
    'QUALITATIVE',
    'Качественное регулирование',
    10,
    true
),

(
    'REGULATION_TYPE',
    'QUANTITATIVE',
    'Количественное регулирование',
    20,
    true
);


-- ============================================================
-- 3. ТАБЛИЦА 5.1
-- ============================================================

INSERT INTO temperature_regimes (
    project_supply_temperature_c,
    project_return_temperature_c,
    calculated_supply_temperature_c
)
VALUES
    (95,  70, 65.0),
    (110, 70, 71.8),
    (120, 70, 76.4),
    (130, 70, 80.9),
    (140, 70, 85.5),
    (150, 70, 90.0),
    (180, 70, 110.0);


-- ============================================================
-- 4. НОРМАТИВНЫЕ ТАБЛИЦЫ
-- ТОЛЬКО Б.7 И Б.9
-- ============================================================

INSERT INTO qh_tables (
    code,
    appendix,
    title,
    table_kind,
    is_active
)
VALUES

(
    'Б.7',
    'Б',
    'Нормы линейной плотности теплового потока через изолированную поверхность для трубопроводов двухтрубных водяных тепловых сетей при бесканальной прокладке и продолжительности работы более 5000 ч в год, сооруженных по проектам, выполненным с 1 июля 1995 г. до 2010 г.',
    'QH',
    true
),

(
    'Б.9',
    'Б',
    'Нормы линейной плотности теплового потока через изолированную поверхность для трубопроводов двухтрубных водяных тепловых сетей при бесканальной прокладке и продолжительности работы 5000 ч в год и менее, сооруженных по проектам, выполненным с 1 июля 1995 г. до 2010 г.',
    'QH',
    true
);


-- ============================================================
-- 5. ПРАВИЛА ВЫБОРА Б.7 / Б.9
-- ============================================================

-- ------------------------------------------------------------
-- Б.7, обычный период 01.07.1995 - 31.12.2009
-- ------------------------------------------------------------

INSERT INTO qh_selection_rules (
    code,
    qh_table_id,
    priority,
    description,
    is_active
)
SELECT
    'B7_1995_2010',
    id,
    100,
    'Выбор Б.7 для проектов с 01.07.1995 до 2010 года при бесканальной прокладке и работе более 5000 ч/год',
    true
FROM qh_tables
WHERE code = 'Б.7';


-- ------------------------------------------------------------
-- Б.9, обычный период 01.07.1995 - 31.12.2009
-- ------------------------------------------------------------

INSERT INTO qh_selection_rules (
    code,
    qh_table_id,
    priority,
    description,
    is_active
)
SELECT
    'B9_1995_2010',
    id,
    100,
    'Выбор Б.9 для проектов с 01.07.1995 до 2010 года при бесканальной прокладке и работе 5000 ч/год и менее',
    true
FROM qh_tables
WHERE code = 'Б.9';


-- ------------------------------------------------------------
-- Б.7 для проектов 1990 - 30.06.1995
-- Используется Б.7, но затем qh делится на 0.8
-- ------------------------------------------------------------

INSERT INTO qh_selection_rules (
    code,
    qh_table_id,
    priority,
    description,
    is_active
)
SELECT
    'B7_1990_1995',
    id,
    100,
    'Выбор Б.7 для проектов с 1990 до 01.07.1995 при работе более 5000 ч/год с последующим делением qh на 0.8',
    true
FROM qh_tables
WHERE code = 'Б.7';


-- ------------------------------------------------------------
-- Б.9 для проектов 1990 - 30.06.1995
-- ------------------------------------------------------------

INSERT INTO qh_selection_rules (
    code,
    qh_table_id,
    priority,
    description,
    is_active
)
SELECT
    'B9_1990_1995',
    id,
    100,
    'Выбор Б.9 для проектов с 1990 до 01.07.1995 при работе 5000 ч/год и менее с последующим делением qh на 0.8',
    true
FROM qh_tables
WHERE code = 'Б.9';


-- ============================================================
-- 6. УСЛОВИЯ ПРАВИЛА Б.7
-- 01.07.1995 <= дата < 01.01.2010
-- ============================================================

INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_date
)
SELECT
    id,
    'PROJECT_DATE',
    'GTE',
    DATE '1995-07-01'
FROM qh_selection_rules
WHERE code = 'B7_1995_2010';


INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_date
)
SELECT
    id,
    'PROJECT_DATE',
    'LT',
    DATE '2010-01-01'
FROM qh_selection_rules
WHERE code = 'B7_1995_2010';


INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_text
)
SELECT
    id,
    'NETWORK_TYPE',
    'EQ',
    'TWO_PIPE_WATER_HEATING'
FROM qh_selection_rules
WHERE code = 'B7_1995_2010';


INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_text
)
SELECT
    id,
    'PIPE_TYPE',
    'EQ',
    'STANDARD'
FROM qh_selection_rules
WHERE code = 'B7_1995_2010';


INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_text
)
SELECT
    id,
    'LAYING_METHOD',
    'EQ',
    'UNDERGROUND_CHANNELLESS'
FROM qh_selection_rules
WHERE code = 'B7_1995_2010';


INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_numeric
)
SELECT
    id,
    'ANNUAL_HOURS',
    'GT',
    5000
FROM qh_selection_rules
WHERE code = 'B7_1995_2010';


-- ============================================================
-- 7. УСЛОВИЯ ПРАВИЛА Б.9
-- 01.07.1995 <= дата < 01.01.2010
-- ============================================================

INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_date
)
SELECT
    id,
    'PROJECT_DATE',
    'GTE',
    DATE '1995-07-01'
FROM qh_selection_rules
WHERE code = 'B9_1995_2010';


INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_date
)
SELECT
    id,
    'PROJECT_DATE',
    'LT',
    DATE '2010-01-01'
FROM qh_selection_rules
WHERE code = 'B9_1995_2010';


INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_text
)
SELECT
    id,
    'NETWORK_TYPE',
    'EQ',
    'TWO_PIPE_WATER_HEATING'
FROM qh_selection_rules
WHERE code = 'B9_1995_2010';


INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_text
)
SELECT
    id,
    'PIPE_TYPE',
    'EQ',
    'STANDARD'
FROM qh_selection_rules
WHERE code = 'B9_1995_2010';


INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_text
)
SELECT
    id,
    'LAYING_METHOD',
    'EQ',
    'UNDERGROUND_CHANNELLESS'
FROM qh_selection_rules
WHERE code = 'B9_1995_2010';


INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_numeric
)
SELECT
    id,
    'ANNUAL_HOURS',
    'LTE',
    5000
FROM qh_selection_rules
WHERE code = 'B9_1995_2010';


-- ============================================================
-- 8. Б.7 ДЛЯ ПРОЕКТОВ 1990 - 30.06.1995
-- ============================================================

INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_date
)
SELECT
    id,
    'PROJECT_DATE',
    'GTE',
    DATE '1990-01-01'
FROM qh_selection_rules
WHERE code = 'B7_1990_1995';


INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_date
)
SELECT
    id,
    'PROJECT_DATE',
    'LT',
    DATE '1995-07-01'
FROM qh_selection_rules
WHERE code = 'B7_1990_1995';


INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_text
)
SELECT
    id,
    'NETWORK_TYPE',
    'EQ',
    'TWO_PIPE_WATER_HEATING'
FROM qh_selection_rules
WHERE code = 'B7_1990_1995';


INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_text
)
SELECT
    id,
    'PIPE_TYPE',
    'EQ',
    'STANDARD'
FROM qh_selection_rules
WHERE code = 'B7_1990_1995';


INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_text
)
SELECT
    id,
    'LAYING_METHOD',
    'EQ',
    'UNDERGROUND_CHANNELLESS'
FROM qh_selection_rules
WHERE code = 'B7_1990_1995';


INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_numeric
)
SELECT
    id,
    'ANNUAL_HOURS',
    'GT',
    5000
FROM qh_selection_rules
WHERE code = 'B7_1990_1995';


-- ============================================================
-- 9. Б.9 ДЛЯ ПРОЕКТОВ 1990 - 30.06.1995
-- ============================================================

INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_date
)
SELECT
    id,
    'PROJECT_DATE',
    'GTE',
    DATE '1990-01-01'
FROM qh_selection_rules
WHERE code = 'B9_1990_1995';


INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_date
)
SELECT
    id,
    'PROJECT_DATE',
    'LT',
    DATE '1995-07-01'
FROM qh_selection_rules
WHERE code = 'B9_1990_1995';


INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_text
)
SELECT
    id,
    'NETWORK_TYPE',
    'EQ',
    'TWO_PIPE_WATER_HEATING'
FROM qh_selection_rules
WHERE code = 'B9_1990_1995';


INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_text
)
SELECT
    id,
    'PIPE_TYPE',
    'EQ',
    'STANDARD'
FROM qh_selection_rules
WHERE code = 'B9_1990_1995';


INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_text
)
SELECT
    id,
    'LAYING_METHOD',
    'EQ',
    'UNDERGROUND_CHANNELLESS'
FROM qh_selection_rules
WHERE code = 'B9_1990_1995';


INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_numeric
)
SELECT
    id,
    'ANNUAL_HOURS',
    'LTE',
    5000
FROM qh_selection_rules
WHERE code = 'B9_1990_1995';


-- ============================================================
-- 10. ХАРАКТЕРИСТИКА СТРОКИ
-- УСЛОВНЫЙ ПРОХОД ТРУБОПРОВОДА
-- ============================================================

INSERT INTO qh_dimensions (
    code,
    question_code,
    value_type,
    unit,
    description
)
VALUES (
    'NOMINAL_BORE',
    'NOMINAL_BORE',
    'NUMBER',
    'мм',
    'Условный проход трубопровода'
);


-- ============================================================
-- 11. Б.7 И Б.9 ИСПОЛЬЗУЮТ NOMINAL_BORE
-- ДЛЯ ВЫБОРА СТРОКИ
-- ============================================================

INSERT INTO qh_table_dimensions (
    table_id,
    dimension_id,
    sequence_no
)
SELECT
    t.id,
    d.id,
    1
FROM qh_tables t
CROSS JOIN qh_dimensions d
WHERE t.code IN ('Б.7', 'Б.9')
  AND d.code = 'NOMINAL_BORE';


-- ============================================================
-- 12. ВРЕМЕННАЯ ТАБЛИЦА ДЛЯ ЗАГРУЗКИ Б.7 / Б.9
-- ============================================================

CREATE TEMP TABLE seed_qh_raw (
    table_code              varchar(10) NOT NULL,

    source_row_no           integer NOT NULL,

    nominal_bore_mm         numeric NOT NULL,

    q_return_50             numeric NOT NULL,

    q_supply_65             numeric NOT NULL,
    q_total_65_50           numeric NOT NULL,

    q_supply_90             numeric NOT NULL,
    q_total_90_50           numeric NOT NULL,

    source_interpolated     boolean NOT NULL
) ON COMMIT DROP;


-- ============================================================
-- 13. ДАННЫЕ ТАБЛИЦЫ Б.7
-- ============================================================

INSERT INTO seed_qh_raw (
    table_code,
    source_row_no,
    nominal_bore_mm,
    q_return_50,
    q_supply_65,
    q_total_65_50,
    q_supply_90,
    q_total_90_50,
    source_interpolated
)
VALUES
('Б.7',  1,  15, 18.1,  24.2,  42.2,  32.0,  49.6, true),
('Б.7',  2,  20, 19.0,  25.3,  44.3,  33.6,  52.0, true),
('Б.7',  3,  25, 20.0,  26.4,  46.4,  35.2,  54.4, false),
('Б.7',  4,  32, 21.3,  28.0,  49.3,  37.4,  57.8, true),
('Б.7',  5,  40, 22.9,  29.8,  52.6,  40.0,  61.6, true),
('Б.7',  6,  50, 24.8,  32.0,  56.8,  43.2,  66.4, false),
('Б.7',  7,  65, 27.2,  36.0,  63.2,  48.0,  74.4, false),
('Б.7',  8,  80, 28.0,  36.8,  64.8,  48.8,  76.0, false),
('Б.7',  9, 100, 30.4,  39.2,  69.6,  52.0,  80.0, false),
('Б.7', 10, 125, 32.8,  42.4,  75.2,  57.6,  88.8, false),
('Б.7', 11, 150, 36.8,  48.0,  84.8,  64.0,  96.4, false),
('Б.7', 12, 200, 40.0,  52.8,  92.8,  71.2, 109.6, false),
('Б.7', 13, 250, 44.0,  57.6, 101.6,  76.8, 117.6, false),
('Б.7', 14, 300, 47.2,  63.2, 110.4,  84.0, 125.8, false),
('Б.7', 15, 350, 52.0,  68.8, 120.8,  90.4, 136.4, false),
('Б.7', 16, 400, 54.4,  72.8, 127.2,  96.8, 147.2, false),
('Б.7', 17, 450, 57.6,  77.6, 135.2, 103.2, 156.8, false),
('Б.7', 18, 500, 62.4,  84.0, 146.4, 110.4, 168.0, false),
('Б.7', 19, 600, 69.6,  93.6, 163.2, 124.8, 188.8, false),
('Б.7', 20, 700, 74.4, 100.8, 175.2, 136.0, 204.8, false),
('Б.7', 21, 800, 81.6, 112.0, 193.6, 148.8, 225.2, false);


-- ============================================================
-- 14. ДАННЫЕ ТАБЛИЦЫ Б.9
-- ============================================================

INSERT INTO seed_qh_raw (
    table_code,
    source_row_no,
    nominal_bore_mm,
    q_return_50,
    q_supply_65,
    q_total_65_50,
    q_supply_90,
    q_total_90_50,
    source_interpolated
)
VALUES
('Б.9',  1,  15, 19.4,  26.2,  45.6,  34.6,  53.4, true),
('Б.9',  2,  20, 20.5,  27.5,  48.0,  36.5,  56.3, true),
('Б.9',  3,  25, 21.6,  28.8,  50.4,  38.4,  59.2, false),
('Б.9',  4,  32, 23.2,  30.6,  53.8,  41.1,  63.2, true),
('Б.9',  5,  40, 25.0,  32.6,  57.6,  44.2,  67.8, true),
('Б.9',  6,  50, 27.2,  35.2,  62.4,  48.0,  73.6, false),
('Б.9',  7,  65, 30.4,  40.0,  70.4,  53.6,  82.4, false),
('Б.9',  8,  80, 31.2,  40.8,  72.0,  55.2,  84.8, false),
('Б.9',  9, 100, 33.6,  44.0,  77.6,  59.2,  91.2, false),
('Б.9', 10, 125, 36.8,  48.8,  85.6,  64.8, 100.0, false),
('Б.9', 11, 150, 41.6,  55.2,  96.8,  72.8, 112.0, false),
('Б.9', 12, 200, 47.2,  61.6, 108.8,  80.8, 124.0, false),
('Б.9', 13, 250, 50.4,  66.4, 116.8,  88.8, 136.0, false),
('Б.9', 14, 300, 55.2,  72.8, 128.0,  97.6, 148.8, false),
('Б.9', 15, 350, 60.0,  80.8, 140.8, 106.4, 161.6, false),
('Б.9', 16, 400, 64.0,  86.4, 150.4, 112.0, 170.4, false),
('Б.9', 17, 450, 68.8,  92.8, 161.6, 120.8, 183.2, false),
('Б.9', 18, 500, 72.8,  98.4, 171.2, 130.4, 196.8, false),
('Б.9', 19, 600, 82.4, 112.0, 194.4, 148.8, 224.0, false),
('Б.9', 20, 700, 89.6, 124.8, 214.4, 162.4, 242.4, false),
('Б.9', 21, 800, 97.6, 135.2, 232.8, 180.8, 278.0, false);


-- ============================================================
-- 15. СОЗДАЕМ qh_rows
-- ============================================================

INSERT INTO qh_rows (
    table_id,
    source_row_no,
    note,
    is_active
)
SELECT
    t.id,
    raw.source_row_no,
    'Таблица ' ||
        raw.table_code ||
        ', условный проход ' ||
        raw.nominal_bore_mm ||
        ' мм',
    true
FROM seed_qh_raw raw
JOIN qh_tables t
    ON t.code = raw.table_code
ORDER BY
    raw.table_code,
    raw.source_row_no;


-- ============================================================
-- 16. ХАРАКТЕРИСТИКА КАЖДОЙ СТРОКИ
-- NOMINAL_BORE
-- ============================================================

INSERT INTO qh_row_dimension_values (
    row_id,
    dimension_id,
    value_numeric,
    value_text
)
SELECT
    r.id,
    d.id,
    raw.nominal_bore_mm,
    NULL
FROM seed_qh_raw raw

JOIN qh_tables t
    ON t.code = raw.table_code

JOIN qh_rows r
    ON r.table_id = t.id
   AND r.source_row_no = raw.source_row_no

JOIN qh_dimensions d
    ON d.code = 'NOMINAL_BORE';


-- ============================================================
-- 17. ЗНАЧЕНИЯ qh
--
-- Для одной qh_rows создается 5 qh_values:
--
-- RETURN 50
-- SUPPLY 65
-- TOTAL 65/50
-- SUPPLY 90
-- TOTAL 90/50
-- ============================================================

INSERT INTO qh_values (
    row_id,
    pipeline_role,
    placement_variant,
    supply_temperature_c,
    return_temperature_c,
    qh_w_per_m,
    source_interpolated,
    note
)
SELECT
    r.id,

    val.pipeline_role,

    'UNDERGROUND_CHANNELLESS',

    val.supply_temperature_c,
    val.return_temperature_c,

    val.qh_w_per_m,

    raw.source_interpolated,

    'Таблица ' ||
        raw.table_code ||
        ', условный проход ' ||
        raw.nominal_bore_mm ||
        ' мм; ' ||
        val.description

FROM seed_qh_raw raw

JOIN qh_tables t
    ON t.code = raw.table_code

JOIN qh_rows r
    ON r.table_id = t.id
   AND r.source_row_no = raw.source_row_no

CROSS JOIN LATERAL (

    VALUES

    (
        'RETURN'::varchar,
        NULL::numeric,
        50::numeric,
        raw.q_return_50,
        'обратный трубопровод при расчетной температуре 50 °C'
    ),

    (
        'SUPPLY'::varchar,
        65::numeric,
        NULL::numeric,
        raw.q_supply_65,
        'подающий трубопровод при расчетной температуре 65 °C'
    ),

    (
        'TWO_PIPE_TOTAL'::varchar,
        65::numeric,
        50::numeric,
        raw.q_total_65_50,
        'суммарное значение для двухтрубной прокладки 65/50 °C'
    ),

    (
        'SUPPLY'::varchar,
        90::numeric,
        NULL::numeric,
        raw.q_supply_90,
        'подающий трубопровод при расчетной температуре 90 °C'
    ),

    (
        'TWO_PIPE_TOTAL'::varchar,
        90::numeric,
        50::numeric,
        raw.q_total_90_50,
        'суммарное значение для двухтрубной прокладки 90/50 °C'
    )

) AS val (
    pipeline_role,
    supply_temperature_c,
    return_temperature_c,
    qh_w_per_m,
    description
);


-- ============================================================
-- 18. ПОПРАВКА ДЛЯ ПЕРИОДА 1990 - 30.06.1995
--
-- Б.7 / 0.8
-- Б.9 / 0.8
-- ============================================================

INSERT INTO qh_adjustment_rules (
    qh_table_id,
    project_date_from,
    project_date_to,
    pipe_type,
    laying_method,
    operation,
    factor,
    requires_question,
    coefficient_source,
    description,
    is_active
)
SELECT
    id,
    DATE '1990-01-01',
    DATE '1995-06-30',
    'STANDARD',
    'UNDERGROUND_CHANNELLESS',
    'DIVIDE',
    0.8,
    'PROJECT_DATE',
    'TABLE_B7_NOTE',
    'Для проектов с 1990 года до 1 июля 1995 года значение qh по Б.7 делится на 0.8',
    true
FROM qh_tables
WHERE code = 'Б.7';


INSERT INTO qh_adjustment_rules (
    qh_table_id,
    project_date_from,
    project_date_to,
    pipe_type,
    laying_method,
    operation,
    factor,
    requires_question,
    coefficient_source,
    description,
    is_active
)
SELECT
    id,
    DATE '1990-01-01',
    DATE '1995-06-30',
    'STANDARD',
    'UNDERGROUND_CHANNELLESS',
    'DIVIDE',
    0.8,
    'PROJECT_DATE',
    'TABLE_B9_NOTE',
    'Для проектов с 1990 года до 1 июля 1995 года значение qh по Б.9 делится на 0.8',
    true
FROM qh_tables
WHERE code = 'Б.9';


COMMIT;


-- ============================================================
-- ПРОВЕРКА №1
-- СКОЛЬКО СТРОК И ЗНАЧЕНИЙ qh ЗАГРУЖЕНО
-- ============================================================

SELECT
    t.code,
    COUNT(DISTINCT r.id) AS qh_rows_count,
    COUNT(v.id) AS qh_values_count
FROM qh_tables t
LEFT JOIN qh_rows r
    ON r.table_id = t.id
LEFT JOIN qh_values v
    ON v.row_id = r.id
GROUP BY
    t.id,
    t.code
ORDER BY
    t.code;


-- ============================================================
-- ПРОВЕРКА №2
-- ПОКАЗАТЬ УСЛОВНЫЕ ПРОХОДЫ Б.7 / Б.9
-- ============================================================

SELECT
    t.code,
    rdv.value_numeric AS nominal_bore_mm
FROM qh_tables t
JOIN qh_rows r
    ON r.table_id = t.id
JOIN qh_row_dimension_values rdv
    ON rdv.row_id = r.id
JOIN qh_dimensions d
    ON d.id = rdv.dimension_id
WHERE d.code = 'NOMINAL_BORE'
ORDER BY
    t.code,
    rdv.value_numeric;


-- ============================================================
-- ПРОВЕРКА №3
-- ПОКАЗАТЬ qh ДЛЯ УСЛОВНОГО ПРОХОДА 100 ММ
-- ============================================================

SELECT
    t.code,
    rdv.value_numeric AS nominal_bore_mm,

    v.pipeline_role,
    v.supply_temperature_c,
    v.return_temperature_c,
    v.qh_w_per_m

FROM qh_tables t

JOIN qh_rows r
    ON r.table_id = t.id

JOIN qh_row_dimension_values rdv
    ON rdv.row_id = r.id

JOIN qh_dimensions d
    ON d.id = rdv.dimension_id

JOIN qh_values v
    ON v.row_id = r.id

WHERE
    d.code = 'NOMINAL_BORE'
    AND rdv.value_numeric = 100

ORDER BY
    t.code,
    v.pipeline_role,
    v.supply_temperature_c NULLS FIRST;