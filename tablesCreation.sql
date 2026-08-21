BEGIN;

-- ============================================================
-- 1. ВОПРОСЫ
-- ============================================================

CREATE TABLE questions (
    code                varchar(60) PRIMARY KEY,

    label               text NOT NULL,
    description         text,

    phase               varchar(30) NOT NULL,

    input_type          varchar(20) NOT NULL,

    unit                varchar(30),

    selection_order     integer NOT NULL DEFAULT 100,

    option_source       varchar(30)
                        CHECK (
                            option_source IN (
                                'STATIC',
                                'QH_ROWS',
                                'TEMPERATURE_REGIMES'
                            )
                            OR option_source IS NULL
                        ),

    is_active           boolean NOT NULL DEFAULT true
);


-- ============================================================
-- 2. СТАТИЧЕСКИЕ ВАРИАНТЫ ОТВЕТОВ
-- ============================================================

CREATE TABLE question_options (
    id                  bigserial PRIMARY KEY,

    question_code       varchar(60) NOT NULL
                        REFERENCES questions(code)
                        ON DELETE CASCADE,

    value               varchar(80) NOT NULL,

    label               text NOT NULL,

    sort_order          integer NOT NULL DEFAULT 0,

    is_active           boolean NOT NULL DEFAULT true,

    UNIQUE(question_code, value)
);


-- ============================================================
-- 3. ТАБЛИЦА 5.1
-- ============================================================

CREATE TABLE temperature_regimes (
    id                              bigserial PRIMARY KEY,

    project_supply_temperature_c    numeric NOT NULL,
    project_return_temperature_c    numeric NOT NULL,

    calculated_supply_temperature_c numeric NOT NULL,

    UNIQUE (
        project_supply_temperature_c,
        project_return_temperature_c
    )
);


-- ============================================================
-- 4. НОРМАТИВНЫЕ ТАБЛИЦЫ qh 
-- ============================================================

CREATE TABLE qh_tables (
    id                  bigserial PRIMARY KEY,

    code                varchar(10) NOT NULL UNIQUE,

    appendix            varchar(2) NOT NULL,

    title               text NOT NULL,

    table_kind          varchar(30) NOT NULL DEFAULT 'QH'
                        CHECK (
                            table_kind IN (
                                'QH',
                                'COEFFICIENT'
                            )
                        ),


    is_active           boolean NOT NULL DEFAULT true
);


-- ============================================================
-- 5. ПРАВИЛА ВЫБОРА НОРМАТИВНОЙ ТАБЛИЦЫ
-- ============================================================

CREATE TABLE qh_selection_rules (
    id                  bigserial PRIMARY KEY,

    code                varchar(80) NOT NULL UNIQUE,

    qh_table_id         bigint NOT NULL
                        REFERENCES qh_tables(id),

    priority            integer NOT NULL DEFAULT 100,

    description         text,

    is_active           boolean NOT NULL DEFAULT true
);


-- ============================================================
-- 6. УСЛОВИЯ ПРАВИЛ ВЫБОРА
-- ============================================================

CREATE TABLE qh_rule_conditions (
    id                  bigserial PRIMARY KEY,

    rule_id             bigint NOT NULL
                        REFERENCES qh_selection_rules(id)
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

    value_boolean       boolean
);


-- ============================================================
-- 7. ВОЗМОЖНЫЕ ХАРАКТЕРИСТИКИ СТРОК ТАБЛИЦ
-- ============================================================

CREATE TABLE qh_dimensions (
    id                  bigserial PRIMARY KEY,

    code                varchar(60) NOT NULL UNIQUE,

    question_code       varchar(60) NOT NULL
                        REFERENCES questions(code),

    value_type          varchar(20) NOT NULL
                        CHECK (
                            value_type IN (
                                'NUMBER',
                                'TEXT'
                            )
                        ),

    unit                varchar(30),

    description         text
);


-- ============================================================
-- 8. КАКИЕ ХАРАКТЕРИСТИКИ ИСПОЛЬЗУЕТ КОНКРЕТНАЯ ТАБЛИЦА
-- ============================================================

