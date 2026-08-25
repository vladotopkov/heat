BEGIN;

-- ============================================================
-- ПРИЛОЖЕНИЕ В: В.1 - В.7
--
-- Заполняются:
--   qh_selection_rules
--   qh_rule_conditions
--   qh_adjustment_rules
--   qh_adjustment_rule_conditions (условия для x0.88)
--
-- ВАЖНО:
--   questions повторно НЕ создаются.
--
-- Добавляются только новые ВАРИАНТЫ уже существующих вопросов:
--   LAYING_METHOD     -> OPEN_AIR
--   PIPE_CONSTRUCTION -> PP_STB2252_GALVANIZED
--
-- Логика:
--
-- В.1: открытый воздух, >5000 ч/год, проект до 1990
-- В.2: открытый воздух, <=5000 ч/год, проект до 1990
--
-- В.3: открытый воздух, >5000 ч/год:
--      01.07.1995-31.12.2009 напрямую;
--      01.01.1990-30.06.1995 та же таблица, но qh / 0.8
--
-- В.4: открытый воздух, <=5000 ч/год:
--      01.07.1995-31.12.2009 напрямую;
--      01.01.1990-30.06.1995 та же таблица, но qh / 0.8
--
-- В.5: открытый воздух, >5000 ч/год, с 2010
-- В.6: открытый воздух, <=5000 ч/год, с 2010
--
-- В.7:
--   ПП-трубопровод в оцинкованной стальной оболочке по СТБ 2252
--   при открытой прокладке;
--
--   для ПИ-труб по СТБ 2252 с циклопентаном:
--   база В.7 x 0.88
-- ============================================================


-- ============================================================
-- 1. ПРОВЕРКА, ЧТО НУЖНЫЕ QUESTIONS УЖЕ СУЩЕСТВУЮТ
-- ============================================================

DO $$
DECLARE
    missing text;
BEGIN
    SELECT string_agg(x.code, ', ' ORDER BY x.code)
    INTO missing
    FROM (
        VALUES
            ('PROJECT_DATE'),
            ('LAYING_METHOD'),
            ('ANNUAL_OPERATING_HOURS'),
            ('PIPE_CONSTRUCTION'),
            ('FOAMING_AGENT')
    ) AS x(code)
    WHERE NOT EXISTS (
        SELECT 1
        FROM questions q
        WHERE q.code = x.code
    );

    IF missing IS NOT NULL THEN
        RAISE EXCEPTION
            'Отсутствуют questions: %. Сначала выполни предыдущие миграции вопросов.',
            missing;
    END IF;
END $$;


-- ============================================================
-- 2. НОВЫЕ OPTIONS, НО НЕ НОВЫЕ QUESTIONS
-- ============================================================

INSERT INTO question_options (
    question_code,
    value,
    label,
    sort_order,
    is_active
)
VALUES (
    'LAYING_METHOD',
    'OPEN_AIR',
    'Прокладка на открытом воздухе (надземная)',
    30,
    true
)
ON CONFLICT (question_code, value)
DO UPDATE SET
    label = EXCLUDED.label,
    sort_order = EXCLUDED.sort_order,
    is_active = true;


-- Существующий PP в предыдущем SQL означает ПП по ТУ изготовителя
-- для таблицы Б.17.
--
-- В.7 имеет другое исполнение:
-- ПП-трубопровод в трубе-оболочке из оцинкованной стали
-- по СТБ 2252.
-- Поэтому отдельный код, чтобы не смешивать две конструкции.

INSERT INTO question_options (
    question_code,
    value,
    label,
    sort_order,
    is_active
)
VALUES (
    'PIPE_CONSTRUCTION',
    'PP_STB2252_GALVANIZED',
    'ПП-трубопровод в трубе-оболочке из оцинкованной стали по СТБ 2252',
    80,
    true
)
ON CONFLICT (question_code, value)
DO UPDATE SET
    label = EXCLUDED.label,
    sort_order = EXCLUDED.sort_order,
    is_active = true;


-- ============================================================
-- 3. ПРОВЕРКА НУЖНЫХ OPTIONS
-- ============================================================

DO $$
DECLARE
    missing text;
