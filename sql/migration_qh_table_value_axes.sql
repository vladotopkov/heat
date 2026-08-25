BEGIN;

-- ============================================================
-- qh_table_value_axes
--
-- Конфигурация VALUE-осей для generic QH resolver.
--
-- Идея:
-- после того как:
--   1) qh_selection_rules выбрал qh_table,
--   2) qh_table_dimensions + qh_row_dimension_values выбрали qh_row,
--
-- эта таблица говорит resolver'у,
-- КАКИЕ координаты qh_values надо учитывать дальше.
--
-- axis_code совпадает с координатами qh_values:
--
--   TEMPERATURE_C
--   PLACEMENT_VARIANT
--   PIPELINE_ROLE
--   DENSITY_KIND
--   SUPPLY_TEMPERATURE_C
--   RETURN_TEMPERATURE_C
--
-- value_source:
--
--   ANSWER
--     значение берется из ответа пользователя.
--     question_code обязателен.
--
--   CALCULATED
--     значение получается расчетом программы
--     (например расчетная температура теплоносителя).
--
--   CONTEXT
--     значение задается текущей операцией resolver'а
--     (например RETURN / SUPPLY / TWO_PIPE_TOTAL).
--
--   ROW_DERIVED
--     значение уже определяется выбранной строкой.
--     Например OBJECT_KIND=PIPE приводит к строке,
--     у которой qh_values имеют LINEAR;
--     OBJECT_KIND=SURFACE -> SURFACE.
--
-- Б.8 и Б.10 сюда НЕ входят:
-- это таблицы коэффициентов, а не qh_values.
-- ============================================================


-- ============================================================
-- 1. СОЗДАЕМ ТАБЛИЦУ
-- ============================================================

CREATE TABLE IF NOT EXISTS qh_table_value_axes (
    table_id        bigint NOT NULL
                    REFERENCES qh_tables(id)
                    ON DELETE CASCADE,

    axis_code       varchar(40) NOT NULL,

    question_code   varchar(60)
                    REFERENCES questions(code),

    value_source    varchar(20) NOT NULL,

    sequence_no     integer NOT NULL,

    is_required     boolean NOT NULL DEFAULT true,

    -- NULL = ось применима ко всем pipeline_role.
    -- Иначе перечислены роли, для которых ось должна учитываться.
    applicable_roles varchar(30)[],

    description     text,

    PRIMARY KEY (
        table_id,
        axis_code
    ),

    CONSTRAINT chk_qh_table_value_axes_axis_code
    CHECK (
        axis_code IN (
            'TEMPERATURE_C',
            'PLACEMENT_VARIANT',
            'PIPELINE_ROLE',
            'DENSITY_KIND',
            'SUPPLY_TEMPERATURE_C',
            'RETURN_TEMPERATURE_C'
        )
    ),

    CONSTRAINT chk_qh_table_value_axes_value_source
    CHECK (
        value_source IN (
            'ANSWER',
            'CALCULATED',
            'CONTEXT',
            'ROW_DERIVED'
        )
    ),

    CONSTRAINT chk_qh_table_value_axes_answer_question
    CHECK (
        (
            value_source = 'ANSWER'
            AND question_code IS NOT NULL
        )
        OR
        (
            value_source <> 'ANSWER'
            AND question_code IS NULL
        )
    ),

    CONSTRAINT chk_qh_table_value_axes_applicable_roles
    CHECK (
        applicable_roles IS NULL
        OR applicable_roles <@ ARRAY[
            'SINGLE',
            'RETURN',
            'SUPPLY',
            'TWO_PIPE_TOTAL',
            'DHW_SUPPLY',
            'DHW_CIRCULATION'
        ]::varchar(30)[]
    ),

    CONSTRAINT uq_qh_table_value_axes_sequence
    UNIQUE (
        table_id,
        sequence_no
    )
);


CREATE INDEX IF NOT EXISTS idx_qh_table_value_axes_table
    ON qh_table_value_axes(table_id);

CREATE INDEX IF NOT EXISTS idx_qh_table_value_axes_question
    ON qh_table_value_axes(question_code)
    WHERE question_code IS NOT NULL;


COMMENT ON TABLE qh_table_value_axes IS
'Конфигурация координат qh_values, используемых после выбора qh_table и qh_row';

COMMENT ON COLUMN qh_table_value_axes.axis_code IS
'Колонка/логическая координата qh_values';

