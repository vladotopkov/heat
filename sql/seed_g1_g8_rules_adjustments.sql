BEGIN;

-- ============================================================
-- ПРИЛОЖЕНИЕ Г: Г.1 - Г.8
--
-- Заполняются:
--   qh_selection_rules
--   qh_rule_conditions
--   qh_adjustment_rules
--   qh_adjustment_rule_conditions
--
-- QUESTIONS повторно НЕ создаются.
--
-- Добавляются только новые OPTIONS существующих вопросов:
--   LAYING_METHOD:
--       ROOM
--       TUNNEL
--
--   PIPE_CONSTRUCTION:
--       SMIGLEKS_P_MVT
--
-- ЛОГИКА:
--
-- Г.1:
--   ROOM / TUNNEL
--   > 5000 ч/год
--   проект до 1990
--
-- Г.2:
--   ROOM / TUNNEL
--   <= 5000 ч/год
--   проект до 1990
--
-- Г.3:
--   ROOM / TUNNEL
--   > 5000 ч/год
--   1990-2009
--   для 01.01.1990-30.06.1995: qh / 0.8
--
-- Г.4:
--   ROOM / TUNNEL
--   <= 5000 ч/год
--   1990-2009
--   для 01.01.1990-30.06.1995: qh / 0.8
--
-- Г.5:
--   ROOM / TUNNEL
--   > 5000 ч/год
--   с 2010
--
-- Г.6:
--   ROOM / TUNNEL
--   <= 5000 ч/год
--   с 2010
--
-- Г.7:
--   PI_STB2252
--   ROOM / TUNNEL
--   при FOAMING_AGENT=CYCLOPENTANE:
--       qh x 0.88
--
-- Г.8:
--   СМИГЛЕКС-П МВТ
--   только ROOM
--
-- ВАЖНО:
--   Для Г.3-Г.6 OBJECT_KIND (PIPE/SURFACE) НЕ является
--   условием выбора таблицы. Это выбор строки внутри уже
--   выбранной таблицы через qh_table_dimensions.
-- ============================================================


-- ============================================================
-- 1. ПРОВЕРКА ОБЯЗАТЕЛЬНЫХ QUESTIONS
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
-- 2. ДОБАВЛЯЕМ ТОЛЬКО НОВЫЕ OPTIONS
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
    'LAYING_METHOD',
    'ROOM',
    'Прокладка в помещении (техническом подполье)',
    40,
    true
),
(
    'LAYING_METHOD',
    'TUNNEL',
    'Прокладка в тоннеле (проходном канале)',
    50,
    true
)
ON CONFLICT (question_code, value)
DO UPDATE SET
    label = EXCLUDED.label,
    sort_order = EXCLUDED.sort_order,
    is_active = true;


