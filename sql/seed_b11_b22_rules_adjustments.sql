BEGIN;

-- ============================================================
-- Б.11 - Б.22
-- qh_selection_rules + qh_rule_conditions
-- qh_adjustment_rules + условия применения поправок
--
-- ВАЖНО:
-- 1) существующие вопросы PROJECT_DATE / PIPE_TYPE / LAYING_METHOD /
--    ANNUAL_OPERATING_HOURS повторно не переписываются;
-- 2) добавляются только недостающие для Б.11-Б.22 вопросы:
--      PIPE_CONSTRUCTION
--      FOAMING_AGENT
-- 3) для условных поправок создается отдельная таблица
--    qh_adjustment_rule_conditions, потому что одной колонки
--    requires_question недостаточно, чтобы выразить:
--      FOAMING_AGENT = CYCLOPENTANE.
-- ============================================================


-- ============================================================
-- 1. PROJECT_DATE
--
-- Для границы 16.03.2018 одного PROJECT_YEAR недостаточно.
-- Если вопрос уже существует, НЕ изменяем его.
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
    'PROJECT_DATE',
    'Дата выполнения проекта',
    'Укажите дату выполнения проекта по тепловой изоляции',
    'TABLE_SELECTION',
    'date',
    NULL,
    11,
    NULL,
    true
)
ON CONFLICT (code) DO NOTHING;


-- ============================================================
-- 2. ТИП / ИСПОЛНЕНИЕ ТРУБОПРОВОДА
--
-- STANDARD    = обычные таблицы Б.2-Б.14
-- PI_STB2252  = ПИ по СТБ 2252 -> Б.15/Б.16
-- PI_REF1     = ПИ по [1]     -> Б.21/Б.22
-- PP          = ПП            -> Б.17
-- GPI         = ГПИ           -> Б.17/Б.18
-- GSI         = ГСИ           -> Б.19/Б.20
-- TSP         = ТСП           -> Б.20
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
    'PIPE_CONSTRUCTION',
    'Исполнение трубопровода',
    'Выберите конструктивное исполнение трубопровода',
    'TABLE_SELECTION',
    'select',
    NULL,
    25,
    'STATIC',
    true
)
ON CONFLICT (code) DO NOTHING;

INSERT INTO question_options (
    question_code,
    value,
    label,
    sort_order,
    is_active
)
VALUES
    ('PIPE_CONSTRUCTION', 'STANDARD',   'Обычный трубопровод', 10, true),
    ('PIPE_CONSTRUCTION', 'PI_STB2252', 'ПИ-трубопровод по СТБ 2252', 20, true),
    ('PIPE_CONSTRUCTION', 'PI_REF1',    'ПИ-трубопровод по [1]', 30, true),
    ('PIPE_CONSTRUCTION', 'PP',         'ПП-трубопровод по техническим условиям изготовителя', 40, true),
    ('PIPE_CONSTRUCTION', 'GPI',        'ГПИ-трубопровод по техническим условиям изготовителя', 50, true),
    ('PIPE_CONSTRUCTION', 'GSI',        'ГСИ-трубопровод по техническим условиям изготовителя', 60, true),
    ('PIPE_CONSTRUCTION', 'TSP',        'ТСП-трубопровод по техническим условиям изготовителя', 70, true)
ON CONFLICT (question_code, value) DO NOTHING;


-- ============================================================
-- 3. ВСПЕНИВАТЕЛЬ ТЕПЛОВОЙ ИЗОЛЯЦИИ
--
-- Нужен для поправки x0.9 в Б.15-Б.20.
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
    'FOAMING_AGENT',
    'Вспениватель теплоизоляции',
    'Укажите вспениватель теплоизоляционного слоя',
    'TABLE_SELECTION',
    'select',
    NULL,
    20,
    'STATIC',
    true
)
ON CONFLICT (code) DO NOTHING;

INSERT INTO question_options (
    question_code,
    value,
    label,
    sort_order,
    is_active
)
VALUES
    ('FOAMING_AGENT', 'CYCLOPENTANE', 'Циклопентан', 10, true),
    ('FOAMING_AGENT', 'OTHER',         'Другой / не применяется', 20, true)