COMMENT ON COLUMN qh_table_value_axes.value_source IS
'Источник значения оси: ANSWER, CALCULATED, CONTEXT, ROW_DERIVED';

COMMENT ON COLUMN qh_table_value_axes.question_code IS
'Вопрос, из которого берется значение, только для value_source=ANSWER';

COMMENT ON COLUMN qh_table_value_axes.applicable_roles IS
'NULL = ось применяется ко всем pipeline_role; иначе список ролей, для которых ось учитывается';


-- ============================================================
-- 2. ПРОВЕРКА QUESTIONS, КОТОРЫЕ НУЖНЫ VALUE AXES
--
-- PLACEMENT_VARIANT в qh_values для Г.1-Г.4/Г.7
-- берется из уже заданного LAYING_METHOD:
--
--   ROOM
--   TUNNEL
--
-- Второй вопрос пользователю не нужен.
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM questions
        WHERE code = 'LAYING_METHOD'
    ) THEN
        RAISE EXCEPTION
            'Не найден question LAYING_METHOD';
    END IF;
END $$;


-- ============================================================
-- 3. ПРОВЕРКА ВСЕХ QH TABLES
-- ============================================================

DO $$
DECLARE
    missing text;
BEGIN
    SELECT string_agg(x.code, ', ' ORDER BY x.code)
    INTO missing
    FROM (
        VALUES

            -- Б
            ('Б.1'),
            ('Б.2'),
            ('Б.3'),
            ('Б.4'),
            ('Б.5'),
            ('Б.6'),
            ('Б.7'),
            ('Б.9'),
            ('Б.11'),
            ('Б.12'),
            ('Б.13'),
            ('Б.14'),
            ('Б.15'),
            ('Б.16'),
            ('Б.17'),
            ('Б.18'),
            ('Б.19'),
            ('Б.20'),
            ('Б.21'),
            ('Б.22'),

            -- В
            ('В.1'),
            ('В.2'),
            ('В.3'),
            ('В.4'),
            ('В.5'),
            ('В.6'),
            ('В.7'),

            -- Г
            ('Г.1'),
            ('Г.2'),
            ('Г.3'),
            ('Г.4'),
            ('Г.5'),
            ('Г.6'),
            ('Г.7'),
            ('Г.8')

    ) AS x(code)

    WHERE NOT EXISTS (
        SELECT 1
        FROM qh_tables t
        WHERE t.code = x.code
    );

    IF missing IS NOT NULL THEN
        RAISE EXCEPTION
            'Отсутствуют qh_tables: %',
            missing;
    END IF;
END $$;


-- ============================================================
-- 4. ОЧИЩАЕМ КОНФИГУРАЦИЮ ТОЛЬКО ДЛЯ Б-Г
-- ============================================================

DELETE FROM qh_table_value_axes
WHERE table_id IN (
    SELECT id
    FROM qh_tables
    WHERE code IN (

        -- Б
        'Б.1',
        'Б.2',
        'Б.3',
        'Б.4',
        'Б.5',
        'Б.6',
        'Б.7',
        'Б.8',
        'Б.9',
        'Б.10',
        'Б.11',
        'Б.12',
        'Б.13',
        'Б.14',
        'Б.15',
        'Б.16',
        'Б.17',
        'Б.18',
        'Б.19',
        'Б.20',
        'Б.21',
        'Б.22',

        -- В
        'В.1',
        'В.2',
        'В.3',
        'В.4',
        'В.5',
        'В.6',
        'В.7',

        -- Г
        'Г.1',
        'Г.2',
        'Г.3',
        'Г.4',
        'Г.5',
        'Г.6',
        'Г.7',
        'Г.8'
    )
);


-- ============================================================
-- 5. TEMP SEED
-- ============================================================

CREATE TEMP TABLE tmp_qh_table_value_axes_seed (
    table_code      varchar(10) NOT NULL,
    axis_code       varchar(40) NOT NULL,
    question_code   varchar(60),
    value_source    varchar(20) NOT NULL,
    sequence_no     integer NOT NULL,
    is_required     boolean NOT NULL,
    description     text,

    PRIMARY KEY (
        table_code,
        axis_code
    )
) ON COMMIT DROP;


-- ============================================================
-- 6. TYPE A
--
-- Б.1
-- В.1, В.2, В.7
--
-- В строке выбирается диаметр.
-- В qh_values остается только температурная ось.
-- ============================================================