CREATE TABLE qh_table_dimensions (
    table_id            bigint NOT NULL
                        REFERENCES qh_tables(id)
                        ON DELETE CASCADE,

    dimension_id        bigint NOT NULL
                        REFERENCES qh_dimensions(id),

    sequence_no         integer NOT NULL,

    PRIMARY KEY(table_id, dimension_id),

    UNIQUE(table_id, sequence_no)
);


-- ============================================================
-- 9. СТРОКИ НОРМАТИВНЫХ ТАБЛИЦ
-- ============================================================

CREATE TABLE qh_rows (
    id                  bigserial PRIMARY KEY,

    table_id            bigint NOT NULL
                        REFERENCES qh_tables(id)
                        ON DELETE CASCADE,

    source_row_no       integer NOT NULL,

    note                text,

    is_active           boolean NOT NULL DEFAULT true,

    UNIQUE(table_id, source_row_no)
);


-- ============================================================
-- 10. ЗНАЧЕНИЯ ХАРАКТЕРИСТИК СТРОК
-- ============================================================

CREATE TABLE qh_row_dimension_values (
    row_id              bigint NOT NULL
                        REFERENCES qh_rows(id)
                        ON DELETE CASCADE,

    dimension_id        bigint NOT NULL
                        REFERENCES qh_dimensions(id),

    value_numeric       numeric,
    value_text          text,

    PRIMARY KEY(row_id, dimension_id),

    CHECK (
        (
            value_numeric IS NOT NULL
            AND value_text IS NULL
        )
        OR
        (
            value_numeric IS NULL
            AND value_text IS NOT NULL
        )
    )
);


-- ============================================================
-- 11. НЕПОСРЕДСТВЕННО ЗНАЧЕНИЯ qh
-- ============================================================

CREATE TABLE qh_values (
    id                      bigserial PRIMARY KEY,

    row_id                  bigint NOT NULL
                            REFERENCES qh_rows(id)
                            ON DELETE CASCADE,

    pipeline_role           varchar(30) NOT NULL
                            CHECK (
                                pipeline_role IN (
                                    'RETURN',
                                    'SUPPLY',
                                    'TWO_PIPE_TOTAL',
                                    'DHW_SUPPLY',
                                    'DHW_CIRCULATION',
                                    'SINGLE'
                                )
                            ),

    placement_variant       varchar(40),

    supply_temperature_c    numeric,
    return_temperature_c    numeric,

    qh_w_per_m              numeric NOT NULL,

    source_interpolated     boolean NOT NULL DEFAULT false,

    note                    text,

    UNIQUE NULLS NOT DISTINCT (
        row_id,
        pipeline_role,
        placement_variant,
        supply_temperature_c,
        return_temperature_c
    )
);


-- ============================================================
-- 12. ПОПРАВКИ К qh
-- Например /0.8, *0.9, *0.88 и т.д.
-- ============================================================

CREATE TABLE qh_adjustment_rules (
    id                      bigserial PRIMARY KEY,

    qh_table_id             bigint
                            REFERENCES qh_tables(id)
                            ON DELETE CASCADE,

    project_date_from       date,
    project_date_to         date,

    pipe_type               varchar(60),
    laying_method           varchar(60),

    operation               varchar(30) NOT NULL
                            CHECK (
                                operation IN (
                                    'MULTIPLY',
                                    'DIVIDE',
                                    'LOOKUP_MULTIPLY'
                                )
                            ),

    factor                  numeric,

    requires_question       varchar(60)
                            REFERENCES questions(code),

    coefficient_source      varchar(30),

    description             text,

    is_active               boolean NOT NULL DEFAULT true
);


-- ============================================================
-- 13. КОЭФФИЦИЕНТЫ Кн ИЗ ТАБЛИЦ ТИПА Б.8 / Б.10
-- Пока таблица создается, но в демке НЕ заполняется.
-- nominal_bore - это условный проход трубопровода
-- ============================================================