ON CONFLICT (question_code, value) DO NOTHING;


-- ============================================================
-- 4. УСЛОВИЯ ДЛЯ qh_adjustment_rules
--
-- В текущей qh_adjustment_rules есть requires_question,
-- но нет возможности записать:
--     вопрос = конкретное значение.
-- Поэтому условия поправок выносим отдельно, аналогично
-- qh_rule_conditions.
-- ============================================================

CREATE TABLE IF NOT EXISTS qh_adjustment_rule_conditions (
    id                  bigserial PRIMARY KEY,

    adjustment_rule_id  bigint NOT NULL
                        REFERENCES qh_adjustment_rules(id)
                        ON DELETE CASCADE,

    question_code       varchar(60) NOT NULL
                        REFERENCES questions(code),

    operator            varchar(20) NOT NULL
                        CHECK (
                            operator IN (
                                'EQ',
                                'NEQ',
                                'GT',
                                'GTE',
                                'LT',
                                'LTE',
                                'BETWEEN'
                            )
                        ),

    value_text          text,
    value_numeric       numeric,
    value_numeric_to    numeric,
    value_date          date,
    value_date_to       date,
    value_boolean       boolean,

    UNIQUE (adjustment_rule_id, question_code)
);

CREATE INDEX IF NOT EXISTS idx_qh_adjustment_rule_conditions_rule
    ON qh_adjustment_rule_conditions(adjustment_rule_id);

CREATE INDEX IF NOT EXISTS idx_qh_adjustment_rule_conditions_question
    ON qh_adjustment_rule_conditions(question_code);


-- ============================================================
-- 5. ПРОВЕРКА ОБЯЗАТЕЛЬНЫХ ВОПРОСОВ
-- ============================================================

DO $$
DECLARE
    missing_codes text;
BEGIN
    SELECT string_agg(x.code, ', ' ORDER BY x.code)
    INTO missing_codes
    FROM (
        VALUES
            ('PROJECT_DATE'),
            ('PIPE_TYPE'),
            ('PIPE_CONSTRUCTION'),
            ('LAYING_METHOD'),
            ('ANNUAL_OPERATING_HOURS'),
            ('FOAMING_AGENT')
    ) AS x(code)
    WHERE NOT EXISTS (
        SELECT 1
        FROM questions q
        WHERE q.code = x.code
    );

    IF missing_codes IS NOT NULL THEN
        RAISE EXCEPTION 'Отсутствуют questions: %', missing_codes;
    END IF;
END $$;


-- ============================================================
-- 6. ПРОВЕРКА qh_tables Б.11-Б.22
-- ============================================================

DO $$
DECLARE
    missing_codes text;
BEGIN
    SELECT string_agg(x.code, ', ' ORDER BY x.code)
    INTO missing_codes
    FROM (
        VALUES
            ('Б.11'),('Б.12'),('Б.13'),('Б.14'),
            ('Б.15'),('Б.16'),('Б.17'),('Б.18'),
            ('Б.19'),('Б.20'),('Б.21'),('Б.22')
    ) AS x(code)
    WHERE NOT EXISTS (
        SELECT 1
        FROM qh_tables t
        WHERE t.code = x.code
    );

    IF missing_codes IS NOT NULL THEN
        RAISE EXCEPTION 'Отсутствуют qh_tables: %', missing_codes;
    END IF;
END $$;


-- ============================================================
-- 7. ВАЖНО: ограничиваем старые ОБЫЧНЫЕ правила Б.2-Б.9
--    конструкцией STANDARD.
--
-- Иначе, например, ПИ-труба 2012 года одновременно совпадет
-- с общим правилом Б.5/Б.6 и специальным Б.15/Б.21.
-- ============================================================

INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_text
)
SELECT
    r.id,
    'PIPE_CONSTRUCTION',
    'EQ',
    'STANDARD'