INSERT INTO tmp_qh_table_value_axes_seed
VALUES

(
    'Б.1',
    'TEMPERATURE_C',
    NULL,
    'CALCULATED',
    10,
    true,
    'Расчетная температура теплоносителя'
),

(
    'В.1',
    'TEMPERATURE_C',
    NULL,
    'CALCULATED',
    10,
    true,
    'Расчетная температура теплоносителя'
),

(
    'В.2',
    'TEMPERATURE_C',
    NULL,
    'CALCULATED',
    10,
    true,
    'Расчетная температура теплоносителя'
),

(
    'В.7',
    'TEMPERATURE_C',
    NULL,
    'CALCULATED',
    10,
    true,
    'Расчетная температура теплоносителя'
);


-- ============================================================
-- 7. CLASSIC TWO-PIPE TABLES
--
-- Б.2-Б.7
-- Б.9
-- Б.11-Б.22
--
-- Внутри выбранной строки qh_values различаются:
--
--   pipeline_role
--   supply_temperature_c
--   return_temperature_c
--
-- pipeline_role приходит из контекста resolver:
--   RETURN
--   SUPPLY
--   TWO_PIPE_TOTAL
-- ============================================================

INSERT INTO tmp_qh_table_value_axes_seed
SELECT
    x.table_code,
    x.axis_code,
    NULL,
    x.value_source,
    x.sequence_no,
    true,
    x.description