CREATE TABLE qh_material_coefficients (
    id                      bigserial PRIMARY KEY,

    source_table_code       varchar(10) NOT NULL,

    insulation_material     varchar(60) NOT NULL,

    nominal_bore_from_mm    numeric,
    nominal_bore_to_mm      numeric,

    factor                  numeric NOT NULL
);


-- ============================================================
-- 14. СЕССИИ ОПРОСА
-- ============================================================

CREATE TABLE questionnaire_sessions (
    id                      bigserial PRIMARY KEY,

    status                  varchar(30) NOT NULL DEFAULT 'IN_PROGRESS'
                            CHECK (
                                status IN (
                                    'IN_PROGRESS',
                                    'TABLE_SELECTED',
                                    'ROW_SELECTED',
                                    'COMPLETED',
                                    'UNSUPPORTED',
                                    'AMBIGUOUS',
                                    'ERROR'
                                )
                            ),

    selected_table_rule_id  bigint
                            REFERENCES qh_selection_rules(id),

    selected_qh_table_id    bigint
                            REFERENCES qh_tables(id),

    selected_qh_row_id      bigint
                            REFERENCES qh_rows(id),

    created_at              timestamptz NOT NULL DEFAULT now(),

    updated_at              timestamptz NOT NULL DEFAULT now()
);


-- ============================================================
-- 15. ОТВЕТЫ ПОЛЬЗОВАТЕЛЯ
-- ============================================================

CREATE TABLE questionnaire_answers (
    id                  bigserial PRIMARY KEY,

    session_id          bigint NOT NULL
                        REFERENCES questionnaire_sessions(id)
                        ON DELETE CASCADE,

    question_code       varchar(60) NOT NULL
                        REFERENCES questions(code),

    value_text          text,
    value_numeric       numeric,
    value_date          date,
    value_boolean       boolean,

    created_at          timestamptz NOT NULL DEFAULT now(),

    updated_at          timestamptz NOT NULL DEFAULT now(),

    UNIQUE(session_id, question_code),

    CHECK (
        (
            value_text IS NOT NULL
            AND value_numeric IS NULL
            AND value_date IS NULL
            AND value_boolean IS NULL
        )
        OR
        (
            value_text IS NULL
            AND value_numeric IS NOT NULL
            AND value_date IS NULL
            AND value_boolean IS NULL
        )
        OR
        (
            value_text IS NULL
            AND value_numeric IS NULL
            AND value_date IS NOT NULL
            AND value_boolean IS NULL
        )
        OR
        (
            value_text IS NULL
            AND value_numeric IS NULL
            AND value_date IS NULL
            AND value_boolean IS NOT NULL
        )
    )
);


-- ============================================================
-- 16. РЕЗУЛЬТАТ ОПРЕДЕЛЕНИЯ qh
-- ============================================================

CREATE TABLE qh_results (
    id                          bigserial PRIMARY KEY,

    session_id                  bigint NOT NULL
                                REFERENCES questionnaire_sessions(id)
                                ON DELETE CASCADE,

    qh_table_id                 bigint NOT NULL
                                REFERENCES qh_tables(id),

    qh_row_id                   bigint NOT NULL
                                REFERENCES qh_rows(id),

    pipeline_role               varchar(30) NOT NULL,

    calculated_supply_temp_c    numeric,
    calculated_return_temp_c    numeric,

    base_qh_w_per_m             numeric NOT NULL,

    adjusted_qh_w_per_m         numeric NOT NULL,

    calculation_details         jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at                  timestamptz NOT NULL DEFAULT now()
);


-- ============================================================
-- ИНДЕКСЫ
-- ============================================================

CREATE INDEX idx_qh_rule_conditions_rule
    ON qh_rule_conditions(rule_id);

CREATE INDEX idx_qh_rule_conditions_question
    ON qh_rule_conditions(question_code);

CREATE INDEX idx_qh_rows_table
    ON qh_rows(table_id);

CREATE INDEX idx_qh_row_dimension_values_dimension
    ON qh_row_dimension_values(dimension_id);

CREATE INDEX idx_qh_values_row
    ON qh_values(row_id);

CREATE INDEX idx_questionnaire_answers_session
    ON questionnaire_answers(session_id);


COMMIT;