INSERT INTO question_options (
    question_code,
    value,
    label,
    sort_order,
    is_active
)
VALUES (
    'PIPE_CONSTRUCTION',
    'SMIGLEKS_P_MVT',
    'Трубопровод СМИГЛЕКС-П МВТ',
    90,
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
    SELECT string_agg(
        x.question_code || '=' || x.value,
        ', '
        ORDER BY x.question_code, x.value
    )
    INTO missing
    FROM (
        VALUES
            ('LAYING_METHOD',     'ROOM'),
            ('LAYING_METHOD',     'TUNNEL'),
            ('PIPE_CONSTRUCTION', 'STANDARD'),
            ('PIPE_CONSTRUCTION', 'PI_STB2252'),
            ('PIPE_CONSTRUCTION', 'SMIGLEKS_P_MVT'),
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
-- 4. ПРОВЕРКА qh_tables Г.1 - Г.8
-- ============================================================

DO $$
DECLARE
    missing text;
BEGIN
    SELECT string_agg(x.code, ', ' ORDER BY x.code)
    INTO missing
    FROM (
        VALUES
            ('Г.1'),('Г.2'),('Г.3'),('Г.4'),
            ('Г.5'),('Г.6'),('Г.7'),('Г.8')
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
-- 5. ПРОВЕРКА DATE-ПОЛЕЙ В qh_rule_conditions
--
-- Они уже использовались в seed Б.11-Б.22.
-- Здесь только понятная ошибка, если та миграция не была выполнена.
-- ============================================================

DO $$
DECLARE
    missing text;
BEGIN
    SELECT string_agg(x.column_name, ', ' ORDER BY x.column_name)
    INTO missing
    FROM (
        VALUES
            ('value_date'),
            ('value_date_to'),
            ('value_boolean')
    ) AS x(column_name)
    WHERE NOT EXISTS (
        SELECT 1
        FROM information_schema.columns c
        WHERE c.table_schema = 'public'
          AND c.table_name = 'qh_rule_conditions'
          AND c.column_name = x.column_name
    );

    IF missing IS NOT NULL THEN
        RAISE EXCEPTION
            'В qh_rule_conditions отсутствуют поля: %',
            missing;
    END IF;
END $$;


-- ============================================================
-- 6. УСЛОВИЯ ДЛЯ qh_adjustment_rules
--
-- Таблица уже создавалась при Б.11-Б.22.
-- Оставляем IF NOT EXISTS для повторного безопасного запуска.
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
-- 7. qh_selection_rules
--
-- Для таблиц, применимых и к ROOM, и к TUNNEL,
-- создается отдельное правило на каждый способ прокладки.
--
-- Причина простая:
-- qh_rule_conditions пока не поддерживает оператор IN.
-- ============================================================

CREATE TEMP TABLE tmp_g1_g8_selection_rules (
    rule_code    varchar(100) PRIMARY KEY,
    table_code   varchar(10) NOT NULL,
    priority     integer NOT NULL,
    description  text NOT NULL
) ON COMMIT DROP;


INSERT INTO tmp_g1_g8_selection_rules (
    rule_code,
    table_code,
    priority,
    description
)
VALUES

-- ------------------------------------------------------------
-- Г.1
-- ------------------------------------------------------------
(
    'G1_ROOM_GT5000_BEFORE_1990',
    'Г.1',
    100,
    'Г.1: обычный трубопровод, помещение/техническое подполье, >5000 ч/год, проект до 1990 г.'
),
(
    'G1_TUNNEL_GT5000_BEFORE_1990',
    'Г.1',
    100,
    'Г.1: обычный трубопровод, тоннель/проходной канал, >5000 ч/год, проект до 1990 г.'
),

-- ------------------------------------------------------------
-- Г.2
-- ------------------------------------------------------------
(
    'G2_ROOM_LTE5000_BEFORE_1990',
    'Г.2',
    100,
    'Г.2: обычный трубопровод, помещение/техническое подполье, <=5000 ч/год, проект до 1990 г.'
),
(
    'G2_TUNNEL_LTE5000_BEFORE_1990',
    'Г.2',
    100,
    'Г.2: обычный трубопровод, тоннель/проходной канал, <=5000 ч/год, проект до 1990 г.'
),

-- ------------------------------------------------------------
-- Г.3
-- ------------------------------------------------------------
(
    'G3_ROOM_GT5000_1990_2009',
    'Г.3',
    100,
    'Г.3: обычный трубопровод/оборудование, помещение, >5000 ч/год, 1990-2009; до 01.07.1995 применяется /0.8'
),
(
    'G3_TUNNEL_GT5000_1990_2009',
    'Г.3',
    100,
    'Г.3: обычный трубопровод/оборудование, тоннель, >5000 ч/год, 1990-2009; до 01.07.1995 применяется /0.8'
),

-- ------------------------------------------------------------
-- Г.4
-- ------------------------------------------------------------
(
    'G4_ROOM_LTE5000_1990_2009',
    'Г.4',
    100,
    'Г.4: обычный трубопровод/оборудование, помещение, <=5000 ч/год, 1990-2009; до 01.07.1995 применяется /0.8'
),
(
    'G4_TUNNEL_LTE5000_1990_2009',
    'Г.4',
    100,
    'Г.4: обычный трубопровод/оборудование, тоннель, <=5000 ч/год, 1990-2009; до 01.07.1995 применяется /0.8'
),

-- ------------------------------------------------------------
-- Г.5
-- ------------------------------------------------------------
(
    'G5_ROOM_GT5000_FROM_2010',
    'Г.5',
    100,
    'Г.5: обычный трубопровод/оборудование, помещение, >5000 ч/год, с 2010 г.'
),
(
    'G5_TUNNEL_GT5000_FROM_2010',
    'Г.5',
    100,
    'Г.5: обычный трубопровод/оборудование, тоннель, >5000 ч/год, с 2010 г.'
),

-- ------------------------------------------------------------
-- Г.6
-- ------------------------------------------------------------
(
    'G6_ROOM_LTE5000_FROM_2010',
    'Г.6',
    100,
    'Г.6: обычный трубопровод/оборудование, помещение, <=5000 ч/год, с 2010 г.'
),
(
    'G6_TUNNEL_LTE5000_FROM_2010',
    'Г.6',
    100,
    'Г.6: обычный трубопровод/оборудование, тоннель, <=5000 ч/год, с 2010 г.'
),

-- ------------------------------------------------------------
-- Г.7
-- ПИ по СТБ 2252.
-- При циклопентане таблица та же, затем x0.88.
-- ------------------------------------------------------------
(
    'G7_PI_STB2252_ROOM',
    'Г.7',
    120,
    'Г.7: ПИ-трубопровод по СТБ 2252, помещение/техническое подполье'
),
(
    'G7_PI_STB2252_TUNNEL',
    'Г.7',
    120,
    'Г.7: ПИ-трубопровод по СТБ 2252, тоннель/проходной канал'
),

-- ------------------------------------------------------------
-- Г.8
-- Только помещение.
-- ------------------------------------------------------------
(
    'G8_SMIGLEKS_P_MVT_ROOM',
    'Г.8',
    130,
    'Г.8: трубопровод СМИГЛЕКС-П МВТ, помещение/техническое подполье'
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
FROM tmp_g1_g8_selection_rules s
JOIN qh_tables t
    ON t.code = s.table_code
ON CONFLICT (code)
DO UPDATE SET
    qh_table_id = EXCLUDED.qh_table_id,
    priority = EXCLUDED.priority,
    description = EXCLUDED.description,
    is_active = true;


-- ============================================================
-- 8. ПЕРЕСОЗДАЕМ CONDITIONS ТОЛЬКО ДЛЯ НАШИХ Г.1-Г.8 RULES
-- ============================================================

DELETE FROM qh_rule_conditions c
USING qh_selection_rules r
WHERE c.rule_id = r.id
  AND r.code IN (
      SELECT rule_code
      FROM tmp_g1_g8_selection_rules
  );


CREATE TEMP TABLE tmp_g1_g8_selection_conditions (
    rule_code          varchar(100) NOT NULL,
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
-- Г.1
-- ============================================================

INSERT INTO tmp_g1_g8_selection_conditions VALUES

(
    'G1_ROOM_GT5000_BEFORE_1990',
    'PROJECT_DATE',
    'LT',
    NULL, NULL, NULL,
    DATE '1990-01-01',
    NULL,
    NULL
),
(
    'G1_ROOM_GT5000_BEFORE_1990',
    'PIPE_CONSTRUCTION',
    'EQ',
    'STANDARD',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G1_ROOM_GT5000_BEFORE_1990',
    'LAYING_METHOD',
    'EQ',
    'ROOM',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G1_ROOM_GT5000_BEFORE_1990',
    'ANNUAL_OPERATING_HOURS',
    'GT',
    NULL,
    5000,
    NULL,
    NULL,
    NULL,
    NULL
),

(
    'G1_TUNNEL_GT5000_BEFORE_1990',
    'PROJECT_DATE',
    'LT',
    NULL, NULL, NULL,
    DATE '1990-01-01',
    NULL,
    NULL
),
(
    'G1_TUNNEL_GT5000_BEFORE_1990',
    'PIPE_CONSTRUCTION',
    'EQ',
    'STANDARD',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G1_TUNNEL_GT5000_BEFORE_1990',
    'LAYING_METHOD',
    'EQ',
    'TUNNEL',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G1_TUNNEL_GT5000_BEFORE_1990',
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
-- Г.2
-- ============================================================

INSERT INTO tmp_g1_g8_selection_conditions VALUES

(
    'G2_ROOM_LTE5000_BEFORE_1990',
    'PROJECT_DATE',
    'LT',
    NULL, NULL, NULL,
    DATE '1990-01-01',
    NULL,
    NULL
),
(
    'G2_ROOM_LTE5000_BEFORE_1990',
    'PIPE_CONSTRUCTION',
    'EQ',
    'STANDARD',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G2_ROOM_LTE5000_BEFORE_1990',
    'LAYING_METHOD',
    'EQ',
    'ROOM',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G2_ROOM_LTE5000_BEFORE_1990',
    'ANNUAL_OPERATING_HOURS',
    'LTE',
    NULL,
    5000,
    NULL,
    NULL,
    NULL,
    NULL
),

(
    'G2_TUNNEL_LTE5000_BEFORE_1990',
    'PROJECT_DATE',
    'LT',
    NULL, NULL, NULL,
    DATE '1990-01-01',
    NULL,
    NULL
),
(
    'G2_TUNNEL_LTE5000_BEFORE_1990',
    'PIPE_CONSTRUCTION',
    'EQ',
    'STANDARD',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G2_TUNNEL_LTE5000_BEFORE_1990',
    'LAYING_METHOD',
    'EQ',
    'TUNNEL',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G2_TUNNEL_LTE5000_BEFORE_1990',
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
-- Г.3
--
-- Таблица источника: 01.07.1995-31.12.2009.
-- Для 01.01.1990-30.06.1995 используется та же Г.3 / 0.8.
--
-- Поэтому selection покрывает весь 1990-2009.
-- ============================================================

INSERT INTO tmp_g1_g8_selection_conditions VALUES

(
    'G3_ROOM_GT5000_1990_2009',
    'PROJECT_DATE',
    'BETWEEN',
    NULL, NULL, NULL,
    DATE '1990-01-01',
    DATE '2009-12-31',
    NULL
),
(
    'G3_ROOM_GT5000_1990_2009',
    'PIPE_CONSTRUCTION',
    'EQ',
    'STANDARD',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G3_ROOM_GT5000_1990_2009',
    'LAYING_METHOD',
    'EQ',
    'ROOM',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G3_ROOM_GT5000_1990_2009',
    'ANNUAL_OPERATING_HOURS',
    'GT',
    NULL,
    5000,
    NULL,
    NULL,
    NULL,
    NULL
),

(
    'G3_TUNNEL_GT5000_1990_2009',
    'PROJECT_DATE',
    'BETWEEN',
    NULL, NULL, NULL,
    DATE '1990-01-01',
    DATE '2009-12-31',
    NULL
),
(
    'G3_TUNNEL_GT5000_1990_2009',
    'PIPE_CONSTRUCTION',
    'EQ',
    'STANDARD',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G3_TUNNEL_GT5000_1990_2009',
    'LAYING_METHOD',
    'EQ',
    'TUNNEL',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G3_TUNNEL_GT5000_1990_2009',
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
-- Г.4
-- ============================================================

INSERT INTO tmp_g1_g8_selection_conditions VALUES

(
    'G4_ROOM_LTE5000_1990_2009',
    'PROJECT_DATE',
    'BETWEEN',
    NULL, NULL, NULL,
    DATE '1990-01-01',
    DATE '2009-12-31',
    NULL
),
(
    'G4_ROOM_LTE5000_1990_2009',
    'PIPE_CONSTRUCTION',
    'EQ',
    'STANDARD',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G4_ROOM_LTE5000_1990_2009',
    'LAYING_METHOD',
    'EQ',
    'ROOM',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G4_ROOM_LTE5000_1990_2009',
    'ANNUAL_OPERATING_HOURS',
    'LTE',
    NULL,
    5000,
    NULL,
    NULL,
    NULL,
    NULL
),

(
    'G4_TUNNEL_LTE5000_1990_2009',
    'PROJECT_DATE',
    'BETWEEN',
    NULL, NULL, NULL,
    DATE '1990-01-01',
    DATE '2009-12-31',
    NULL
),
(
    'G4_TUNNEL_LTE5000_1990_2009',
    'PIPE_CONSTRUCTION',
    'EQ',
    'STANDARD',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G4_TUNNEL_LTE5000_1990_2009',
    'LAYING_METHOD',
    'EQ',
    'TUNNEL',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G4_TUNNEL_LTE5000_1990_2009',
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
-- Г.5
--
-- В самой qh_values для Г.5 placement_variant = NULL,
-- потому что источник дает один набор норм для ROOM/TUNNEL.
--
-- Но TABLE SELECTION обязан различать ROOM/TUNNEL от OPEN_AIR
-- и подземной прокладки, поэтому оставляем два selection rules.
-- ============================================================

INSERT INTO tmp_g1_g8_selection_conditions VALUES

(
    'G5_ROOM_GT5000_FROM_2010',
    'PROJECT_DATE',
    'GTE',
    NULL, NULL, NULL,
    DATE '2010-01-01',
    NULL,
    NULL
),
(
    'G5_ROOM_GT5000_FROM_2010',
    'PIPE_CONSTRUCTION',
    'EQ',
    'STANDARD',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G5_ROOM_GT5000_FROM_2010',
    'LAYING_METHOD',
    'EQ',
    'ROOM',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G5_ROOM_GT5000_FROM_2010',
    'ANNUAL_OPERATING_HOURS',
    'GT',
    NULL,
    5000,
    NULL,
    NULL,
    NULL,
    NULL
),

(
    'G5_TUNNEL_GT5000_FROM_2010',
    'PROJECT_DATE',
    'GTE',
    NULL, NULL, NULL,
    DATE '2010-01-01',
    NULL,
    NULL
),
(
    'G5_TUNNEL_GT5000_FROM_2010',
    'PIPE_CONSTRUCTION',
    'EQ',
    'STANDARD',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G5_TUNNEL_GT5000_FROM_2010',
    'LAYING_METHOD',
    'EQ',
    'TUNNEL',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G5_TUNNEL_GT5000_FROM_2010',
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
-- Г.6
-- ============================================================

INSERT INTO tmp_g1_g8_selection_conditions VALUES

(
    'G6_ROOM_LTE5000_FROM_2010',
    'PROJECT_DATE',
    'GTE',
    NULL, NULL, NULL,
    DATE '2010-01-01',
    NULL,
    NULL
),
(
    'G6_ROOM_LTE5000_FROM_2010',
    'PIPE_CONSTRUCTION',
    'EQ',
    'STANDARD',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G6_ROOM_LTE5000_FROM_2010',
    'LAYING_METHOD',
    'EQ',
    'ROOM',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G6_ROOM_LTE5000_FROM_2010',
    'ANNUAL_OPERATING_HOURS',
    'LTE',
    NULL,
    5000,
    NULL,
    NULL,
    NULL,
    NULL
),

(
    'G6_TUNNEL_LTE5000_FROM_2010',
    'PROJECT_DATE',
    'GTE',
    NULL, NULL, NULL,
    DATE '2010-01-01',
    NULL,
    NULL
),
(
    'G6_TUNNEL_LTE5000_FROM_2010',
    'PIPE_CONSTRUCTION',
    'EQ',
    'STANDARD',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G6_TUNNEL_LTE5000_FROM_2010',
    'LAYING_METHOD',
    'EQ',
    'TUNNEL',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G6_TUNNEL_LTE5000_FROM_2010',
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
-- Г.7
-- ============================================================

INSERT INTO tmp_g1_g8_selection_conditions VALUES

(
    'G7_PI_STB2252_ROOM',
    'PIPE_CONSTRUCTION',
    'EQ',
    'PI_STB2252',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G7_PI_STB2252_ROOM',
    'LAYING_METHOD',
    'EQ',
    'ROOM',
    NULL, NULL, NULL, NULL, NULL
),

(
    'G7_PI_STB2252_TUNNEL',
    'PIPE_CONSTRUCTION',
    'EQ',
    'PI_STB2252',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G7_PI_STB2252_TUNNEL',
    'LAYING_METHOD',
    'EQ',
    'TUNNEL',
    NULL, NULL, NULL, NULL, NULL
);


-- ============================================================
-- Г.8
-- ============================================================

INSERT INTO tmp_g1_g8_selection_conditions VALUES

(
    'G8_SMIGLEKS_P_MVT_ROOM',
    'PIPE_CONSTRUCTION',
    'EQ',
    'SMIGLEKS_P_MVT',
    NULL, NULL, NULL, NULL, NULL
),
(
    'G8_SMIGLEKS_P_MVT_ROOM',
    'LAYING_METHOD',
    'EQ',
    'ROOM',
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
FROM tmp_g1_g8_selection_conditions c
JOIN qh_selection_rules r
    ON r.code = c.rule_code;


-- ============================================================
-- 9. qh_adjustment_rules
-- ============================================================

DELETE FROM qh_adjustment_rules
WHERE description LIKE 'SEED_G1_G8:%';


-- ============================================================
-- Г.3 / Г.4
--
-- Для тепловых сетей, сооруженных по проектам:
--   01.01.1990 - 30.06.1995
--
-- qh = значение Г.3 / 0.8
-- qh = значение Г.4 / 0.8
--
-- Поправка не зависит от ROOM/TUNNEL:
-- таблица уже выбрана, поэтому laying_method здесь можно NULL.
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
    NULL,
    'DIVIDE',
    0.8,
    'PROJECT_DATE',
    NULL,
    x.description,
    true
FROM (
    VALUES
        ('Г.3', 'SEED_G1_G8:G3_1990_19950630_DIVIDE_0_8'),
        ('Г.4', 'SEED_G1_G8:G4_1990_19950630_DIVIDE_0_8')
) AS x(table_code, description)
JOIN qh_tables t
    ON t.code = x.table_code;


-- ============================================================
-- Г.7
--
-- ПИ по СТБ 2252 + циклопентан:
--
-- qh = значение Г.7 x 0.88
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
    NULL,
    'MULTIPLY',
    0.88,
    'FOAMING_AGENT',
    NULL,
    'SEED_G1_G8:G7_PI_STB2252_CYCLOPENTANE_X0_88',
    true
FROM qh_tables t
WHERE t.code = 'Г.7';


-- ============================================================
-- 10. CONDITIONS ДЛЯ ПОПРАВКИ Г.7 x0.88
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
    ON ar.description =
       'SEED_G1_G8:G7_PI_STB2252_CYCLOPENTANE_X0_88';


COMMIT;


-- ============================================================
-- ПРОВЕРКА 1:
-- qh_selection_rules + qh_rule_conditions
--
-- Ожидается:
-- Г.1 = 2 rules
-- Г.2 = 2
-- Г.3 = 2
-- Г.4 = 2
-- Г.5 = 2
-- Г.6 = 2
-- Г.7 = 2
-- Г.8 = 1
--
-- ИТОГО = 15 rules
-- ============================================================

SELECT
    t.code AS table_code,
    r.code AS rule_code,
    r.priority,
    r.description,
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
WHERE r.code IN (
    'G1_ROOM_GT5000_BEFORE_1990',
    'G1_TUNNEL_GT5000_BEFORE_1990',

    'G2_ROOM_LTE5000_BEFORE_1990',
    'G2_TUNNEL_LTE5000_BEFORE_1990',

    'G3_ROOM_GT5000_1990_2009',
    'G3_TUNNEL_GT5000_1990_2009',

    'G4_ROOM_LTE5000_1990_2009',
    'G4_TUNNEL_LTE5000_1990_2009',

    'G5_ROOM_GT5000_FROM_2010',
    'G5_TUNNEL_GT5000_FROM_2010',

    'G6_ROOM_LTE5000_FROM_2010',
    'G6_TUNNEL_LTE5000_FROM_2010',

    'G7_PI_STB2252_ROOM',
    'G7_PI_STB2252_TUNNEL',

    'G8_SMIGLEKS_P_MVT_ROOM'
)
ORDER BY
    t.code,
    r.code,
    c.id;


-- ============================================================
-- ПРОВЕРКА 2:
-- количество selection rules
-- ============================================================

SELECT
    t.code AS table_code,
    count(*) AS rules_count
FROM qh_selection_rules r
JOIN qh_tables t
    ON t.id = r.qh_table_id
WHERE r.code IN (
    'G1_ROOM_GT5000_BEFORE_1990',
    'G1_TUNNEL_GT5000_BEFORE_1990',

    'G2_ROOM_LTE5000_BEFORE_1990',
    'G2_TUNNEL_LTE5000_BEFORE_1990',

    'G3_ROOM_GT5000_1990_2009',
    'G3_TUNNEL_GT5000_1990_2009',

    'G4_ROOM_LTE5000_1990_2009',
    'G4_TUNNEL_LTE5000_1990_2009',

    'G5_ROOM_GT5000_FROM_2010',
    'G5_TUNNEL_GT5000_FROM_2010',

    'G6_ROOM_LTE5000_FROM_2010',
    'G6_TUNNEL_LTE5000_FROM_2010',

    'G7_PI_STB2252_ROOM',
    'G7_PI_STB2252_TUNNEL',

    'G8_SMIGLEKS_P_MVT_ROOM'
)
GROUP BY t.code
ORDER BY t.code;


-- ============================================================
-- ПРОВЕРКА 3:
-- qh_adjustment_rules
--
-- Ожидается:
-- Г.3 -> DIVIDE 0.8
-- Г.4 -> DIVIDE 0.8
-- Г.7 -> MULTIPLY 0.88
-- ============================================================

SELECT
    t.code AS table_code,
    ar.project_date_from,
    ar.project_date_to,
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
WHERE ar.description LIKE 'SEED_G1_G8:%'
ORDER BY
    t.code,
    ar.id,
    c.id;