FROM (
    VALUES

        -- Б.2
        ('Б.2','PIPELINE_ROLE','CONTEXT',10,'RETURN / SUPPLY / TWO_PIPE_TOTAL'),
        ('Б.2','SUPPLY_TEMPERATURE_C','CALCULATED',20,'Расчетная температура подающего трубопровода'),
        ('Б.2','RETURN_TEMPERATURE_C','CALCULATED',30,'Расчетная температура обратного трубопровода'),

        -- Б.3
        ('Б.3','PIPELINE_ROLE','CONTEXT',10,'RETURN / SUPPLY / TWO_PIPE_TOTAL'),
        ('Б.3','SUPPLY_TEMPERATURE_C','CALCULATED',20,'Расчетная температура подающего трубопровода'),
        ('Б.3','RETURN_TEMPERATURE_C','CALCULATED',30,'Расчетная температура обратного трубопровода'),

        -- Б.4
        ('Б.4','PIPELINE_ROLE','CONTEXT',10,'RETURN / SUPPLY / TWO_PIPE_TOTAL'),
        ('Б.4','SUPPLY_TEMPERATURE_C','CALCULATED',20,'Расчетная температура подающего трубопровода'),
        ('Б.4','RETURN_TEMPERATURE_C','CALCULATED',30,'Расчетная температура обратного трубопровода'),

        -- Б.5
        ('Б.5','PIPELINE_ROLE','CONTEXT',10,'RETURN / SUPPLY / TWO_PIPE_TOTAL'),
        ('Б.5','SUPPLY_TEMPERATURE_C','CALCULATED',20,'Расчетная температура подающего трубопровода'),
        ('Б.5','RETURN_TEMPERATURE_C','CALCULATED',30,'Расчетная температура обратного трубопровода'),

        -- Б.6
        ('Б.6','PIPELINE_ROLE','CONTEXT',10,'RETURN / SUPPLY / TWO_PIPE_TOTAL'),
        ('Б.6','SUPPLY_TEMPERATURE_C','CALCULATED',20,'Расчетная температура подающего трубопровода'),
        ('Б.6','RETURN_TEMPERATURE_C','CALCULATED',30,'Расчетная температура обратного трубопровода'),

        -- Б.7
        ('Б.7','PIPELINE_ROLE','CONTEXT',10,'RETURN / SUPPLY / TWO_PIPE_TOTAL'),
        ('Б.7','SUPPLY_TEMPERATURE_C','CALCULATED',20,'Расчетная температура подающего трубопровода'),
        ('Б.7','RETURN_TEMPERATURE_C','CALCULATED',30,'Расчетная температура обратного трубопровода'),

        -- Б.9
        ('Б.9','PIPELINE_ROLE','CONTEXT',10,'RETURN / SUPPLY / TWO_PIPE_TOTAL'),
        ('Б.9','SUPPLY_TEMPERATURE_C','CALCULATED',20,'Расчетная температура подающего трубопровода'),
        ('Б.9','RETURN_TEMPERATURE_C','CALCULATED',30,'Расчетная температура обратного трубопровода'),

        -- Б.11
        ('Б.11','PIPELINE_ROLE','CONTEXT',10,'RETURN / SUPPLY / TWO_PIPE_TOTAL'),
        ('Б.11','SUPPLY_TEMPERATURE_C','CALCULATED',20,'Расчетная температура подающего трубопровода'),
        ('Б.11','RETURN_TEMPERATURE_C','CALCULATED',30,'Расчетная температура обратного трубопровода'),

        -- Б.12
        ('Б.12','PIPELINE_ROLE','CONTEXT',10,'RETURN / SUPPLY / TWO_PIPE_TOTAL'),
        ('Б.12','SUPPLY_TEMPERATURE_C','CALCULATED',20,'Расчетная температура подающего трубопровода'),
        ('Б.12','RETURN_TEMPERATURE_C','CALCULATED',30,'Расчетная температура обратного трубопровода'),

        -- Б.13
        ('Б.13','PIPELINE_ROLE','CONTEXT',10,'RETURN / SUPPLY / TWO_PIPE_TOTAL'),
        ('Б.13','SUPPLY_TEMPERATURE_C','CALCULATED',20,'Расчетная температура подающего трубопровода'),
        ('Б.13','RETURN_TEMPERATURE_C','CALCULATED',30,'Расчетная температура обратного трубопровода'),

        -- Б.14
        ('Б.14','PIPELINE_ROLE','CONTEXT',10,'RETURN / SUPPLY / TWO_PIPE_TOTAL'),
        ('Б.14','SUPPLY_TEMPERATURE_C','CALCULATED',20,'Расчетная температура подающего трубопровода'),
        ('Б.14','RETURN_TEMPERATURE_C','CALCULATED',30,'Расчетная температура обратного трубопровода'),

        -- Б.15
        ('Б.15','PIPELINE_ROLE','CONTEXT',10,'RETURN / SUPPLY / TWO_PIPE_TOTAL'),
        ('Б.15','SUPPLY_TEMPERATURE_C','CALCULATED',20,'Расчетная/нормативная температура подающего трубопровода'),
        ('Б.15','RETURN_TEMPERATURE_C','CALCULATED',30,'Расчетная/нормативная температура обратного трубопровода'),

        -- Б.16
        ('Б.16','PIPELINE_ROLE','CONTEXT',10,'RETURN / SUPPLY / TWO_PIPE_TOTAL'),
        ('Б.16','SUPPLY_TEMPERATURE_C','CALCULATED',20,'Расчетная/нормативная температура подающего трубопровода'),
        ('Б.16','RETURN_TEMPERATURE_C','CALCULATED',30,'Расчетная/нормативная температура обратного трубопровода'),

        -- Б.17
        ('Б.17','PIPELINE_ROLE','CONTEXT',10,'RETURN / SUPPLY / TWO_PIPE_TOTAL'),
        ('Б.17','SUPPLY_TEMPERATURE_C','CALCULATED',20,'Расчетная/нормативная температура подающего трубопровода'),
        ('Б.17','RETURN_TEMPERATURE_C','CALCULATED',30,'Расчетная/нормативная температура обратного трубопровода'),

        -- Б.18
        ('Б.18','PIPELINE_ROLE','CONTEXT',10,'RETURN / SUPPLY / TWO_PIPE_TOTAL'),
        ('Б.18','SUPPLY_TEMPERATURE_C','CALCULATED',20,'Расчетная/нормативная температура подающего трубопровода'),
        ('Б.18','RETURN_TEMPERATURE_C','CALCULATED',30,'Расчетная/нормативная температура обратного трубопровода'),

        -- Б.19
        ('Б.19','PIPELINE_ROLE','CONTEXT',10,'RETURN / SUPPLY / TWO_PIPE_TOTAL'),
        ('Б.19','SUPPLY_TEMPERATURE_C','CALCULATED',20,'Расчетная/нормативная температура подающего трубопровода'),
        ('Б.19','RETURN_TEMPERATURE_C','CALCULATED',30,'Расчетная/нормативная температура обратного трубопровода'),

        -- Б.20
        ('Б.20','PIPELINE_ROLE','CONTEXT',10,'RETURN / SUPPLY / TWO_PIPE_TOTAL'),
        ('Б.20','SUPPLY_TEMPERATURE_C','CALCULATED',20,'Расчетная/нормативная температура подающего трубопровода'),
        ('Б.20','RETURN_TEMPERATURE_C','CALCULATED',30,'Расчетная/нормативная температура обратного трубопровода'),

        -- Б.21
        ('Б.21','PIPELINE_ROLE','CONTEXT',10,'RETURN / SUPPLY / TWO_PIPE_TOTAL'),
        ('Б.21','SUPPLY_TEMPERATURE_C','CALCULATED',20,'Расчетная/нормативная температура подающего трубопровода'),
        ('Б.21','RETURN_TEMPERATURE_C','CALCULATED',30,'Расчетная/нормативная температура обратного трубопровода'),

        -- Б.22
        ('Б.22','PIPELINE_ROLE','CONTEXT',10,'RETURN / SUPPLY / TWO_PIPE_TOTAL'),
        ('Б.22','SUPPLY_TEMPERATURE_C','CALCULATED',20,'Расчетная/нормативная температура подающего трубопровода'),
        ('Б.22','RETURN_TEMPERATURE_C','CALCULATED',30,'Расчетная/нормативная температура обратного трубопровода')

) AS x(
    table_code,
    axis_code,
    value_source,
    sequence_no,
    description
);