BEGIN
    SELECT string_agg(x.question_code || '=' || x.value, ', ' ORDER BY x.question_code, x.value)
    INTO missing
    FROM (
        VALUES
            ('LAYING_METHOD',     'OPEN_AIR'),
            ('PIPE_CONSTRUCTION', 'STANDARD'),
            ('PIPE_CONSTRUCTION', 'PI_STB2252'),
            ('PIPE_CONSTRUCTION', 'PP_STB2252_GALVANIZED'),
            ('FOAMING_AGENT',     'CYCLOPENTANE')
    ) AS x(question_code, value)
    WHERE NOT EXISTS (
        SELECT 1
        FROM question_options qo
        WHERE qo.question_code = x.question_code
          AND qo.value = x.value
          AND qo.is_active = true
    );

    IF missing IS NOT NULL THEN
        RAISE EXCEPTION 'Отсутствуют question_options: %', missing;
    END IF;
END $$;


-- ============================================================
-- 4. ПРОВЕРКА qh_tables В.1 - В.7
-- ============================================================

DO $$
DECLARE
    missing text;
BEGIN
    SELECT string_agg(x.code, ', ' ORDER BY x.code)
    INTO missing
    FROM (
        VALUES
            ('В.1'),('В.2'),('В.3'),('В.4'),
            ('В.5'),('В.6'),('В.7')
    ) AS x(code)
    WHERE NOT EXISTS (
        SELECT 1
        FROM qh_tables t
        WHERE t.code = x.code
    );

    IF missing IS NOT NULL THEN
        RAISE EXCEPTION 'Отсутствуют qh_tables: %', missing;
    END IF;
END $$;


-- ============================================================
-- 5. УСЛОВИЯ ДЛЯ qh_adjustment_rules
--
-- Эта таблица уже создавалась в SQL для Б.11-Б.22.
-- IF NOT EXISTS оставлен для идемпотентности.
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
-- 6. qh_selection_rules
-- ============================================================

CREATE TEMP TABLE tmp_v1_v7_selection_rules (
    rule_code    varchar(80) PRIMARY KEY,
    table_code   varchar(10) NOT NULL,
    priority     integer NOT NULL,
    description  text NOT NULL
) ON COMMIT DROP;


INSERT INTO tmp_v1_v7_selection_rules (
    rule_code,
    table_code,
    priority,
    description
)
VALUES

(
    'V1_OPEN_AIR_GT5000_BEFORE_1990',
    'В.1',
    100,
    'В.1: обычный трубопровод, открытый воздух, >5000 ч/год, проект до 1990 г.'
),

(
    'V2_OPEN_AIR_LTE5000_BEFORE_1990',
    'В.2',
    100,
    'В.2: обычный трубопровод, открытый воздух, <=5000 ч/год, проект до 1990 г.'
),

(
    'V3_OPEN_AIR_GT5000_1990_2009',
    'В.3',
    100,
    'В.3: обычный трубопровод/поверхность, открытый воздух, >5000 ч/год, 1990-2009; до 01.07.1995 применяется /0.8'
),

(
    'V4_OPEN_AIR_LTE5000_1990_2009',
    'В.4',
    100,
    'В.4: обычный трубопровод/поверхность, открытый воздух, <=5000 ч/год, 1990-2009; до 01.07.1995 применяется /0.8'
),

(
    'V5_OPEN_AIR_GT5000_FROM_2010',
    'В.5',
    100,
    'В.5: обычный трубопровод/поверхность, открытый воздух, >5000 ч/год, с 2010 г.'
),

(
    'V6_OPEN_AIR_LTE5000_FROM_2010',
    'В.6',
    100,
    'В.6: обычный трубопровод/поверхность, открытый воздух, <=5000 ч/год, с 2010 г.'
),

(
    'V7_PP_STB2252_GALVANIZED_OPEN_AIR',
    'В.7',
    110,
    'В.7: ПП-трубопровод в оцинкованной стальной оболочке по СТБ 2252, открытый воздух'
),

(
    'V7_PI_STB2252_CYCLOPENTANE_OPEN_AIR',
    'В.7',
    120,
    'В.7: ПИ-трубопровод по СТБ 2252 с циклопентаном, открытый воздух; значения В.7 x0.88'
);


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
FROM tmp_v1_v7_selection_rules s
JOIN qh_tables t
    ON t.code = s.table_code