FROM qh_selection_rules r
WHERE r.code IN (
    'B2_TWO_PIPE_CHANNELLESS_BEFORE_1990',
    'B2_TWO_PIPE_NONPASSAGE_BEFORE_1990',
    'B3_NONPASSAGE_GT5000_1990_2009',
    'B4_NONPASSAGE_LTE5000_1990_2009',
    'B5_NONPASSAGE_GT5000_FROM_2010',
    'B6_NONPASSAGE_LTE5000_FROM_2010',
    'B7_CHANNELLESS_GT5000_1990_2009',
    'B9_CHANNELLESS_LTE5000_1990_2009'
)
AND NOT EXISTS (
    SELECT 1
    FROM qh_rule_conditions c
    WHERE c.rule_id = r.id
      AND c.question_code = 'PIPE_CONSTRUCTION'
);


-- ============================================================
-- 8. qh_selection_rules Б.11-Б.22
-- ============================================================

CREATE TEMP TABLE tmp_b11_b22_selection_rules (
    rule_code    varchar(80) PRIMARY KEY,
    table_code   varchar(10) NOT NULL,
    priority     integer NOT NULL,
    description  text NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_b11_b22_selection_rules (
    rule_code,
    table_code,
    priority,
    description
)
VALUES
    ('B11_STANDARD_CHANNELLESS_GT5000_2010_20180315',
     'Б.11', 100,
     'Б.11: обычная двухтрубная сеть, бесканальная прокладка, >5000 ч/год, 01.01.2010-15.03.2018'),

    ('B12_STANDARD_CHANNELLESS_LTE5000_2010_20180315',
     'Б.12', 100,
     'Б.12: обычная двухтрубная сеть, бесканальная прокладка, <=5000 ч/год, 01.01.2010-15.03.2018'),

    ('B13_STANDARD_CHANNELLESS_GT5000_FROM_20180316',
     'Б.13', 100,
     'Б.13: обычная двухтрубная сеть, бесканальная прокладка, >5000 ч/год, с 16.03.2018'),

    ('B14_STANDARD_CHANNELLESS_LTE5000_FROM_20180316',
     'Б.14', 100,
     'Б.14: обычная двухтрубная сеть, бесканальная прокладка, <=5000 ч/год, с 16.03.2018'),

    ('B15_PI_STB2252_NONPASSAGE',
     'Б.15', 100,
     'Б.15: ПИ-трубопровод по СТБ 2252, непроходной канал'),

    ('B16_PI_STB2252_CHANNELLESS',
     'Б.16', 100,
     'Б.16: ПИ-трубопровод по СТБ 2252, бесканальная прокладка'),

    ('B17_PP_NONPASSAGE',
     'Б.17', 100,
     'Б.17: ПП-трубопровод по ТУ изготовителя, непроходной канал'),

    ('B17_GPI_NONPASSAGE',
     'Б.17', 100,
     'Б.17: ГПИ-трубопровод с циклопентаном, непроходной канал; Б.17 x0.9'),

    ('B18_GPI_CHANNELLESS',
     'Б.18', 100,
     'Б.18: ГПИ-трубопровод по ТУ изготовителя, бесканальная прокладка'),

    ('B19_GSI_NONPASSAGE',
     'Б.19', 100,
     'Б.19: ГСИ-трубопровод по ТУ изготовителя, непроходной канал'),

    ('B20_TSP_CHANNELLESS',
     'Б.20', 100,
     'Б.20: ТСП-трубопровод по ТУ изготовителя, бесканальная прокладка'),

    ('B20_GSI_CHANNELLESS',
     'Б.20', 100,
     'Б.20: ГСИ-трубопровод с циклопентаном, бесканальная прокладка; Б.20 x0.9'),

    ('B21_PI_REF1_NONPASSAGE',
     'Б.21', 100,
     'Б.21: ПИ-трубопровод по [1], непроходной канал'),

    ('B22_PI_REF1_CHANNELLESS',
     'Б.22', 100,
     'Б.22: ПИ-трубопровод по [1], бесканальная прокладка');


INSERT INTO qh_selection_rules (
    code,
    qh_table_id,
    priority,
    description,
    is_active
)
SELECT
    s.rule_code,
    t.id,
    s.priority,
    s.description,
    true
FROM tmp_b11_b22_selection_rules s
JOIN qh_tables t
    ON t.code = s.table_code
ON CONFLICT (code)
DO UPDATE SET
    qh_table_id = EXCLUDED.qh_table_id,
    priority = EXCLUDED.priority,
    description = EXCLUDED.description,
    is_active = true;


-- ============================================================
-- 9. Полностью пересоздаем conditions только наших правил
-- ============================================================

DELETE FROM qh_rule_conditions c
USING qh_selection_rules r
WHERE c.rule_id = r.id
  AND r.code IN (
      SELECT rule_code
      FROM tmp_b11_b22_selection_rules
  );


CREATE TEMP TABLE tmp_b11_b22_selection_conditions (
    rule_code          varchar(80) NOT NULL,
    question_code      varchar(60) NOT NULL,
    operator           varchar(20) NOT NULL,
    value_text         text,
    value_numeric      numeric,
    value_numeric_to   numeric,
    value_date         date,
    value_date_to      date,
    value_boolean      boolean
) ON COMMIT DROP;


-- ============================================================
-- Б.11
-- ============================================================
INSERT INTO tmp_b11_b22_selection_conditions VALUES
('B11_STANDARD_CHANNELLESS_GT5000_2010_20180315', 'PROJECT_DATE',           'BETWEEN', NULL, NULL, NULL, DATE '2010-01-01', DATE '2018-03-15', NULL),
('B11_STANDARD_CHANNELLESS_GT5000_2010_20180315', 'PIPE_TYPE',              'EQ',      'TWO_PIPE_WATER', NULL, NULL, NULL, NULL, NULL),
('B11_STANDARD_CHANNELLESS_GT5000_2010_20180315', 'PIPE_CONSTRUCTION',      'EQ',      'STANDARD', NULL, NULL, NULL, NULL, NULL),
('B11_STANDARD_CHANNELLESS_GT5000_2010_20180315', 'LAYING_METHOD',          'EQ',      'CHANNELLESS', NULL, NULL, NULL, NULL, NULL),
('B11_STANDARD_CHANNELLESS_GT5000_2010_20180315', 'ANNUAL_OPERATING_HOURS', 'GT',      NULL, 5000, NULL, NULL, NULL, NULL);

-- ============================================================
-- Б.12
-- ============================================================
INSERT INTO tmp_b11_b22_selection_conditions VALUES
('B12_STANDARD_CHANNELLESS_LTE5000_2010_20180315', 'PROJECT_DATE',           'BETWEEN', NULL, NULL, NULL, DATE '2010-01-01', DATE '2018-03-15', NULL),
('B12_STANDARD_CHANNELLESS_LTE5000_2010_20180315', 'PIPE_TYPE',              'EQ',      'TWO_PIPE_WATER', NULL, NULL, NULL, NULL, NULL),
('B12_STANDARD_CHANNELLESS_LTE5000_2010_20180315', 'PIPE_CONSTRUCTION',      'EQ',      'STANDARD', NULL, NULL, NULL, NULL, NULL),
('B12_STANDARD_CHANNELLESS_LTE5000_2010_20180315', 'LAYING_METHOD',          'EQ',      'CHANNELLESS', NULL, NULL, NULL, NULL, NULL),
('B12_STANDARD_CHANNELLESS_LTE5000_2010_20180315', 'ANNUAL_OPERATING_HOURS', 'LTE',     NULL, 5000, NULL, NULL, NULL, NULL);

-- ============================================================
-- Б.13
-- ============================================================
INSERT INTO tmp_b11_b22_selection_conditions VALUES
('B13_STANDARD_CHANNELLESS_GT5000_FROM_20180316', 'PROJECT_DATE',           'GTE', NULL, NULL, NULL, DATE '2018-03-16', NULL, NULL),
('B13_STANDARD_CHANNELLESS_GT5000_FROM_20180316', 'PIPE_TYPE',              'EQ',  'TWO_PIPE_WATER', NULL, NULL, NULL, NULL, NULL),
('B13_STANDARD_CHANNELLESS_GT5000_FROM_20180316', 'PIPE_CONSTRUCTION',      'EQ',  'STANDARD', NULL, NULL, NULL, NULL, NULL),
('B13_STANDARD_CHANNELLESS_GT5000_FROM_20180316', 'LAYING_METHOD',          'EQ',  'CHANNELLESS', NULL, NULL, NULL, NULL, NULL),
('B13_STANDARD_CHANNELLESS_GT5000_FROM_20180316', 'ANNUAL_OPERATING_HOURS', 'GT',  NULL, 5000, NULL, NULL, NULL, NULL);

-- ============================================================
-- Б.14
-- ============================================================
INSERT INTO tmp_b11_b22_selection_conditions VALUES
('B14_STANDARD_CHANNELLESS_LTE5000_FROM_20180316', 'PROJECT_DATE',           'GTE', NULL, NULL, NULL, DATE '2018-03-16', NULL, NULL),
('B14_STANDARD_CHANNELLESS_LTE5000_FROM_20180316', 'PIPE_TYPE',              'EQ',  'TWO_PIPE_WATER', NULL, NULL, NULL, NULL, NULL),
('B14_STANDARD_CHANNELLESS_LTE5000_FROM_20180316', 'PIPE_CONSTRUCTION',      'EQ',  'STANDARD', NULL, NULL, NULL, NULL, NULL),
('B14_STANDARD_CHANNELLESS_LTE5000_FROM_20180316', 'LAYING_METHOD',          'EQ',  'CHANNELLESS', NULL, NULL, NULL, NULL, NULL),
('B14_STANDARD_CHANNELLESS_LTE5000_FROM_20180316', 'ANNUAL_OPERATING_HOURS', 'LTE', NULL, 5000, NULL, NULL, NULL, NULL);

-- ============================================================
-- Б.15 / Б.16: ПИ по СТБ 2252
-- ============================================================
INSERT INTO tmp_b11_b22_selection_conditions VALUES
('B15_PI_STB2252_NONPASSAGE', 'PIPE_TYPE',         'EQ', 'TWO_PIPE_WATER', NULL, NULL, NULL, NULL, NULL),
('B15_PI_STB2252_NONPASSAGE', 'PIPE_CONSTRUCTION', 'EQ', 'PI_STB2252',     NULL, NULL, NULL, NULL, NULL),
('B15_PI_STB2252_NONPASSAGE', 'LAYING_METHOD',     'EQ', 'NONPASSAGE_CHANNEL', NULL, NULL, NULL, NULL, NULL),

('B16_PI_STB2252_CHANNELLESS', 'PIPE_TYPE',         'EQ', 'TWO_PIPE_WATER', NULL, NULL, NULL, NULL, NULL),
('B16_PI_STB2252_CHANNELLESS', 'PIPE_CONSTRUCTION', 'EQ', 'PI_STB2252',     NULL, NULL, NULL, NULL, NULL),
('B16_PI_STB2252_CHANNELLESS', 'LAYING_METHOD',     'EQ', 'CHANNELLESS',     NULL, NULL, NULL, NULL, NULL);

-- ============================================================
-- Б.17: ПП; также база для ГПИ в непроходном канале
-- ============================================================
INSERT INTO tmp_b11_b22_selection_conditions VALUES
('B17_PP_NONPASSAGE', 'PIPE_TYPE',         'EQ', 'TWO_PIPE_WATER', NULL, NULL, NULL, NULL, NULL),
('B17_PP_NONPASSAGE', 'PIPE_CONSTRUCTION', 'EQ', 'PP',             NULL, NULL, NULL, NULL, NULL),
('B17_PP_NONPASSAGE', 'LAYING_METHOD',     'EQ', 'NONPASSAGE_CHANNEL', NULL, NULL, NULL, NULL, NULL),

('B17_GPI_NONPASSAGE', 'PIPE_TYPE',         'EQ', 'TWO_PIPE_WATER', NULL, NULL, NULL, NULL, NULL),
('B17_GPI_NONPASSAGE', 'PIPE_CONSTRUCTION', 'EQ', 'GPI',            NULL, NULL, NULL, NULL, NULL),
('B17_GPI_NONPASSAGE', 'FOAMING_AGENT',     'EQ', 'CYCLOPENTANE',   NULL, NULL, NULL, NULL, NULL),
('B17_GPI_NONPASSAGE', 'LAYING_METHOD',     'EQ', 'NONPASSAGE_CHANNEL', NULL, NULL, NULL, NULL, NULL);

-- ============================================================
-- Б.18: ГПИ бесканально
-- ============================================================
INSERT INTO tmp_b11_b22_selection_conditions VALUES
('B18_GPI_CHANNELLESS', 'PIPE_TYPE',         'EQ', 'TWO_PIPE_WATER', NULL, NULL, NULL, NULL, NULL),
('B18_GPI_CHANNELLESS', 'PIPE_CONSTRUCTION', 'EQ', 'GPI',            NULL, NULL, NULL, NULL, NULL),
('B18_GPI_CHANNELLESS', 'LAYING_METHOD',     'EQ', 'CHANNELLESS',     NULL, NULL, NULL, NULL, NULL);

-- ============================================================
-- Б.19: ГСИ в непроходном канале
-- ============================================================
INSERT INTO tmp_b11_b22_selection_conditions VALUES
('B19_GSI_NONPASSAGE', 'PIPE_TYPE',         'EQ', 'TWO_PIPE_WATER', NULL, NULL, NULL, NULL, NULL),
('B19_GSI_NONPASSAGE', 'PIPE_CONSTRUCTION', 'EQ', 'GSI',            NULL, NULL, NULL, NULL, NULL),
('B19_GSI_NONPASSAGE', 'LAYING_METHOD',     'EQ', 'NONPASSAGE_CHANNEL', NULL, NULL, NULL, NULL, NULL);

-- ============================================================
-- Б.20: ТСП; также база для ГСИ при бесканальной прокладке
-- ============================================================
INSERT INTO tmp_b11_b22_selection_conditions VALUES
('B20_TSP_CHANNELLESS', 'PIPE_TYPE',         'EQ', 'TWO_PIPE_WATER', NULL, NULL, NULL, NULL, NULL),
('B20_TSP_CHANNELLESS', 'PIPE_CONSTRUCTION', 'EQ', 'TSP',            NULL, NULL, NULL, NULL, NULL),
('B20_TSP_CHANNELLESS', 'LAYING_METHOD',     'EQ', 'CHANNELLESS',     NULL, NULL, NULL, NULL, NULL),

('B20_GSI_CHANNELLESS', 'PIPE_TYPE',         'EQ', 'TWO_PIPE_WATER', NULL, NULL, NULL, NULL, NULL),
('B20_GSI_CHANNELLESS', 'PIPE_CONSTRUCTION', 'EQ', 'GSI',            NULL, NULL, NULL, NULL, NULL),
('B20_GSI_CHANNELLESS', 'FOAMING_AGENT',     'EQ', 'CYCLOPENTANE',   NULL, NULL, NULL, NULL, NULL),
('B20_GSI_CHANNELLESS', 'LAYING_METHOD',     'EQ', 'CHANNELLESS',     NULL, NULL, NULL, NULL, NULL);

-- ============================================================
-- Б.21 / Б.22: ПИ по [1]
-- ============================================================
INSERT INTO tmp_b11_b22_selection_conditions VALUES
('B21_PI_REF1_NONPASSAGE', 'PIPE_TYPE',         'EQ', 'TWO_PIPE_WATER', NULL, NULL, NULL, NULL, NULL),
('B21_PI_REF1_NONPASSAGE', 'PIPE_CONSTRUCTION', 'EQ', 'PI_REF1',        NULL, NULL, NULL, NULL, NULL),
('B21_PI_REF1_NONPASSAGE', 'LAYING_METHOD',     'EQ', 'NONPASSAGE_CHANNEL', NULL, NULL, NULL, NULL, NULL),

('B22_PI_REF1_CHANNELLESS', 'PIPE_TYPE',         'EQ', 'TWO_PIPE_WATER', NULL, NULL, NULL, NULL, NULL),
('B22_PI_REF1_CHANNELLESS', 'PIPE_CONSTRUCTION', 'EQ', 'PI_REF1',        NULL, NULL, NULL, NULL, NULL),
('B22_PI_REF1_CHANNELLESS', 'LAYING_METHOD',     'EQ', 'CHANNELLESS',     NULL, NULL, NULL, NULL, NULL);


INSERT INTO qh_rule_conditions (
    rule_id,
    question_code,
    operator,
    value_text,
    value_numeric,
    value_numeric_to,
    value_date,
    value_date_to,
    value_boolean
)
SELECT
    r.id,
    c.question_code,
    c.operator,
    c.value_text,
    c.value_numeric,
    c.value_numeric_to,
    c.value_date,
    c.value_date_to,
    c.value_boolean
FROM tmp_b11_b22_selection_conditions c
JOIN qh_selection_rules r
    ON r.code = c.rule_code;


-- ============================================================
-- 10. qh_adjustment_rules Б.15-Б.20
--
-- Б.11-Б.14: специальных поправок из самих таблиц нет.
-- Б.21-Б.22: коэффициент 0.9 в примечаниях не указан.
--
-- Б.15 / Б.16: ПИ + циклопентан -> x0.9
-- Б.17 / Б.18: ГПИ + циклопентан -> x0.9
-- Б.19 / Б.20: ГСИ + циклопентан -> x0.9
-- ============================================================

DELETE FROM qh_adjustment_rules
WHERE description LIKE 'SEED_B11_B22:%';


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
    t.id,
    NULL,
    NULL,
    x.pipe_type,
    x.laying_method,
    'MULTIPLY',
    0.9,
    'FOAMING_AGENT',
    NULL,
    x.description,
    true
FROM (
    VALUES
        ('Б.15', 'TWO_PIPE_WATER', 'NONPASSAGE_CHANNEL', 'SEED_B11_B22:B15_CYCLOPENTANE_X0_9'),
        ('Б.16', 'TWO_PIPE_WATER', 'CHANNELLESS',         'SEED_B11_B22:B16_CYCLOPENTANE_X0_9'),
        ('Б.17', 'TWO_PIPE_WATER', 'NONPASSAGE_CHANNEL', 'SEED_B11_B22:B17_GPI_CYCLOPENTANE_X0_9'),
        ('Б.18', 'TWO_PIPE_WATER', 'CHANNELLESS',         'SEED_B11_B22:B18_GPI_CYCLOPENTANE_X0_9'),
        ('Б.19', 'TWO_PIPE_WATER', 'NONPASSAGE_CHANNEL', 'SEED_B11_B22:B19_GSI_CYCLOPENTANE_X0_9'),
        ('Б.20', 'TWO_PIPE_WATER', 'CHANNELLESS',         'SEED_B11_B22:B20_GSI_CYCLOPENTANE_X0_9')
) AS x(
    table_code,
    pipe_type,
    laying_method,
    description
)
JOIN qh_tables t
    ON t.code = x.table_code;


-- ============================================================
-- 11. CONDITIONS ДЛЯ ПОПРАВОК x0.9
-- ============================================================

-- DELETE выше каскадно удалил старые conditions наших правил.

CREATE TEMP TABLE tmp_b11_b22_adjustment_conditions (
    description       text NOT NULL,
    question_code     varchar(60) NOT NULL,
    operator          varchar(20) NOT NULL,
    value_text        text,
    value_numeric     numeric,
    value_numeric_to  numeric,
    value_date        date,
    value_date_to     date,
    value_boolean     boolean
) ON COMMIT DROP;

INSERT INTO tmp_b11_b22_adjustment_conditions VALUES
    -- Б.15: ПИ по СТБ 2252 + циклопентан
    ('SEED_B11_B22:B15_CYCLOPENTANE_X0_9', 'PIPE_CONSTRUCTION', 'EQ', 'PI_STB2252', NULL, NULL, NULL, NULL, NULL),
    ('SEED_B11_B22:B15_CYCLOPENTANE_X0_9', 'FOAMING_AGENT',     'EQ', 'CYCLOPENTANE', NULL, NULL, NULL, NULL, NULL),

    -- Б.16: ПИ по СТБ 2252 + циклопентан
    ('SEED_B11_B22:B16_CYCLOPENTANE_X0_9', 'PIPE_CONSTRUCTION', 'EQ', 'PI_STB2252', NULL, NULL, NULL, NULL, NULL),
    ('SEED_B11_B22:B16_CYCLOPENTANE_X0_9', 'FOAMING_AGENT',     'EQ', 'CYCLOPENTANE', NULL, NULL, NULL, NULL, NULL),

    -- Б.17: поправка именно для ГПИ с циклопентаном
    ('SEED_B11_B22:B17_GPI_CYCLOPENTANE_X0_9', 'PIPE_CONSTRUCTION', 'EQ', 'GPI', NULL, NULL, NULL, NULL, NULL),
    ('SEED_B11_B22:B17_GPI_CYCLOPENTANE_X0_9', 'FOAMING_AGENT',     'EQ', 'CYCLOPENTANE', NULL, NULL, NULL, NULL, NULL),

    -- Б.18: ГПИ + циклопентан
    ('SEED_B11_B22:B18_GPI_CYCLOPENTANE_X0_9', 'PIPE_CONSTRUCTION', 'EQ', 'GPI', NULL, NULL, NULL, NULL, NULL),
    ('SEED_B11_B22:B18_GPI_CYCLOPENTANE_X0_9', 'FOAMING_AGENT',     'EQ', 'CYCLOPENTANE', NULL, NULL, NULL, NULL, NULL),

    -- Б.19: ГСИ + циклопентан
    ('SEED_B11_B22:B19_GSI_CYCLOPENTANE_X0_9', 'PIPE_CONSTRUCTION', 'EQ', 'GSI', NULL, NULL, NULL, NULL, NULL),
    ('SEED_B11_B22:B19_GSI_CYCLOPENTANE_X0_9', 'FOAMING_AGENT',     'EQ', 'CYCLOPENTANE', NULL, NULL, NULL, NULL, NULL),

    -- Б.20: поправка именно для ГСИ с циклопентаном
    ('SEED_B11_B22:B20_GSI_CYCLOPENTANE_X0_9', 'PIPE_CONSTRUCTION', 'EQ', 'GSI', NULL, NULL, NULL, NULL, NULL),
    ('SEED_B11_B22:B20_GSI_CYCLOPENTANE_X0_9', 'FOAMING_AGENT',     'EQ', 'CYCLOPENTANE', NULL, NULL, NULL, NULL, NULL);


INSERT INTO qh_adjustment_rule_conditions (
    adjustment_rule_id,
    question_code,
    operator,
    value_text,
    value_numeric,
    value_numeric_to,
    value_date,
    value_date_to,
    value_boolean
)
SELECT
    ar.id,
    c.question_code,
    c.operator,
    c.value_text,
    c.value_numeric,
    c.value_numeric_to,
    c.value_date,
    c.value_date_to,
    c.value_boolean
FROM tmp_b11_b22_adjustment_conditions c
JOIN qh_adjustment_rules ar
    ON ar.description = c.description;


COMMIT;


-- ============================================================
-- ПРОВЕРКА 1: правила выбора Б.11-Б.22
-- ============================================================

SELECT
    r.code AS rule_code,
    t.code AS table_code,
    r.priority,
    c.question_code,
    c.operator,
    c.value_text,
    c.value_numeric,
    c.value_numeric_to,
    c.value_date,
    c.value_date_to
FROM qh_selection_rules r
JOIN qh_tables t
    ON t.id = r.qh_table_id
LEFT JOIN qh_rule_conditions c
    ON c.rule_id = r.id
WHERE r.code LIKE 'B11_%'
   OR r.code LIKE 'B12_%'
   OR r.code LIKE 'B13_%'
   OR r.code LIKE 'B14_%'
   OR r.code LIKE 'B15_%'
   OR r.code LIKE 'B16_%'
   OR r.code LIKE 'B17_%'
   OR r.code LIKE 'B18_%'
   OR r.code LIKE 'B19_%'
   OR r.code LIKE 'B20_%'
   OR r.code LIKE 'B21_%'
   OR r.code LIKE 'B22_%'
ORDER BY t.code, r.code, c.id;


-- ============================================================
-- ПРОВЕРКА 2: поправки Б.15-Б.20
-- ============================================================

SELECT
    t.code AS table_code,
    ar.operation,
    ar.factor,
    ar.description,
    c.question_code,
    c.operator,
    c.value_text
FROM qh_adjustment_rules ar
JOIN qh_tables t
    ON t.id = ar.qh_table_id
LEFT JOIN qh_adjustment_rule_conditions c
    ON c.adjustment_rule_id = ar.id
WHERE ar.description LIKE 'SEED_B11_B22:%'
ORDER BY t.code, ar.id, c.id;