-- ============================================================
-- 8. TYPE F: В.3 - В.6
--
-- OBJECT_KIND уже выбирает конкретную строку:
--
--   PIPE    -> LINEAR
--   SURFACE -> SURFACE
--
-- Поэтому DENSITY_KIND не спрашивается второй раз,
-- а помечается ROW_DERIVED.
-- ============================================================

INSERT INTO tmp_qh_table_value_axes_seed
VALUES

('В.3','DENSITY_KIND',NULL,'ROW_DERIVED',10,true,'LINEAR/SURFACE определяется выбранной строкой OBJECT_KIND'),
('В.3','TEMPERATURE_C',NULL,'CALCULATED',20,true,'Расчетная температура теплоносителя'),

('В.4','DENSITY_KIND',NULL,'ROW_DERIVED',10,true,'LINEAR/SURFACE определяется выбранной строкой OBJECT_KIND'),
('В.4','TEMPERATURE_C',NULL,'CALCULATED',20,true,'Расчетная температура теплоносителя'),

('В.5','DENSITY_KIND',NULL,'ROW_DERIVED',10,true,'LINEAR/SURFACE определяется выбранной строкой OBJECT_KIND'),
('В.5','TEMPERATURE_C',NULL,'CALCULATED',20,true,'Расчетная температура теплоносителя'),

('В.6','DENSITY_KIND',NULL,'ROW_DERIVED',10,true,'LINEAR/SURFACE определяется выбранной строкой OBJECT_KIND'),
('В.6','TEMPERATURE_C',NULL,'CALCULATED',20,true,'Расчетная температура теплоносителя');


-- ============================================================
-- 9. Г.1 / Г.2
--
-- placement_variant реально меняет qh внутри одной строки.
--
-- Используем уже полученный ответ LAYING_METHOD:
--   ROOM
--   TUNNEL
-- ============================================================

INSERT INTO tmp_qh_table_value_axes_seed
VALUES

(
    'Г.1',
    'PLACEMENT_VARIANT',
    'LAYING_METHOD',
    'ANSWER',
    10,
    true,
    'ROOM / TUNNEL'
),
(
    'Г.1',
    'TEMPERATURE_C',
    NULL,
    'CALCULATED',
    20,
    true,
    'Расчетная температура теплоносителя'
),

(
    'Г.2',
    'PLACEMENT_VARIANT',
    'LAYING_METHOD',
    'ANSWER',
    10,
    true,
    'ROOM / TUNNEL'
),
(
    'Г.2',
    'TEMPERATURE_C',
    NULL,
    'CALCULATED',
    20,
    true,
    'Расчетная температура теплоносителя'
);


-- ============================================================
-- 10. Г.3 / Г.4
--
-- Две независимые вещи:
--
--   DENSITY_KIND
--       уже определяется выбранной строкой
--
--   PLACEMENT_VARIANT
--       ROOM / TUNNEL
--
--   TEMPERATURE_C
--       расчетная температура
-- ============================================================

INSERT INTO tmp_qh_table_value_axes_seed
VALUES