ON CONFLICT (code)
DO UPDATE SET
    qh_table_id = EXCLUDED.qh_table_id,
    priority = EXCLUDED.priority,
    description = EXCLUDED.description,
    is_active = true;


-- ============================================================
-- 7. ПЕРЕСОЗДАЕМ CONDITIONS ТОЛЬКО ДЛЯ В.1 - В.7
-- ============================================================

DELETE FROM qh_rule_conditions c
USING qh_selection_rules r
WHERE c.rule_id = r.id
  AND r.code IN (
      SELECT rule_code
      FROM tmp_v1_v7_selection_rules
  );


CREATE TEMP TABLE tmp_v1_v7_selection_conditions (
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
-- В.1
-- > 5000 ч/год
-- до 1990
-- ============================================================

INSERT INTO tmp_v1_v7_selection_conditions VALUES
(
    'V1_OPEN_AIR_GT5000_BEFORE_1990',
    'PROJECT_DATE',
    'LT',
    NULL, NULL, NULL,
    DATE '1990-01-01',
    NULL,
    NULL
),
(
    'V1_OPEN_AIR_GT5000_BEFORE_1990',
    'PIPE_CONSTRUCTION',
    'EQ',
    'STANDARD',
    NULL, NULL, NULL, NULL, NULL
),
(
    'V1_OPEN_AIR_GT5000_BEFORE_1990',
    'LAYING_METHOD',
    'EQ',
    'OPEN_AIR',
    NULL, NULL, NULL, NULL, NULL
),
(
    'V1_OPEN_AIR_GT5000_BEFORE_1990',
    'ANNUAL_OPERATING_HOURS',
    'GT',
    NULL,
    5000,
    NULL,
    NULL,
    NULL,
    NULL
);


-- ============================================================
-- В.2
-- <= 5000 ч/год
-- до 1990
-- ============================================================

INSERT INTO tmp_v1_v7_selection_conditions VALUES
(
    'V2_OPEN_AIR_LTE5000_BEFORE_1990',
    'PROJECT_DATE',
    'LT',
    NULL, NULL, NULL,
    DATE '1990-01-01',
    NULL,
    NULL
),
(
    'V2_OPEN_AIR_LTE5000_BEFORE_1990',
    'PIPE_CONSTRUCTION',
    'EQ',
    'STANDARD',
    NULL, NULL, NULL, NULL, NULL
),
(
    'V2_OPEN_AIR_LTE5000_BEFORE_1990',
    'LAYING_METHOD',
    'EQ',
    'OPEN_AIR',
    NULL, NULL, NULL, NULL, NULL
),
(
    'V2_OPEN_AIR_LTE5000_BEFORE_1990',
    'ANNUAL_OPERATING_HOURS',
    'LTE',
    NULL,
    5000,
    NULL,
    NULL,
    NULL,
    NULL
);


-- ============================================================
-- В.3
--
-- В самой таблице указан период:
--   01.07.1995 - 31.12.2009
--
-- Но примечание требует для:
--   01.01.1990 - 30.06.1995
--
-- использовать нормы В.3 / 0.8.
--
-- Поэтому правило выбора В.3 покрывает весь 1990-2009,
-- а поправка ниже применяется только к ранней части.
-- ============================================================

INSERT INTO tmp_v1_v7_selection_conditions VALUES
(
    'V3_OPEN_AIR_GT5000_1990_2009',
    'PROJECT_DATE',
    'BETWEEN',
    NULL, NULL, NULL,
    DATE '1990-01-01',
    DATE '2009-12-31',
    NULL
),
(
    'V3_OPEN_AIR_GT5000_1990_2009',
    'PIPE_CONSTRUCTION',
    'EQ',
    'STANDARD',
    NULL, NULL, NULL, NULL, NULL
),
(
    'V3_OPEN_AIR_GT5000_1990_2009',
    'LAYING_METHOD',
    'EQ',
    'OPEN_AIR',
    NULL, NULL, NULL, NULL, NULL
),
(
    'V3_OPEN_AIR_GT5000_1990_2009',
    'ANNUAL_OPERATING_HOURS',
    'GT',
    NULL,
    5000,
    NULL,
    NULL,
    NULL,
    NULL
);


-- ============================================================
-- В.4
-- ============================================================

INSERT INTO tmp_v1_v7_selection_conditions VALUES
(
    'V4_OPEN_AIR_LTE5000_1990_2009',
    'PROJECT_DATE',
    'BETWEEN',
    NULL, NULL, NULL,
    DATE '1990-01-01',
    DATE '2009-12-31',
    NULL
),
(
    'V4_OPEN_AIR_LTE5000_1990_2009',
    'PIPE_CONSTRUCTION',
    'EQ',
    'STANDARD',
    NULL, NULL, NULL, NULL, NULL
),
(
    'V4_OPEN_AIR_LTE5000_1990_2009',
    'LAYING_METHOD',
    'EQ',
    'OPEN_AIR',
    NULL, NULL, NULL, NULL, NULL
),
(
    'V4_OPEN_AIR_LTE5000_1990_2009',
    'ANNUAL_OPERATING_HOURS',
    'LTE',
    NULL,
    5000,
    NULL,
    NULL,
    NULL,
    NULL
);


-- ============================================================
-- В.5
-- >5000, с 2010
-- ============================================================

INSERT INTO tmp_v1_v7_selection_conditions VALUES
(
    'V5_OPEN_AIR_GT5000_FROM_2010',
    'PROJECT_DATE',
    'GTE',
    NULL, NULL, NULL,
    DATE '2010-01-01',
    NULL,
    NULL
),
(
    'V5_OPEN_AIR_GT5000_FROM_2010',
    'PIPE_CONSTRUCTION',
    'EQ',
    'STANDARD',
    NULL, NULL, NULL, NULL, NULL
),
(
    'V5_OPEN_AIR_GT5000_FROM_2010',
    'LAYING_METHOD',
    'EQ',
    'OPEN_AIR',
    NULL, NULL, NULL, NULL, NULL
),
(
    'V5_OPEN_AIR_GT5000_FROM_2010',
    'ANNUAL_OPERATING_HOURS',
    'GT',
    NULL,
    5000,
    NULL,
    NULL,
    NULL,
    NULL
);


-- ============================================================
-- В.6
-- <=5000, с 2010
-- ============================================================

INSERT INTO tmp_v1_v7_selection_conditions VALUES
(
    'V6_OPEN_AIR_LTE5000_FROM_2010',
    'PROJECT_DATE',
    'GTE',
    NULL, NULL, NULL,
    DATE '2010-01-01',
    NULL,
    NULL
),
(
    'V6_OPEN_AIR_LTE5000_FROM_2010',
    'PIPE_CONSTRUCTION',
    'EQ',
    'STANDARD',
    NULL, NULL, NULL, NULL, NULL
),
(
    'V6_OPEN_AIR_LTE5000_FROM_2010',
    'LAYING_METHOD',
    'EQ',
    'OPEN_AIR',
    NULL, NULL, NULL, NULL, NULL
),
(
    'V6_OPEN_AIR_LTE5000_FROM_2010',
    'ANNUAL_OPERATING_HOURS',
    'LTE',
    NULL,
    5000,
    NULL,
    NULL,
    NULL,
    NULL
);


-- ============================================================
-- В.7
-- ПП в оцинкованной оболочке по СТБ 2252
--
-- Здесь год и число часов НЕ являются условиями таблицы.
-- ============================================================

INSERT INTO tmp_v1_v7_selection_conditions VALUES
(
    'V7_PP_STB2252_GALVANIZED_OPEN_AIR',
    'PIPE_CONSTRUCTION',
    'EQ',
    'PP_STB2252_GALVANIZED',
    NULL, NULL, NULL, NULL, NULL
),
(
    'V7_PP_STB2252_GALVANIZED_OPEN_AIR',
    'LAYING_METHOD',
    'EQ',
    'OPEN_AIR',
    NULL, NULL, NULL, NULL, NULL
);


-- ============================================================
-- В.7 как база для ПИ по СТБ 2252 + циклопентан
-- ============================================================

INSERT INTO tmp_v1_v7_selection_conditions VALUES
(
    'V7_PI_STB2252_CYCLOPENTANE_OPEN_AIR',
    'PIPE_CONSTRUCTION',
    'EQ',
    'PI_STB2252',
    NULL, NULL, NULL, NULL, NULL
),
(
    'V7_PI_STB2252_CYCLOPENTANE_OPEN_AIR',
    'FOAMING_AGENT',
    'EQ',
    'CYCLOPENTANE',
    NULL, NULL, NULL, NULL, NULL
),
(
    'V7_PI_STB2252_CYCLOPENTANE_OPEN_AIR',
    'LAYING_METHOD',
    'EQ',
    'OPEN_AIR',
    NULL, NULL, NULL, NULL, NULL
);


-- ============================================================
-- ЗАПИСЫВАЕМ qh_rule_conditions
-- ============================================================

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
FROM tmp_v1_v7_selection_conditions c
JOIN qh_selection_rules r
    ON r.code = c.rule_code;


-- ============================================================
-- 8. qh_adjustment_rules
-- ============================================================

DELETE FROM qh_adjustment_rules
WHERE description LIKE 'SEED_V1_V7:%';


-- ============================================================
-- В.3 / В.4
--
-- Проекты с 01.01.1990 до 30.06.1995:
--
-- qh = значение таблицы / 0.8
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
    t.id,
    DATE '1990-01-01',
    DATE '1995-06-30',
    NULL,
    'OPEN_AIR',
    'DIVIDE',
    0.8,
    'PROJECT_DATE',
    NULL,
    x.description,
    true
FROM (
    VALUES
        ('В.3', 'SEED_V1_V7:V3_1990_19950630_DIVIDE_0_8'),
        ('В.4', 'SEED_V1_V7:V4_1990_19950630_DIVIDE_0_8')
) AS x(table_code, description)
JOIN qh_tables t
    ON t.code = x.table_code;


-- ============================================================
-- В.7
--
-- ПИ по СТБ 2252 + вспениватель циклопентан:
--
-- qh = значение В.7 x 0.88
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
    t.id,
    NULL,
    NULL,
    NULL,
    'OPEN_AIR',
    'MULTIPLY',
    0.88,
    'FOAMING_AGENT',
    NULL,
    'SEED_V1_V7:V7_PI_STB2252_CYCLOPENTANE_X0_88',
    true
FROM qh_tables t
WHERE t.code = 'В.7';


-- ============================================================
-- 9. УСЛОВИЯ ДЛЯ ПОПРАВКИ В.7 x0.88
-- ============================================================

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
FROM (
    VALUES
        (
            'PIPE_CONSTRUCTION',
            'EQ',
            'PI_STB2252'::text,
            NULL::numeric,
            NULL::numeric,
            NULL::date,
            NULL::date,
            NULL::boolean
        ),
        (
            'FOAMING_AGENT',
            'EQ',
            'CYCLOPENTANE'::text,
            NULL::numeric,
            NULL::numeric,
            NULL::date,
            NULL::date,
            NULL::boolean
        )
) AS c(
    question_code,
    operator,
    value_text,
    value_numeric,
    value_numeric_to,
    value_date,
    value_date_to,
    value_boolean
)
JOIN qh_adjustment_rules ar
    ON ar.description = 'SEED_V1_V7:V7_PI_STB2252_CYCLOPENTANE_X0_88';


COMMIT;


-- ============================================================
-- ПРОВЕРКА 1:
-- qh_selection_rules + qh_rule_conditions
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
WHERE r.code LIKE 'V1_%'
   OR r.code LIKE 'V2_%'
   OR r.code LIKE 'V3_%'
   OR r.code LIKE 'V4_%'
   OR r.code LIKE 'V5_%'
   OR r.code LIKE 'V6_%'
   OR r.code LIKE 'V7_%'
ORDER BY t.code, r.code, c.id;


-- ============================================================
-- ПРОВЕРКА 2:
-- qh_adjustment_rules
-- ============================================================

SELECT
    t.code AS table_code,
    ar.project_date_from,
    ar.project_date_to,
    ar.laying_method,
    ar.operation,
    ar.factor,
    ar.requires_question,
    ar.description,
    c.question_code,
    c.operator,
    c.value_text
FROM qh_adjustment_rules ar
JOIN qh_tables t
    ON t.id = ar.qh_table_id
LEFT JOIN qh_adjustment_rule_conditions c
    ON c.adjustment_rule_id = ar.id
WHERE ar.description LIKE 'SEED_V1_V7:%'
ORDER BY t.code, ar.id, c.id;