(
    'Г.3',
    'DENSITY_KIND',
    NULL,
    'ROW_DERIVED',
    10,
    true,
    'LINEAR/SURFACE определяется выбранной строкой OBJECT_KIND'
),
(
    'Г.3',
    'PLACEMENT_VARIANT',
    'LAYING_METHOD',
    'ANSWER',
    20,
    true,
    'ROOM / TUNNEL'
),
(
    'Г.3',
    'TEMPERATURE_C',
    NULL,
    'CALCULATED',
    30,
    true,
    'Расчетная температура теплоносителя'
),

(
    'Г.4',
    'DENSITY_KIND',
    NULL,
    'ROW_DERIVED',
    10,
    true,
    'LINEAR/SURFACE определяется выбранной строкой OBJECT_KIND'
),
(
    'Г.4',
    'PLACEMENT_VARIANT',
    'LAYING_METHOD',
    'ANSWER',
    20,
    true,
    'ROOM / TUNNEL'
),
(
    'Г.4',
    'TEMPERATURE_C',
    NULL,
    'CALCULATED',
    30,
    true,
    'Расчетная температура теплоносителя'
);


-- ============================================================
-- 11. Г.5 / Г.6
--
-- qh_values здесь не разделены ROOM/TUNNEL:
-- selection rule уже определил, что это приложение Г.
--
-- Внутри строки остаются:
--   DENSITY_KIND
--   TEMPERATURE_C
-- ============================================================

INSERT INTO tmp_qh_table_value_axes_seed
VALUES

(
    'Г.5',
    'DENSITY_KIND',
    NULL,
    'ROW_DERIVED',
    10,
    true,
    'LINEAR/SURFACE определяется выбранной строкой OBJECT_KIND'
),
(
    'Г.5',
    'TEMPERATURE_C',
    NULL,
    'CALCULATED',
    20,
    true,
    'Расчетная температура теплоносителя'
),

(
    'Г.6',
    'DENSITY_KIND',
    NULL,
    'ROW_DERIVED',
    10,
    true,
    'LINEAR/SURFACE определяется выбранной строкой OBJECT_KIND'
),
(
    'Г.6',
    'TEMPERATURE_C',
    NULL,
    'CALCULATED',
    20,
    true,
    'Расчетная температура теплоносителя'
);


-- ============================================================
-- 12. Г.7
-- ============================================================

INSERT INTO tmp_qh_table_value_axes_seed
VALUES

(
    'Г.7',
    'PLACEMENT_VARIANT',
    'LAYING_METHOD',
    'ANSWER',
    10,
    true,
    'ROOM / TUNNEL'
),
(
    'Г.7',
    'TEMPERATURE_C',
    NULL,
    'CALCULATED',
    20,
    true,
    'Расчетная температура теплоносителя'
);


-- ============================================================
-- 13. Г.8
--
-- Внутри строки:
--   RETURN 50
--   SUPPLY 65
--
-- TWO_PIPE_TOTAL отсутствует.
-- ============================================================

INSERT INTO tmp_qh_table_value_axes_seed
VALUES

(
    'Г.8',
    'PIPELINE_ROLE',
    NULL,
    'CONTEXT',
    10,
    true,
    'RETURN / SUPPLY'
),
(
    'Г.8',
    'SUPPLY_TEMPERATURE_C',
    NULL,
    'CALCULATED',
    20,
    true,
    'Температура подающего трубопровода'
),
(
    'Г.8',
    'RETURN_TEMPERATURE_C',
    NULL,
    'CALCULATED',
    30,
    true,
    'Температура обратного трубопровода'
);


-- ============================================================
-- 14. ЗАПИСЫВАЕМ CONFIG
-- ============================================================

INSERT INTO qh_table_value_axes (
    table_id,
    axis_code,
    question_code,
    value_source,
    sequence_no,
    is_required,
    description
)
SELECT
    t.id,
    s.axis_code,
    s.question_code,
    s.value_source,
    s.sequence_no,
    s.is_required,
    s.description
FROM tmp_qh_table_value_axes_seed s
JOIN qh_tables t
    ON t.code = s.table_code
ON CONFLICT (table_id, axis_code)
DO UPDATE SET
    question_code = EXCLUDED.question_code,
    value_source = EXCLUDED.value_source,
    sequence_no = EXCLUDED.sequence_no,
    is_required = EXCLUDED.is_required,
    description = EXCLUDED.description;


-- ============================================================
-- 15. ROLE-ЗАВИСИМЫЕ ОСИ
--
-- Это убирает необходимость в Go писать:
--   if role == SUPPLY ...
--   if role == RETURN ...
--
-- Resolver читает applicable_roles из БД.
-- ============================================================

UPDATE qh_table_value_axes
SET applicable_roles = NULL
WHERE table_id IN (
    SELECT id
    FROM qh_tables
    WHERE code IN (
        'Б.1','Б.2','Б.3','Б.4','Б.5','Б.6','Б.7','Б.9',
        'Б.11','Б.12','Б.13','Б.14','Б.15','Б.16','Б.17','Б.18',
        'Б.19','Б.20','Б.21','Б.22',
        'В.1','В.2','В.3','В.4','В.5','В.6','В.7',
        'Г.1','Г.2','Г.3','Г.4','Г.5','Г.6','Г.7','Г.8'
    )
);


-- Классические двухтрубные таблицы:
-- supply_temperature нужен для SUPPLY и TWO_PIPE_TOTAL.
UPDATE qh_table_value_axes a
SET applicable_roles = ARRAY['SUPPLY','TWO_PIPE_TOTAL']::varchar(30)[]
FROM qh_tables t
WHERE t.id = a.table_id
  AND a.axis_code = 'SUPPLY_TEMPERATURE_C'
  AND t.code IN (
      'Б.2','Б.3','Б.4','Б.5','Б.6','Б.7','Б.9',
      'Б.11','Б.12','Б.13','Б.14','Б.15','Б.16',
      'Б.17','Б.18','Б.19','Б.20','Б.21','Б.22'
  );


-- return_temperature нужен для RETURN и TWO_PIPE_TOTAL.
UPDATE qh_table_value_axes a
SET applicable_roles = ARRAY['RETURN','TWO_PIPE_TOTAL']::varchar(30)[]
FROM qh_tables t
WHERE t.id = a.table_id
  AND a.axis_code = 'RETURN_TEMPERATURE_C'
  AND t.code IN (
      'Б.2','Б.3','Б.4','Б.5','Б.6','Б.7','Б.9',
      'Б.11','Б.12','Б.13','Б.14','Б.15','Б.16',
      'Б.17','Б.18','Б.19','Б.20','Б.21','Б.22'
  );


-- Г.8 не имеет TWO_PIPE_TOTAL:
-- только RETURN 50 и SUPPLY 65.
UPDATE qh_table_value_axes a
SET applicable_roles = ARRAY['SUPPLY']::varchar(30)[]
FROM qh_tables t
WHERE t.id = a.table_id
  AND t.code = 'Г.8'
  AND a.axis_code = 'SUPPLY_TEMPERATURE_C';

UPDATE qh_table_value_axes a
SET applicable_roles = ARRAY['RETURN']::varchar(30)[]
FROM qh_tables t
WHERE t.id = a.table_id
  AND t.code = 'Г.8'
  AND a.axis_code = 'RETURN_TEMPERATURE_C';


COMMIT;


-- ============================================================
-- 16. ПРОВЕРКА ВСЕЙ КОНФИГУРАЦИИ
-- ============================================================

SELECT
    t.code AS table_code,
    a.sequence_no,
    a.axis_code,
    a.value_source,
    a.question_code,
    a.is_required,
    a.applicable_roles,
    a.description
FROM qh_table_value_axes a
JOIN qh_tables t
    ON t.id = a.table_id
WHERE t.code LIKE 'Б.%'
   OR t.code LIKE 'В.%'
   OR t.code LIKE 'Г.%'
ORDER BY
    t.appendix,
    t.code,
    a.sequence_no;


-- ============================================================
-- 17. ПРОВЕРКА: КАКИЕ QH TABLES НЕ ИМЕЮТ VALUE AXES
--
-- Ожидаемо здесь могут быть только:
--   Б.8
--   Б.10
--
-- Они не qh-таблицы, а таблицы коэффициентов.
-- ============================================================

SELECT
    t.code,
    t.title
FROM qh_tables t
LEFT JOIN qh_table_value_axes a
    ON a.table_id = t.id
WHERE (
       t.code LIKE 'Б.%'
    OR t.code LIKE 'В.%'
    OR t.code LIKE 'Г.%'
)
GROUP BY
    t.id,
    t.code,
    t.title
HAVING count(a.axis_code) = 0
ORDER BY t.code;
