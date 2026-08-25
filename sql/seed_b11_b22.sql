BEGIN;

-- ============================================================
-- Б.11 - Б.22
-- ТОЛЬКО НОРМАТИВНЫЕ СТРОКИ / DIMENSION VALUES / qh_values
--
-- НЕ создаёт questions.
-- НЕ трогает qh_selection_rules.
-- НЕ трогает qh_adjustment_rules.
-- Предполагается, что миграции TYPE B/C/D/F уже выполнены.
-- ============================================================

-- ============================================================
-- 1. ПРОВЕРКА qh_tables
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
-- 2. ПРОВЕРКА DIMENSIONS
-- ============================================================

DO $$
DECLARE
    missing_codes text;
BEGIN
    SELECT string_agg(x.code, ', ' ORDER BY x.code)
    INTO missing_codes
    FROM (
        VALUES
            ('NOMINAL_BORE'),
            ('OUTER_DIAMETER'),
            ('CHANNEL_HEIGHT'),
            ('CHANNEL_WIDTH'),
            ('THERMAL_RESISTANCE'),
            ('BURIAL_DEPTH'),
            ('AXIS_DISTANCE'),
            ('PIPE_SIZE'),
            ('PRESSURE_PIPE_INNER_DIAMETER'),
            ('PRESSURE_PIPE_OUTER_DIAMETER'),
            ('PRESSURE_PIPE_WALL_THICKNESS'),
            ('SHELL_OUTER_DIAMETER'),
            ('SHELL_WALL_THICKNESS')
    ) AS x(code)
    WHERE NOT EXISTS (
        SELECT 1
        FROM qh_dimensions d
        WHERE d.code = x.code
    );

    IF missing_codes IS NOT NULL THEN
        RAISE EXCEPTION 'Отсутствуют qh_dimensions: %', missing_codes;
    END IF;
END $$;


-- ============================================================
-- 3. ПРОВЕРКА АКТУАЛЬНОЙ СХЕМЫ qh_values
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'qh_values'
          AND column_name = 'qh_value'
    ) THEN
        RAISE EXCEPTION 'В qh_values отсутствует qh_value. TYPE F не выполнен.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'qh_values'
          AND column_name = 'density_kind'
    ) THEN
        RAISE EXCEPTION 'В qh_values отсутствует density_kind. TYPE F не выполнен.';
    END IF;
END $$;


-- ============================================================
-- 4. ВРЕМЕННАЯ ТАБЛИЦА ИСХОДНЫХ СТРОК
-- ============================================================

CREATE TEMP TABLE tmp_qh_rows_seed (
    table_code      varchar(10) NOT NULL,
    source_row_no   integer NOT NULL,
    dimensions      jsonb NOT NULL,
    qh_values       numeric[] NOT NULL,
    interpolated    boolean[] NOT NULL,
    PRIMARY KEY (table_code, source_row_no)
) ON COMMIT DROP;


INSERT INTO tmp_qh_rows_seed (
    table_code,
    source_row_no,
    dimensions,
    qh_values,
    interpolated
)
VALUES
    ('Б.11', 1, jsonb_build_object('NOMINAL_BORE', 15), ARRAY[16,22,38,31,49], ARRAY[true,true,true,true,true]),
    ('Б.11', 2, jsonb_build_object('NOMINAL_BORE', 20), ARRAY[18,24,41,33,51], ARRAY[true,true,true,true,true]),
    ('Б.11', 3, jsonb_build_object('NOMINAL_BORE', 25), ARRAY[19,26,44,34,53], ARRAY[false,false,false,false,false]),
    ('Б.11', 4, jsonb_build_object('NOMINAL_BORE', 32), ARRAY[21,27,48,36,56], ARRAY[false,false,false,false,false]),
    ('Б.11', 5, jsonb_build_object('NOMINAL_BORE', 40), ARRAY[22,28,50,38,59], ARRAY[false,false,false,false,false]),
    ('Б.11', 6, jsonb_build_object('NOMINAL_BORE', 50), ARRAY[24,31,55,41,63], ARRAY[false,false,false,false,false]),
    ('Б.11', 7, jsonb_build_object('NOMINAL_BORE', 65), ARRAY[26,34,60,46,71], ARRAY[false,false,false,false,false]),
    ('Б.11', 8, jsonb_build_object('NOMINAL_BORE', 80), ARRAY[27,35,62,46,72], ARRAY[false,false,false,false,false]),
    ('Б.11', 9, jsonb_build_object('NOMINAL_BORE', 100), ARRAY[29,37,66,49,76], ARRAY[false,false,false,false,false]),
    ('Б.11', 10, jsonb_build_object('NOMINAL_BORE', 125), ARRAY[31,40,71,55,85], ARRAY[false,false,false,false,false]),
    ('Б.11', 11, jsonb_build_object('NOMINAL_BORE', 150), ARRAY[35,46,81,61,94], ARRAY[false,false,false,false,false]),
    ('Б.11', 12, jsonb_build_object('NOMINAL_BORE', 200), ARRAY[38,50,88,67,104], ARRAY[false,false,false,false,false]),
    ('Б.11', 13, jsonb_build_object('NOMINAL_BORE', 250), ARRAY[42,55,97,73,112], ARRAY[false,false,false,false,false]),
    ('Б.11', 14, jsonb_build_object('NOMINAL_BORE', 300), ARRAY[45,60,105,79,122], ARRAY[false,false,false,false,false]),
    ('Б.11', 15, jsonb_build_object('NOMINAL_BORE', 350), ARRAY[49,65,114,85,131], ARRAY[false,false,false,false,false]),
    ('Б.11', 16, jsonb_build_object('NOMINAL_BORE', 400), ARRAY[52,69,121,92,140], ARRAY[false,false,false,false,false]),
    ('Б.11', 17, jsonb_build_object('NOMINAL_BORE', 450), ARRAY[55,73,128,98,149], ARRAY[false,false,false,false,false]),
    ('Б.11', 18, jsonb_build_object('NOMINAL_BORE', 500), ARRAY[59,80,139,104,159], ARRAY[false,false,false,false,false]),
    ('Б.11', 19, jsonb_build_object('NOMINAL_BORE', 600), ARRAY[66,89,155,116,179], ARRAY[false,false,false,false,false]),
    ('Б.11', 20, jsonb_build_object('NOMINAL_BORE', 700), ARRAY[71,96,167,129,194], ARRAY[false,false,false,false,false]),
    ('Б.11', 21, jsonb_build_object('NOMINAL_BORE', 800), ARRAY[77,106,183,141,212], ARRAY[false,false,false,false,false]),
    ('Б.11', 22, jsonb_build_object('NOMINAL_BORE', 900), ARRAY[83,115,198,150,225], ARRAY[false,false,false,false,false]),
    ('Б.11', 23, jsonb_build_object('NOMINAL_BORE', 1000), ARRAY[89,123,212,163,243], ARRAY[false,false,false,false,false]),
    ('Б.11', 24, jsonb_build_object('NOMINAL_BORE', 1200), ARRAY[100,140,240,185,275], ARRAY[false,false,false,false,false]),
    ('Б.11', 25, jsonb_build_object('NOMINAL_BORE', 1400), ARRAY[111,158,269,209,309], ARRAY[false,false,false,false,false]),
    ('Б.12', 1, jsonb_build_object('NOMINAL_BORE', 15), ARRAY[19,26,45,35,54], ARRAY[true,true,true,true,true]),
    ('Б.12', 2, jsonb_build_object('NOMINAL_BORE', 20), ARRAY[20,27,47,36,56], ARRAY[true,true,true,true,true]),
    ('Б.12', 3, jsonb_build_object('NOMINAL_BORE', 25), ARRAY[21,28,49,37,57], ARRAY[false,false,false,false,false]),
    ('Б.12', 4, jsonb_build_object('NOMINAL_BORE', 32), ARRAY[22,29,51,39,60], ARRAY[false,false,false,false,false]),
    ('Б.12', 5, jsonb_build_object('NOMINAL_BORE', 40), ARRAY[24,30,54,42,65], ARRAY[false,false,false,false,false]),
    ('Б.12', 6, jsonb_build_object('NOMINAL_BORE', 50), ARRAY[26,34,60,46,70], ARRAY[false,false,false,false,false]),
    ('Б.12', 7, jsonb_build_object('NOMINAL_BORE', 65), ARRAY[29,38,67,51,79], ARRAY[false,false,false,false,false]),
    ('Б.12', 8, jsonb_build_object('NOMINAL_BORE', 80), ARRAY[30,39,69,52,80], ARRAY[false,false,false,false,false]),
    ('Б.12', 9, jsonb_build_object('NOMINAL_BORE', 100), ARRAY[32,42,74,56,87], ARRAY[false,false,false,false,false]),
    ('Б.12', 10, jsonb_build_object('NOMINAL_BORE', 125), ARRAY[35,46,81,61,94], ARRAY[false,false,false,false,false]),
    ('Б.12', 11, jsonb_build_object('NOMINAL_BORE', 150), ARRAY[40,52,92,69,106], ARRAY[false,false,false,false,false]),
    ('Б.12', 12, jsonb_build_object('NOMINAL_BORE', 200), ARRAY[45,58,103,76,117], ARRAY[false,false,false,false,false]),
    ('Б.12', 13, jsonb_build_object('NOMINAL_BORE', 250), ARRAY[48,63,111,84,129], ARRAY[false,false,false,false,false]),
    ('Б.12', 14, jsonb_build_object('NOMINAL_BORE', 300), ARRAY[52,69,121,92,140], ARRAY[false,false,false,false,false]),
    ('Б.12', 15, jsonb_build_object('NOMINAL_BORE', 350), ARRAY[57,76,133,100,152], ARRAY[false,false,false,false,false]),
    ('Б.12', 16, jsonb_build_object('NOMINAL_BORE', 400), ARRAY[61,82,143,106,161], ARRAY[false,false,false,false,false]),
    ('Б.12', 17, jsonb_build_object('NOMINAL_BORE', 450), ARRAY[65,88,153,114,173], ARRAY[false,false,false,false,false]),
    ('Б.12', 18, jsonb_build_object('NOMINAL_BORE', 500), ARRAY[69,93,162,123,186], ARRAY[false,false,false,false,false]),
    ('Б.12', 19, jsonb_build_object('NOMINAL_BORE', 600), ARRAY[78,106,184,140,211], ARRAY[false,false,false,false,false]),
    ('Б.12', 20, jsonb_build_object('NOMINAL_BORE', 700), ARRAY[85,118,203,153,228], ARRAY[false,false,false,false,false]),
    ('Б.12', 21, jsonb_build_object('NOMINAL_BORE', 800), ARRAY[92,127,219,170,252], ARRAY[false,false,false,false,false]),
    ('Б.12', 22, jsonb_build_object('NOMINAL_BORE', 900), ARRAY[99,138,237,183,270], ARRAY[false,false,false,false,false]),
    ('Б.12', 23, jsonb_build_object('NOMINAL_BORE', 1000), ARRAY[107,149,256,200,294], ARRAY[false,false,false,false,false]),
    ('Б.12', 24, jsonb_build_object('NOMINAL_BORE', 1200), ARRAY[121,171,292,230,335], ARRAY[false,false,false,false,false]),
    ('Б.12', 25, jsonb_build_object('NOMINAL_BORE', 1400), ARRAY[135,193,328,260,376], ARRAY[false,false,false,false,false]),
    ('Б.13', 1, jsonb_build_object('NOMINAL_BORE', 15), ARRAY[5,9,14,11,16], ARRAY[true,true,true,true,true]),
    ('Б.13', 2, jsonb_build_object('NOMINAL_BORE', 20), ARRAY[7,11,18,13,20], ARRAY[true,true,true,true,true]),
    ('Б.13', 3, jsonb_build_object('NOMINAL_BORE', 25), ARRAY[9,13,22,15,26], ARRAY[false,false,false,false,false]),
    ('Б.13', 4, jsonb_build_object('NOMINAL_BORE', 32), ARRAY[11,14,25,18,30], ARRAY[false,false,false,false,false]),
    ('Б.13', 5, jsonb_build_object('NOMINAL_BORE', 40), ARRAY[12,17,29,21,35], ARRAY[false,false,false,false,false]),
    ('Б.13', 6, jsonb_build_object('NOMINAL_BORE', 50), ARRAY[14,19,33,24,39], ARRAY[false,false,false,false,false]),
    ('Б.13', 7, jsonb_build_object('NOMINAL_BORE', 65), ARRAY[17,23,40,32,50], ARRAY[false,false,false,false,false]),
    ('Б.13', 8, jsonb_build_object('NOMINAL_BORE', 80), ARRAY[19,25,44,34,52], ARRAY[false,false,false,false,false]),
    ('Б.13', 9, jsonb_build_object('NOMINAL_BORE', 100), ARRAY[20,27,47,36,55], ARRAY[false,false,false,false,false]),
    ('Б.13', 10, jsonb_build_object('NOMINAL_BORE', 125), ARRAY[21,28,49,42,61], ARRAY[false,false,false,false,false]),
    ('Б.13', 11, jsonb_build_object('NOMINAL_BORE', 150), ARRAY[22,34,56,48,68], ARRAY[false,false,false,false,false]),
    ('Б.13', 12, jsonb_build_object('NOMINAL_BORE', 200), ARRAY[27,39,66,58,83], ARRAY[false,false,false,false,false]),
    ('Б.13', 13, jsonb_build_object('NOMINAL_BORE', 250), ARRAY[28,40,68,60,86], ARRAY[false,false,false,false,false]),
    ('Б.13', 14, jsonb_build_object('NOMINAL_BORE', 300), ARRAY[32,46,78,65,96], ARRAY[false,false,false,false,false]),
    ('Б.13', 15, jsonb_build_object('NOMINAL_BORE', 350), ARRAY[35,54,89,75,108], ARRAY[false,false,false,false,false]),
    ('Б.13', 16, jsonb_build_object('NOMINAL_BORE', 400), ARRAY[38,55,93,77,113], ARRAY[false,false,false,false,false]),
    ('Б.13', 17, jsonb_build_object('NOMINAL_BORE', 500), ARRAY[43,58,101,85,125], ARRAY[false,false,false,false,false]),
    ('Б.13', 18, jsonb_build_object('NOMINAL_BORE', 600), ARRAY[45,65,110,89,130], ARRAY[false,false,false,false,false]),
    ('Б.13', 19, jsonb_build_object('NOMINAL_BORE', 700), ARRAY[50,70,120,97,145], ARRAY[false,false,false,false,false]),
    ('Б.13', 20, jsonb_build_object('NOMINAL_BORE', 800), ARRAY[56,80,136,110,163], ARRAY[false,false,false,false,false]),
    ('Б.13', 21, jsonb_build_object('NOMINAL_BORE', 900), ARRAY[60,90,150,121,180], ARRAY[false,false,false,false,false]),
    ('Б.13', 22, jsonb_build_object('NOMINAL_BORE', 1000), ARRAY[66,100,166,132,197], ARRAY[false,false,false,false,false]),
    ('Б.14', 1, jsonb_build_object('NOMINAL_BORE', 15), ARRAY[7,12,19,12,22], ARRAY[true,true,true,true,true]),
    ('Б.14', 2, jsonb_build_object('NOMINAL_BORE', 20), ARRAY[9,13,22,14,25], ARRAY[true,true,true,true,true]),
    ('Б.14', 3, jsonb_build_object('NOMINAL_BORE', 25), ARRAY[10,14,24,16,28], ARRAY[false,false,false,false,false]),
    ('Б.14', 4, jsonb_build_object('NOMINAL_BORE', 32), ARRAY[12,15,27,19,32], ARRAY[false,false,false,false,false]),
    ('Б.14', 5, jsonb_build_object('NOMINAL_BORE', 40), ARRAY[13,18,31,22,37], ARRAY[false,false,false,false,false]),
    ('Б.14', 6, jsonb_build_object('NOMINAL_BORE', 50), ARRAY[15,20,35,25,41], ARRAY[false,false,false,false,false]),
    ('Б.14', 7, jsonb_build_object('NOMINAL_BORE', 65), ARRAY[19,26,45,35,55], ARRAY[false,false,false,false,false]),
    ('Б.14', 8, jsonb_build_object('NOMINAL_BORE', 80), ARRAY[21,28,49,38,58], ARRAY[false,false,false,false,false]),
    ('Б.14', 9, jsonb_build_object('NOMINAL_BORE', 100), ARRAY[23,31,54,41,63], ARRAY[false,false,false,false,false]),
    ('Б.14', 10, jsonb_build_object('NOMINAL_BORE', 125), ARRAY[24,32,56,48,70], ARRAY[false,false,false,false,false]),
    ('Б.14', 11, jsonb_build_object('NOMINAL_BORE', 150), ARRAY[26,40,66,55,79], ARRAY[false,false,false,false,false]),
    ('Б.14', 12, jsonb_build_object('NOMINAL_BORE', 200), ARRAY[32,46,78,67,96], ARRAY[false,false,false,false,false]),
    ('Б.14', 13, jsonb_build_object('NOMINAL_BORE', 250), ARRAY[33,48,81,70,100], ARRAY[false,false,false,false,false]),
    ('Б.14', 14, jsonb_build_object('NOMINAL_BORE', 300), ARRAY[38,55,93,77,113], ARRAY[false,false,false,false,false]),
    ('Б.14', 15, jsonb_build_object('NOMINAL_BORE', 350), ARRAY[42,64,106,89,128], ARRAY[false,false,false,false,false]),
    ('Б.14', 16, jsonb_build_object('NOMINAL_BORE', 400), ARRAY[46,66,112,92,135], ARRAY[false,false,false,false,false]),
    ('Б.14', 17, jsonb_build_object('NOMINAL_BORE', 500), ARRAY[52,70,122,102,150], ARRAY[false,false,false,false,false]),
    ('Б.14', 18, jsonb_build_object('NOMINAL_BORE', 600), ARRAY[55,79,134,108,158], ARRAY[false,false,false,false,false]),
    ('Б.14', 19, jsonb_build_object('NOMINAL_BORE', 700), ARRAY[61,85,146,118,176], ARRAY[false,false,false,false,false]),
    ('Б.14', 20, jsonb_build_object('NOMINAL_BORE', 800), ARRAY[69,98,167,135,202], ARRAY[false,false,false,false,false]),
    ('Б.14', 21, jsonb_build_object('NOMINAL_BORE', 900), ARRAY[74,112,186,150,223], ARRAY[false,false,false,false,false]),
    ('Б.14', 22, jsonb_build_object('NOMINAL_BORE', 1000), ARRAY[81,123,204,163,243], ARRAY[false,false,false,false,false]),
    ('Б.15', 1, jsonb_build_object('OUTER_DIAMETER', 32, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 5.06537), ARRAY[7.9,15.8,23.7], ARRAY[false,false,false]),
    ('Б.15', 2, jsonb_build_object('OUTER_DIAMETER', 33.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 4.84444), ARRAY[8.2,16.4,24.6], ARRAY[false,false,false]),
    ('Б.15', 3, jsonb_build_object('OUTER_DIAMETER', 38, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 5.16583), ARRAY[7.7,15.5,23.2], ARRAY[false,false,false]),
    ('Б.15', 4, jsonb_build_object('OUTER_DIAMETER', 42.3, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 4.64881), ARRAY[8.5,17.1,25.6], ARRAY[false,false,false]),
    ('Б.15', 5, jsonb_build_object('OUTER_DIAMETER', 45, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 4.35039), ARRAY[9.0,18.2,27.2], ARRAY[false,false,false]),
    ('Б.15', 6, jsonb_build_object('OUTER_DIAMETER', 48, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 4.03913), ARRAY[9.6,19.5,29.1], ARRAY[false,false,false]),
    ('Б.15', 7, jsonb_build_object('OUTER_DIAMETER', 57, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.82284), ARRAY[10.0,20.5,30.6], ARRAY[false,false,false]),
    ('Б.15', 8, jsonb_build_object('OUTER_DIAMETER', 60, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.57546), ARRAY[10.6,21.8,32.4], ARRAY[false,false,false]),
    ('Б.15', 9, jsonb_build_object('OUTER_DIAMETER', 75.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.01050), ARRAY[12.2,25.6,37.8], ARRAY[false,false,false]),
    ('Б.15', 10, jsonb_build_object('OUTER_DIAMETER', 76, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.94531), ARRAY[12.5,26.0,38.5], ARRAY[false,false,false]),
    ('Б.15', 11, jsonb_build_object('OUTER_DIAMETER', 88.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.85572), ARRAY[12.8,26.8,39.6], ARRAY[false,false,false]),
    ('Б.15', 12, jsonb_build_object('OUTER_DIAMETER', 89, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.82654), ARRAY[12.9,27.0,39.9], ARRAY[false,false,false]),
    ('Б.15', 13, jsonb_build_object('OUTER_DIAMETER', 108, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 2.98344), ARRAY[12.6,26.1,38.7], ARRAY[false,false,false]),
    ('Б.15', 14, jsonb_build_object('OUTER_DIAMETER', 114, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 2.69768), ARRAY[13.6,28.4,42.0], ARRAY[false,false,false]),
    ('Б.15', 15, jsonb_build_object('OUTER_DIAMETER', 133, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 2.51180), ARRAY[14.4,30.3,44.7], ARRAY[false,false,false]),
    ('Б.15', 16, jsonb_build_object('OUTER_DIAMETER', 140, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 2.26441), ARRAY[15.6,33.3,48.9], ARRAY[false,false,false]),
    ('Б.15', 17, jsonb_build_object('OUTER_DIAMETER', 159, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.5, 'THERMAL_RESISTANCE', 2.14669), ARRAY[16.5,35.1,51.6], ARRAY[false,false,false]),
    ('Б.15', 18, jsonb_build_object('OUTER_DIAMETER', 165, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.5, 'THERMAL_RESISTANCE', 1.98805), ARRAY[17.6,37.9,55.5], ARRAY[false,false,false]),
    ('Б.15', 19, jsonb_build_object('OUTER_DIAMETER', 219, 'CHANNEL_HEIGHT', 0.6, 'CHANNEL_WIDTH', 1.5, 'THERMAL_RESISTANCE', 1.69297), ARRAY[20.0,43.6,63.6], ARRAY[false,false,false]),
    ('Б.15', 20, jsonb_build_object('OUTER_DIAMETER', 273, 'CHANNEL_HEIGHT', 0.6, 'CHANNEL_WIDTH', 1.8, 'THERMAL_RESISTANCE', 1.77476), ARRAY[19.6,42.1,61.7], ARRAY[false,false,false]),
    ('Б.15', 21, jsonb_build_object('OUTER_DIAMETER', 325, 'CHANNEL_HEIGHT', 0.9, 'CHANNEL_WIDTH', 1.8, 'THERMAL_RESISTANCE', 1.50560), ARRAY[22.6,49.2,71.8], ARRAY[false,false,false]),
    ('Б.15', 22, jsonb_build_object('OUTER_DIAMETER', 377, 'CHANNEL_HEIGHT', 0.9, 'CHANNEL_WIDTH', 1.8, 'THERMAL_RESISTANCE', 1.29167), ARRAY[25.2,56.2,81.4], ARRAY[false,false,false]),
    ('Б.15', 23, jsonb_build_object('OUTER_DIAMETER', 426, 'CHANNEL_HEIGHT', 0.9, 'CHANNEL_WIDTH', 2.1, 'THERMAL_RESISTANCE', 1.24190), ARRAY[26.3,58.5,84.8], ARRAY[false,false,false]),
    ('Б.15', 24, jsonb_build_object('OUTER_DIAMETER', 530, 'CHANNEL_HEIGHT', 1.0, 'CHANNEL_WIDTH', 2.4, 'THERMAL_RESISTANCE', 1.32000), ARRAY[25.2,55.5,80.7], ARRAY[false,false,false]),
    ('Б.15', 25, jsonb_build_object('OUTER_DIAMETER', 630, 'CHANNEL_HEIGHT', 1.1, 'CHANNEL_WIDTH', 2.4, 'THERMAL_RESISTANCE', 1.05746), ARRAY[29.5,67.3,96.8], ARRAY[false,false,false]),
    ('Б.15', 26, jsonb_build_object('OUTER_DIAMETER', 720, 'CHANNEL_HEIGHT', 1.2, 'CHANNEL_WIDTH', 3.0, 'THERMAL_RESISTANCE', 0.97695), ARRAY[32.0,73.0,105.0], ARRAY[false,false,false]),
    ('Б.15', 27, jsonb_build_object('OUTER_DIAMETER', 820, 'CHANNEL_HEIGHT', 1.3, 'CHANNEL_WIDTH', 3.1, 'THERMAL_RESISTANCE', 0.65514), ARRAY[35.2,81.9,117.1], ARRAY[false,false,false]),
    ('Б.15', 28, jsonb_build_object('OUTER_DIAMETER', 920, 'CHANNEL_HEIGHT', 1.5, 'CHANNEL_WIDTH', 3.3, 'THERMAL_RESISTANCE', 0.75512), ARRAY[36.6,91.6,130.3], ARRAY[false,false,false]),
    ('Б.15', 29, jsonb_build_object('OUTER_DIAMETER', 1020, 'CHANNEL_HEIGHT', 1.6, 'CHANNEL_WIDTH', 3.5, 'THERMAL_RESISTANCE', 0.67624), ARRAY[41.7,100.9,142.6], ARRAY[false,false,false]),
    ('Б.15', 30, jsonb_build_object('OUTER_DIAMETER', 1220, 'CHANNEL_HEIGHT', 1.825, 'CHANNEL_WIDTH', 3.9, 'THERMAL_RESISTANCE', 0.69198), ARRAY[43.5,103.9,147.4], ARRAY[false,false,false]),
    ('Б.15', 31, jsonb_build_object('OUTER_DIAMETER', 1420, 'CHANNEL_HEIGHT', 2, 'CHANNEL_WIDTH', 4.25, 'THERMAL_RESISTANCE', 0.48504), ARRAY[52.2,134.7,186.9], ARRAY[false,false,false]),
    ('Б.16', 1, jsonb_build_object('OUTER_DIAMETER', 32, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.24), ARRAY[8.4,16.6,25.0], ARRAY[false,false,false]),
    ('Б.16', 2, jsonb_build_object('OUTER_DIAMETER', 33.5, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.24), ARRAY[8.7,17.4,26.1], ARRAY[false,false,false]),
    ('Б.16', 3, jsonb_build_object('OUTER_DIAMETER', 38, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.25), ARRAY[8.2,16.2,24.4], ARRAY[false,false,false]),
    ('Б.16', 4, jsonb_build_object('OUTER_DIAMETER', 42.3, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.26), ARRAY[9.0,17.9,26.9], ARRAY[false,false,false]),
    ('Б.16', 5, jsonb_build_object('OUTER_DIAMETER', 45, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.26), ARRAY[9.6,19.1,28.7], ARRAY[false,false,false]),
    ('Б.16', 6, jsonb_build_object('OUTER_DIAMETER', 48, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.26), ARRAY[10.3,20.6,30.9], ARRAY[false,false,false]),
    ('Б.16', 7, jsonb_build_object('OUTER_DIAMETER', 57, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.275), ARRAY[10.7,21.6,32.3], ARRAY[false,false,false]),
    ('Б.16', 8, jsonb_build_object('OUTER_DIAMETER', 60, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.275), ARRAY[11.4,23.0,34.4], ARRAY[false,false,false]),
    ('Б.16', 9, jsonb_build_object('OUTER_DIAMETER', 75.5, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.29), ARRAY[13.4,27.4,40.8], ARRAY[false,false,false]),
    ('Б.16', 10, jsonb_build_object('OUTER_DIAMETER', 76, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.29), ARRAY[13.5,27.6,41.1], ARRAY[false,false,false]),
    ('Б.16', 11, jsonb_build_object('OUTER_DIAMETER', 88.5, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.31), ARRAY[13.9,28.3,42.2], ARRAY[false,false,false]),
    ('Б.16', 12, jsonb_build_object('OUTER_DIAMETER', 89, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.31), ARRAY[14.0,28.6,42.6], ARRAY[false,false,false]),
    ('Б.16', 13, jsonb_build_object('OUTER_DIAMETER', 108, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.35), ARRAY[13.5,27.2,40.7], ARRAY[false,false,false]),
    ('Б.16', 14, jsonb_build_object('OUTER_DIAMETER', 114, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.35), ARRAY[14.6,29.7,44.3], ARRAY[false,false,false]),
    ('Б.16', 15, jsonb_build_object('OUTER_DIAMETER', 133, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.375), ARRAY[15.5,31.7,47.2], ARRAY[false,false,false]),
    ('Б.16', 16, jsonb_build_object('OUTER_DIAMETER', 140, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.375), ARRAY[17.0,35.0,52.0], ARRAY[false,false,false]),
    ('Б.16', 17, jsonb_build_object('OUTER_DIAMETER', 159, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.5), ARRAY[18.1,36.9,55.0], ARRAY[false,false,false]),
    ('Б.16', 18, jsonb_build_object('OUTER_DIAMETER', 165, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.5), ARRAY[19.5,40.0,59.5], ARRAY[false,false,false]),
    ('Б.16', 19, jsonb_build_object('OUTER_DIAMETER', 219, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.565), ARRAY[22.2,45.8,68.0], ARRAY[false,false,false]),
    ('Б.16', 20, jsonb_build_object('OUTER_DIAMETER', 273, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.65), ARRAY[21.6,44.0,65.6], ARRAY[false,false,false]),
    ('Б.16', 21, jsonb_build_object('OUTER_DIAMETER', 325, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.7), ARRAY[25.0,51.2,76.2], ARRAY[false,false,false]),
    ('Б.16', 22, jsonb_build_object('OUTER_DIAMETER', 377, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.75), ARRAY[28.5,59.0,87.5], ARRAY[false,false,false]),
    ('Б.16', 23, jsonb_build_object('OUTER_DIAMETER', 426, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.81), ARRAY[29.7,61.3,91.0], ARRAY[false,false,false]),
    ('Б.16', 24, jsonb_build_object('OUTER_DIAMETER', 530, 'BURIAL_DEPTH', 1.1, 'AXIS_DISTANCE', 0.96), ARRAY[28.5,58.2,86.7], ARRAY[false,false,false]),
    ('Б.16', 25, jsonb_build_object('OUTER_DIAMETER', 630, 'BURIAL_DEPTH', 1.1, 'AXIS_DISTANCE', 1.05), ARRAY[34.6,71.4,106.0], ARRAY[false,false,false]),
    ('Б.16', 26, jsonb_build_object('OUTER_DIAMETER', 720, 'BURIAL_DEPTH', 1.2, 'AXIS_DISTANCE', 1.25), ARRAY[37.2,76.7,113.9], ARRAY[false,false,false]),
    ('Б.16', 27, jsonb_build_object('OUTER_DIAMETER', 820, 'BURIAL_DEPTH', 1.3, 'AXIS_DISTANCE', 1.35), ARRAY[41.3,86.1,127.4], ARRAY[false,false,false]),
    ('Б.16', 28, jsonb_build_object('OUTER_DIAMETER', 920, 'BURIAL_DEPTH', 1.3, 'AXIS_DISTANCE', 1.45), ARRAY[46.1,96.7,142.8], ARRAY[false,false,false]),
    ('Б.16', 29, jsonb_build_object('OUTER_DIAMETER', 1020, 'BURIAL_DEPTH', 1.3, 'AXIS_DISTANCE', 1.55), ARRAY[51.0,107.2,158.2], ARRAY[false,false,false]),
    ('Б.16', 30, jsonb_build_object('OUTER_DIAMETER', 1220, 'BURIAL_DEPTH', 1.5, 'AXIS_DISTANCE', 1.775), ARRAY[51.6,108.9,160.5], ARRAY[false,false,false]),
    ('Б.16', 31, jsonb_build_object('OUTER_DIAMETER', 1420, 'BURIAL_DEPTH', 1.5, 'AXIS_DISTANCE', 1.95), ARRAY[66.5,143.7,210.2], ARRAY[false,false,false]),
    ('Б.17', 1, jsonb_build_object('PIPE_SIZE', '25/63', 'PRESSURE_PIPE_OUTER_DIAMETER', 25, 'PRESSURE_PIPE_WALL_THICKNESS', 2.3, 'SHELL_OUTER_DIAMETER', 63, 'SHELL_WALL_THICKNESS', 2, 'CHANNEL_HEIGHT', 0.3, 'CHANNEL_WIDTH', 0.6, 'THERMAL_RESISTANCE', 4.68203), ARRAY[8.4,11.7,20.1], ARRAY[false,false,false]),
    ('Б.17', 2, jsonb_build_object('PIPE_SIZE', '25/63', 'PRESSURE_PIPE_OUTER_DIAMETER', 25, 'PRESSURE_PIPE_WALL_THICKNESS', 3.5, 'SHELL_OUTER_DIAMETER', 63, 'SHELL_WALL_THICKNESS', 2, 'CHANNEL_HEIGHT', 0.3, 'CHANNEL_WIDTH', 0.6, 'THERMAL_RESISTANCE', 4.73445), ARRAY[8.3,11.6,19.9], ARRAY[false,false,false]),
    ('Б.17', 3, jsonb_build_object('PIPE_SIZE', '25/63', 'PRESSURE_PIPE_OUTER_DIAMETER', 25, 'PRESSURE_PIPE_WALL_THICKNESS', 2.3, 'SHELL_OUTER_DIAMETER', 63, 'SHELL_WALL_THICKNESS', 2, 'CHANNEL_HEIGHT', 0.3, 'CHANNEL_WIDTH', 0.6, 'THERMAL_RESISTANCE', 4.70592), ARRAY[8.4,11.5,19.9], ARRAY[false,false,false]),
    ('Б.17', 4, jsonb_build_object('PIPE_SIZE', '32/63', 'PRESSURE_PIPE_OUTER_DIAMETER', 32, 'PRESSURE_PIPE_WALL_THICKNESS', 2.9, 'SHELL_OUTER_DIAMETER', 63, 'SHELL_WALL_THICKNESS', 2, 'CHANNEL_HEIGHT', 0.3, 'CHANNEL_WIDTH', 0.6, 'THERMAL_RESISTANCE', 3.49304), ARRAY[10.9,15.2,26.1], ARRAY[false,false,false]),
    ('Б.17', 5, jsonb_build_object('PIPE_SIZE', '32/63', 'PRESSURE_PIPE_OUTER_DIAMETER', 32, 'PRESSURE_PIPE_WALL_THICKNESS', 4.4, 'SHELL_OUTER_DIAMETER', 63, 'SHELL_WALL_THICKNESS', 2, 'CHANNEL_HEIGHT', 0.3, 'CHANNEL_WIDTH', 0.6, 'THERMAL_RESISTANCE', 3.54098), ARRAY[10.8,15.0,25.8], ARRAY[false,false,false]),
    ('Б.17', 6, jsonb_build_object('PIPE_SIZE', '32/63', 'PRESSURE_PIPE_OUTER_DIAMETER', 32, 'PRESSURE_PIPE_WALL_THICKNESS', 2.9, 'SHELL_OUTER_DIAMETER', 63, 'SHELL_WALL_THICKNESS', 2, 'CHANNEL_HEIGHT', 0.3, 'CHANNEL_WIDTH', 0.6, 'THERMAL_RESISTANCE', 3.56393), ARRAY[10.7,14.9,25.6], ARRAY[false,false,false]),
    ('Б.17', 7, jsonb_build_object('PIPE_SIZE', '32/90', 'PRESSURE_PIPE_OUTER_DIAMETER', 32, 'PRESSURE_PIPE_WALL_THICKNESS', 2.9, 'SHELL_OUTER_DIAMETER', 90, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 5.11727), ARRAY[8.0,10.9,18.9], ARRAY[false,false,false]),
    ('Б.17', 8, jsonb_build_object('PIPE_SIZE', '32/90', 'PRESSURE_PIPE_OUTER_DIAMETER', 32, 'PRESSURE_PIPE_WALL_THICKNESS', 4.4, 'SHELL_OUTER_DIAMETER', 94, 'SHELL_WALL_THICKNESS', 2.2, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 5.40649), ARRAY[7.6,10.4,18.0], ARRAY[false,false,false]),
    ('Б.17', 9, jsonb_build_object('PIPE_SIZE', '40/75', 'PRESSURE_PIPE_OUTER_DIAMETER', 40, 'PRESSURE_PIPE_WALL_THICKNESS', 2.8, 'SHELL_OUTER_DIAMETER', 75, 'SHELL_WALL_THICKNESS', 2, 'CHANNEL_HEIGHT', 0.3, 'CHANNEL_WIDTH', 0.6, 'THERMAL_RESISTANCE', 3.21294), ARRAY[11.6,16.4,28.0], ARRAY[false,false,false]),
    ('Б.17', 10, jsonb_build_object('PIPE_SIZE', '40/75', 'PRESSURE_PIPE_OUTER_DIAMETER', 40, 'PRESSURE_PIPE_WALL_THICKNESS', 3.7, 'SHELL_OUTER_DIAMETER', 75, 'SHELL_WALL_THICKNESS', 2, 'CHANNEL_HEIGHT', 0.3, 'CHANNEL_WIDTH', 0.6, 'THERMAL_RESISTANCE', 3.22635), ARRAY[11.6,16.3,27.9], ARRAY[false,false,false]),
    ('Б.17', 11, jsonb_build_object('PIPE_SIZE', '40/75', 'PRESSURE_PIPE_OUTER_DIAMETER', 40, 'PRESSURE_PIPE_WALL_THICKNESS', 5.5, 'SHELL_OUTER_DIAMETER', 75, 'SHELL_WALL_THICKNESS', 2, 'CHANNEL_HEIGHT', 0.3, 'CHANNEL_WIDTH', 0.6, 'THERMAL_RESISTANCE', 3.32430), ARRAY[11.5,16.0,27.5], ARRAY[false,false,false]),
    ('Б.17', 12, jsonb_build_object('PIPE_SIZE', '40/75', 'PRESSURE_PIPE_OUTER_DIAMETER', 40, 'PRESSURE_PIPE_WALL_THICKNESS', 2.8, 'SHELL_OUTER_DIAMETER', 79, 'SHELL_WALL_THICKNESS', 2, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.45771), ARRAY[11.3,15.7,27.0], ARRAY[false,false,false]),
    ('Б.17', 13, jsonb_build_object('PIPE_SIZE', '40/75', 'PRESSURE_PIPE_OUTER_DIAMETER', 40, 'PRESSURE_PIPE_WALL_THICKNESS', 4, 'SHELL_OUTER_DIAMETER', 79, 'SHELL_WALL_THICKNESS', 2, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.48900), ARRAY[11.3,15.5,26.8], ARRAY[false,false,false]),
    ('Б.17', 14, jsonb_build_object('PIPE_SIZE', '32/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 40, 'PRESSURE_PIPE_WALL_THICKNESS', 5.5, 'SHELL_OUTER_DIAMETER', 110, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 5.05241), ARRAY[8.0,11.1,19.1], ARRAY[false,false,false]),
    ('Б.17', 15, jsonb_build_object('PIPE_SIZE', '40/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 40, 'PRESSURE_PIPE_WALL_THICKNESS', 3.7, 'SHELL_OUTER_DIAMETER', 110, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 5.00340), ARRAY[8.1,11.2,19.3], ARRAY[false,false,false]),
    ('Б.17', 16, jsonb_build_object('PIPE_SIZE', '32/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 40, 'PRESSURE_PIPE_WALL_THICKNESS', 5.5, 'SHELL_OUTER_DIAMETER', 115, 'SHELL_WALL_THICKNESS', 2.4, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 5.27345), ARRAY[7.8,10.6,18.4], ARRAY[false,false,false]),
    ('Б.17', 17, jsonb_build_object('PIPE_SIZE', '50/90', 'PRESSURE_PIPE_OUTER_DIAMETER', 47.6, 'PRESSURE_PIPE_WALL_THICKNESS', 3.6, 'SHELL_OUTER_DIAMETER', 94, 'SHELL_WALL_THICKNESS', 2.2, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.42635), ARRAY[11.4,15.8,27.2], ARRAY[false,false,false]),
    ('Б.17', 18, jsonb_build_object('PIPE_SIZE', '50/100', 'PRESSURE_PIPE_OUTER_DIAMETER', 47.6, 'PRESSURE_PIPE_WALL_THICKNESS', 3.6, 'SHELL_OUTER_DIAMETER', 103, 'SHELL_WALL_THICKNESS', 2.2, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.86012), ARRAY[10.3,14.2,24.5], ARRAY[false,false,false]),
    ('Б.17', 19, jsonb_build_object('PIPE_SIZE', '50/90', 'PRESSURE_PIPE_OUTER_DIAMETER', 47.7, 'PRESSURE_PIPE_WALL_THICKNESS', 3.6, 'SHELL_OUTER_DIAMETER', 90, 'SHELL_WALL_THICKNESS', 2.2, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.21647), ARRAY[12.1,16.8,28.9], ARRAY[false,false,false]),
    ('Б.17', 20, jsonb_build_object('PIPE_SIZE', '50/90', 'PRESSURE_PIPE_OUTER_DIAMETER', 47.7, 'PRESSURE_PIPE_WALL_THICKNESS', 3.6, 'SHELL_OUTER_DIAMETER', 94.4, 'SHELL_WALL_THICKNESS', 2.2, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.43525), ARRAY[11.4,15.8,27.2], ARRAY[false,false,false]),
    ('Б.17', 21, jsonb_build_object('PIPE_SIZE', '50/100', 'PRESSURE_PIPE_OUTER_DIAMETER', 47.7, 'PRESSURE_PIPE_WALL_THICKNESS', 3.6, 'SHELL_OUTER_DIAMETER', 100, 'SHELL_WALL_THICKNESS', 2.2, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.70923), ARRAY[10.7,14.7,25.4], ARRAY[false,false,false]),
    ('Б.17', 22, jsonb_build_object('PIPE_SIZE', '50/90', 'PRESSURE_PIPE_OUTER_DIAMETER', 50, 'PRESSURE_PIPE_WALL_THICKNESS', 4.6, 'SHELL_OUTER_DIAMETER', 90, 'SHELL_WALL_THICKNESS', 2.2, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.99799), ARRAY[12.8,17.8,30.6], ARRAY[false,false,false]),
    ('Б.17', 23, jsonb_build_object('PIPE_SIZE', '50/90', 'PRESSURE_PIPE_OUTER_DIAMETER', 50, 'PRESSURE_PIPE_WALL_THICKNESS', 6.9, 'SHELL_OUTER_DIAMETER', 90, 'SHELL_WALL_THICKNESS', 2.2, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.04809), ARRAY[12.6,17.6,30.2], ARRAY[false,false,false]),
    ('Б.17', 24, jsonb_build_object('PIPE_SIZE', '50/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 50, 'PRESSURE_PIPE_WALL_THICKNESS', 4.6, 'SHELL_OUTER_DIAMETER', 110, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.92669), ARRAY[10.1,14.0,24.1], ARRAY[false,false,false]),
    ('Б.17', 25, jsonb_build_object('PIPE_SIZE', '40/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 50, 'PRESSURE_PIPE_WALL_THICKNESS', 6.9, 'SHELL_OUTER_DIAMETER', 110, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.97679), ARRAY[10.0,13.8,23.8], ARRAY[false,false,false]),
    ('Б.17', 26, jsonb_build_object('PIPE_SIZE', '40/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 50, 'PRESSURE_PIPE_WALL_THICKNESS', 6.9, 'SHELL_OUTER_DIAMETER', 115, 'SHELL_WALL_THICKNESS', 2.4, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 4.19784), ARRAY[9.6,13.1,22.7], ARRAY[false,false,false]),
    ('Б.17', 27, jsonb_build_object('PIPE_SIZE', '63/100', 'PRESSURE_PIPE_OUTER_DIAMETER', 58.5, 'PRESSURE_PIPE_WALL_THICKNESS', 4, 'SHELL_OUTER_DIAMETER', 100, 'SHELL_WALL_THICKNESS', 2.2, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.71797), ARRAY[13.9,19.4,33.3], ARRAY[false,false,false]),
    ('Б.17', 28, jsonb_build_object('PIPE_SIZE', '63/100', 'PRESSURE_PIPE_OUTER_DIAMETER', 58.5, 'PRESSURE_PIPE_WALL_THICKNESS', 4, 'SHELL_OUTER_DIAMETER', 100, 'SHELL_WALL_THICKNESS', 2.2, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.95957), ARRAY[13.3,18.6,31.9], ARRAY[false,false,false]),
    ('Б.17', 29, jsonb_build_object('PIPE_SIZE', '63/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 58.5, 'PRESSURE_PIPE_WALL_THICKNESS', 4, 'SHELL_OUTER_DIAMETER', 110, 'SHELL_WALL_THICKNESS', 2.4, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.19446), ARRAY[12.3,17.0,29.3], ARRAY[false,false,false]),
    ('Б.17', 30, jsonb_build_object('PIPE_SIZE', '63/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 58.5, 'PRESSURE_PIPE_WALL_THICKNESS', 4, 'SHELL_OUTER_DIAMETER', 115, 'SHELL_WALL_THICKNESS', 2.4, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.36695), ARRAY[11.5,16.1,27.6], ARRAY[false,false,false]),
    ('Б.17', 31, jsonb_build_object('PIPE_SIZE', '63/100', 'PRESSURE_PIPE_OUTER_DIAMETER', 63, 'PRESSURE_PIPE_WALL_THICKNESS', 5.8, 'SHELL_OUTER_DIAMETER', 100, 'SHELL_WALL_THICKNESS', 2.2, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.38419), ARRAY[15.5,21.8,37.3], ARRAY[false,false,false]),
    ('Б.17', 32, jsonb_build_object('PIPE_SIZE', '63/100', 'PRESSURE_PIPE_OUTER_DIAMETER', 63, 'PRESSURE_PIPE_WALL_THICKNESS', 8.6, 'SHELL_OUTER_DIAMETER', 100, 'SHELL_WALL_THICKNESS', 2.2, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.42621), ARRAY[15.3,21.4,36.7], ARRAY[false,false,false]),
    ('Б.17', 33, jsonb_build_object('PIPE_SIZE', '63/125', 'PRESSURE_PIPE_OUTER_DIAMETER', 63, 'PRESSURE_PIPE_WALL_THICKNESS', 5.8, 'SHELL_OUTER_DIAMETER', 125, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.42446), ARRAY[11.4,15.8,27.2], ARRAY[false,false,false]),
    ('Б.17', 34, jsonb_build_object('PIPE_SIZE', '50/125', 'PRESSURE_PIPE_OUTER_DIAMETER', 63, 'PRESSURE_PIPE_WALL_THICKNESS', 8.6, 'SHELL_OUTER_DIAMETER', 125, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.47277), ARRAY[11.3,15.6,26.9], ARRAY[false,false,false]),
    ('Б.17', 35, jsonb_build_object('PIPE_SIZE', '50/125', 'PRESSURE_PIPE_OUTER_DIAMETER', 63, 'PRESSURE_PIPE_WALL_THICKNESS', 8.6, 'SHELL_OUTER_DIAMETER', 130, 'SHELL_WALL_THICKNESS', 2.6, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.65584), ARRAY[10.8,14.9,25.7], ARRAY[false,false,false]),
    ('Б.17', 36, jsonb_build_object('PIPE_SIZE', '75/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 69.5, 'PRESSURE_PIPE_WALL_THICKNESS', 4.6, 'SHELL_OUTER_DIAMETER', 110, 'SHELL_WALL_THICKNESS', 2.4, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.32136), ARRAY[15.8,22.3,38.1], ARRAY[false,false,false]),
    ('Б.17', 37, jsonb_build_object('PIPE_SIZE', '75/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 69.5, 'PRESSURE_PIPE_WALL_THICKNESS', 4.6, 'SHELL_OUTER_DIAMETER', 114.8, 'SHELL_WALL_THICKNESS', 2.4, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.52553), ARRAY[14.8,20.7,35.5], ARRAY[false,false,false]),
    ('Б.17', 38, jsonb_build_object('PIPE_SIZE', '75/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 69.5, 'PRESSURE_PIPE_WALL_THICKNESS', 4.6, 'SHELL_OUTER_DIAMETER', 115, 'SHELL_WALL_THICKNESS', 2.4, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.53385), ARRAY[14.7,20.7,35.4], ARRAY[false,false,false]),
    ('Б.17', 39, jsonb_build_object('PIPE_SIZE', '75/125', 'PRESSURE_PIPE_OUTER_DIAMETER', 69.5, 'PRESSURE_PIPE_WALL_THICKNESS', 4.6, 'SHELL_OUTER_DIAMETER', 125, 'SHELL_WALL_THICKNESS', 2.6, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.91674), ARRAY[13.2,18.2,31.4], ARRAY[false,false,false]),
    ('Б.17', 40, jsonb_build_object('PIPE_SIZE', '75/125', 'PRESSURE_PIPE_OUTER_DIAMETER', 69.5, 'PRESSURE_PIPE_WALL_THICKNESS', 4.6, 'SHELL_OUTER_DIAMETER', 130, 'SHELL_WALL_THICKNESS', 2.6, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.10589), ARRAY[12.4,17.3,29.7], ARRAY[false,false,false]),
    ('Б.17', 41, jsonb_build_object('PIPE_SIZE', '75/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 75, 'PRESSURE_PIPE_WALL_THICKNESS', 6.8, 'SHELL_OUTER_DIAMETER', 110, 'SHELL_WALL_THICKNESS', 2.4, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 1.97037), ARRAY[18.0,25.6,43.6], ARRAY[false,false,false]),
    ('Б.17', 42, jsonb_build_object('PIPE_SIZE', '75/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 75, 'PRESSURE_PIPE_WALL_THICKNESS', 10.3, 'SHELL_OUTER_DIAMETER', 110, 'SHELL_WALL_THICKNESS', 2.4, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.02907), ARRAY[17.7,25.0,42.7], ARRAY[false,false,false]),
    ('Б.17', 43, jsonb_build_object('PIPE_SIZE', '75/140', 'PRESSURE_PIPE_OUTER_DIAMETER', 75, 'PRESSURE_PIPE_WALL_THICKNESS', 6.8, 'SHELL_OUTER_DIAMETER', 140, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.12532), ARRAY[12.3,17.2,29.5], ARRAY[false,false,false]),
    ('Б.17', 44, jsonb_build_object('PIPE_SIZE', '63/140', 'PRESSURE_PIPE_OUTER_DIAMETER', 75, 'PRESSURE_PIPE_WALL_THICKNESS', 10.3, 'SHELL_OUTER_DIAMETER', 140, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.17802), ARRAY[12.2,16.9,29.1], ARRAY[false,false,false]),
    ('Б.17', 45, jsonb_build_object('PIPE_SIZE', '63/145', 'PRESSURE_PIPE_OUTER_DIAMETER', 75, 'PRESSURE_PIPE_WALL_THICKNESS', 10.3, 'SHELL_OUTER_DIAMETER', 150, 'SHELL_WALL_THICKNESS', 2.7, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.49446), ARRAY[11.2,15.5,26.7], ARRAY[false,false,false]),
    ('Б.17', 46, jsonb_build_object('PIPE_SIZE', '90/125', 'PRESSURE_PIPE_OUTER_DIAMETER', 84, 'PRESSURE_PIPE_WALL_THICKNESS', 6, 'SHELL_OUTER_DIAMETER', 125, 'SHELL_WALL_THICKNESS', 2.6, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.00685), ARRAY[17.7,25.3,43.0], ARRAY[false,false,false]),
    ('Б.17', 47, jsonb_build_object('PIPE_SIZE', '90/125', 'PRESSURE_PIPE_OUTER_DIAMETER', 84, 'PRESSURE_PIPE_WALL_THICKNESS', 6, 'SHELL_OUTER_DIAMETER', 128.7, 'SHELL_WALL_THICKNESS', 2.6, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.18601), ARRAY[16.6,23.5,40.1], ARRAY[false,false,false]),
    ('Б.17', 48, jsonb_build_object('PIPE_SIZE', '90/125', 'PRESSURE_PIPE_OUTER_DIAMETER', 84, 'PRESSURE_PIPE_WALL_THICKNESS', 6, 'SHELL_OUTER_DIAMETER', 130, 'SHELL_WALL_THICKNESS', 2.6, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.19710), ARRAY[16.6,23.4,40.0], ARRAY[false,false,false]),
    ('Б.17', 49, jsonb_build_object('PIPE_SIZE', '90/145', 'PRESSURE_PIPE_OUTER_DIAMETER', 84, 'PRESSURE_PIPE_WALL_THICKNESS', 6, 'SHELL_OUTER_DIAMETER', 145, 'SHELL_WALL_THICKNESS', 2.7, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.71494), ARRAY[13.9,19.5,33.4], ARRAY[false,false,false]),
    ('Б.17', 50, jsonb_build_object('PIPE_SIZE', '90/145', 'PRESSURE_PIPE_OUTER_DIAMETER', 84, 'PRESSURE_PIPE_WALL_THICKNESS', 6, 'SHELL_OUTER_DIAMETER', 150, 'SHELL_WALL_THICKNESS', 2.7, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.67796), ARRAY[13.2,18.5,31.7], ARRAY[false,false,false]),
    ('Б.17', 51, jsonb_build_object('PIPE_SIZE', '90/125', 'PRESSURE_PIPE_OUTER_DIAMETER', 90, 'PRESSURE_PIPE_WALL_THICKNESS', 8.2, 'SHELL_OUTER_DIAMETER', 125, 'SHELL_WALL_THICKNESS', 2.6, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 1.69580), ARRAY[20.3,29.1,49.4], ARRAY[false,false,false]),
    ('Б.17', 52, jsonb_build_object('PIPE_SIZE', '90/125', 'PRESSURE_PIPE_OUTER_DIAMETER', 90, 'PRESSURE_PIPE_WALL_THICKNESS', 12.3, 'SHELL_OUTER_DIAMETER', 125, 'SHELL_WALL_THICKNESS', 2.6, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 1.74527), ARRAY[19.8,28.4,48.2], ARRAY[false,false,false]),
    ('Б.17', 53, jsonb_build_object('PIPE_SIZE', '90/140', 'PRESSURE_PIPE_OUTER_DIAMETER', 90, 'PRESSURE_PIPE_WALL_THICKNESS', 8.2, 'SHELL_OUTER_DIAMETER', 140, 'SHELL_WALL_THICKNESS', 2.7, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.23315), ARRAY[16.3,23.1,39.4], ARRAY[false,false,false]),
    ('Б.17', 54, jsonb_build_object('PIPE_SIZE', '90/160', 'PRESSURE_PIPE_OUTER_DIAMETER', 90, 'PRESSURE_PIPE_WALL_THICKNESS', 8.2, 'SHELL_OUTER_DIAMETER', 160, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.89685), ARRAY[13.2,18.4,31.6], ARRAY[false,false,false]),
    ('Б.17', 55, jsonb_build_object('PIPE_SIZE', '75/160', 'PRESSURE_PIPE_OUTER_DIAMETER', 90, 'PRESSURE_PIPE_WALL_THICKNESS', 12.3, 'SHELL_OUTER_DIAMETER', 160, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.93602), ARRAY[13.1,18.1,31.2], ARRAY[false,false,false]),
    ('Б.17', 56, jsonb_build_object('PIPE_SIZE', '75/160', 'PRESSURE_PIPE_OUTER_DIAMETER', 90, 'PRESSURE_PIPE_WALL_THICKNESS', 12.3, 'SHELL_OUTER_DIAMETER', 165, 'SHELL_WALL_THICKNESS', 2.9, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.03218), ARRAY[12.7,17.6,30.3], ARRAY[false,false,false]),
    ('Б.17', 57, jsonb_build_object('PIPE_SIZE', '110/145', 'PRESSURE_PIPE_OUTER_DIAMETER', 101, 'PRESSURE_PIPE_WALL_THICKNESS', 6.5, 'SHELL_OUTER_DIAMETER', 145, 'SHELL_WALL_THICKNESS', 2.7, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 1.81621), ARRAY[19.2,27.5,46.7], ARRAY[false,false,false]),
    ('Б.17', 58, jsonb_build_object('PIPE_SIZE', '110/145', 'PRESSURE_PIPE_OUTER_DIAMETER', 101, 'PRESSURE_PIPE_WALL_THICKNESS', 6.5, 'SHELL_OUTER_DIAMETER', 150, 'SHELL_WALL_THICKNESS', 2.7, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 1.98223), ARRAY[18.0,25.5,43.5], ARRAY[false,false,false]),
    ('Б.17', 59, jsonb_build_object('PIPE_SIZE', '110/145', 'PRESSURE_PIPE_OUTER_DIAMETER', 101, 'PRESSURE_PIPE_WALL_THICKNESS', 6.5, 'SHELL_OUTER_DIAMETER', 150.4, 'SHELL_WALL_THICKNESS', 2.7, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 1.99503), ARRAY[17.9,25.4,43.3], ARRAY[false,false,false]),
    ('Б.17', 60, jsonb_build_object('PIPE_SIZE', '110/160', 'PRESSURE_PIPE_OUTER_DIAMETER', 101, 'PRESSURE_PIPE_WALL_THICKNESS', 6.5, 'SHELL_OUTER_DIAMETER', 160, 'SHELL_WALL_THICKNESS', 2.7, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.29259), ARRAY[16.1,22.5,38.6], ARRAY[false,false,false]),
    ('Б.17', 61, jsonb_build_object('PIPE_SIZE', '110/160', 'PRESSURE_PIPE_OUTER_DIAMETER', 101, 'PRESSURE_PIPE_WALL_THICKNESS', 6.5, 'SHELL_OUTER_DIAMETER', 165, 'SHELL_WALL_THICKNESS', 2.9, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.40003), ARRAY[15.4,21.7,37.1], ARRAY[false,false,false]),
    ('Б.17', 62, jsonb_build_object('PIPE_SIZE', '110/145', 'PRESSURE_PIPE_OUTER_DIAMETER', 110, 'PRESSURE_PIPE_WALL_THICKNESS', 10, 'SHELL_OUTER_DIAMETER', 145, 'SHELL_WALL_THICKNESS', 2.7, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 1.43387), ARRAY[22.9,33.4,56.3], ARRAY[false,false,false]),
    ('Б.17', 63, jsonb_build_object('PIPE_SIZE', '110/145', 'PRESSURE_PIPE_OUTER_DIAMETER', 110, 'PRESSURE_PIPE_WALL_THICKNESS', 15.1, 'SHELL_OUTER_DIAMETER', 145, 'SHELL_WALL_THICKNESS', 2.7, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 1.49424), ARRAY[22.3,32.5,54.8], ARRAY[false,false,false]),
    ('Б.17', 64, jsonb_build_object('PIPE_SIZE', '110/160', 'PRESSURE_PIPE_OUTER_DIAMETER', 110, 'PRESSURE_PIPE_WALL_THICKNESS', 10, 'SHELL_OUTER_DIAMETER', 160, 'SHELL_WALL_THICKNESS', 2.7, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 1.90725), ARRAY[18.5,26.4,44.9], ARRAY[false,false,false]),
    ('Б.17', 65, jsonb_build_object('PIPE_SIZE', '110/180', 'PRESSURE_PIPE_OUTER_DIAMETER', 110, 'PRESSURE_PIPE_WALL_THICKNESS', 10, 'SHELL_OUTER_DIAMETER', 180, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.45727), ARRAY[15.2,21.2,36.4], ARRAY[false,false,false]),
    ('Б.17', 66, jsonb_build_object('PIPE_SIZE', '90/180', 'PRESSURE_PIPE_OUTER_DIAMETER', 110, 'PRESSURE_PIPE_WALL_THICKNESS', 15.1, 'SHELL_OUTER_DIAMETER', 180, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.50765), ARRAY[14.8,20.9,35.7], ARRAY[false,false,false]),
    ('Б.17', 67, jsonb_build_object('PIPE_SIZE', '90/180', 'PRESSURE_PIPE_OUTER_DIAMETER', 110, 'PRESSURE_PIPE_WALL_THICKNESS', 15.1, 'SHELL_OUTER_DIAMETER', 185, 'SHELL_WALL_THICKNESS', 3, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.61480), ARRAY[14.4,20.1,34.5], ARRAY[false,false,false]),
    ('Б.17', 68, jsonb_build_object('PIPE_SIZE', '125/160', 'PRESSURE_PIPE_OUTER_DIAMETER', 116, 'PRESSURE_PIPE_WALL_THICKNESS', 6.8, 'SHELL_OUTER_DIAMETER', 160, 'SHELL_WALL_THICKNESS', 2.7, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 1.61929), ARRAY[21.4,30.7,52.1], ARRAY[false,false,false]),
    ('Б.17', 69, jsonb_build_object('PIPE_SIZE', '125/160', 'PRESSURE_PIPE_OUTER_DIAMETER', 116, 'PRESSURE_PIPE_WALL_THICKNESS', 6.8, 'SHELL_OUTER_DIAMETER', 165, 'SHELL_WALL_THICKNESS', 2.9, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 1.72673), ARRAY[20.4,29.1,49.5], ARRAY[false,false,false]),
    ('Б.17', 70, jsonb_build_object('PIPE_SIZE', '125/180', 'PRESSURE_PIPE_OUTER_DIAMETER', 116, 'PRESSURE_PIPE_WALL_THICKNESS', 6.8, 'SHELL_OUTER_DIAMETER', 180, 'SHELL_WALL_THICKNESS', 3, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 2.14350), ARRAY[17.1,24.2,41.3], ARRAY[false,false,false]),
    ('Б.17', 71, jsonb_build_object('PIPE_SIZE', '125/180', 'PRESSURE_PIPE_OUTER_DIAMETER', 116, 'PRESSURE_PIPE_WALL_THICKNESS', 6.8, 'SHELL_OUTER_DIAMETER', 185, 'SHELL_WALL_THICKNESS', 3, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 2.27646), ARRAY[16.4,22.9,39.3], ARRAY[false,false,false]),
    ('Б.17', 72, jsonb_build_object('PIPE_SIZE', '125/200', 'PRESSURE_PIPE_OUTER_DIAMETER', 125, 'PRESSURE_PIPE_WALL_THICKNESS', 11.4, 'SHELL_OUTER_DIAMETER', 200, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 2.34252), ARRAY[15.9,22.3,38.2], ARRAY[false,false,false]),
    ('Б.17', 73, jsonb_build_object('PIPE_SIZE', '110/200', 'PRESSURE_PIPE_OUTER_DIAMETER', 125, 'PRESSURE_PIPE_WALL_THICKNESS', 17.1, 'SHELL_OUTER_DIAMETER', 200, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 2.39905), ARRAY[15.7,21.9,37.6], ARRAY[false,false,false]),
    ('Б.17', 74, jsonb_build_object('PIPE_SIZE', '110/200', 'PRESSURE_PIPE_OUTER_DIAMETER', 125, 'PRESSURE_PIPE_WALL_THICKNESS', 17.1, 'SHELL_OUTER_DIAMETER', 201, 'SHELL_WALL_THICKNESS', 3.1, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 2.39549), ARRAY[15.7,21.9,37.6], ARRAY[false,false,false]),
    ('Б.17', 75, jsonb_build_object('PIPE_SIZE', '140/180', 'PRESSURE_PIPE_OUTER_DIAMETER', 127, 'PRESSURE_PIPE_WALL_THICKNESS', 7.1, 'SHELL_OUTER_DIAMETER', 180, 'SHELL_WALL_THICKNESS', 3, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 1.70399), ARRAY[20.6,29.4,50.0], ARRAY[false,false,false]),
    ('Б.17', 76, jsonb_build_object('PIPE_SIZE', '140/180', 'PRESSURE_PIPE_OUTER_DIAMETER', 127, 'PRESSURE_PIPE_WALL_THICKNESS', 7.1, 'SHELL_OUTER_DIAMETER', 185, 'SHELL_WALL_THICKNESS', 3, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 1.83695), ARRAY[19.4,27.6,47.0], ARRAY[false,false,false]),
    ('Б.17', 77, jsonb_build_object('PIPE_SIZE', '140/200', 'PRESSURE_PIPE_OUTER_DIAMETER', 127, 'PRESSURE_PIPE_WALL_THICKNESS', 7.1, 'SHELL_OUTER_DIAMETER', 200, 'SHELL_WALL_THICKNESS', 3.1, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 2.21051), ARRAY[16.8,23.5,40.3], ARRAY[false,false,false]),
    ('Б.17', 78, jsonb_build_object('PIPE_SIZE', '140/200', 'PRESSURE_PIPE_OUTER_DIAMETER', 127, 'PRESSURE_PIPE_WALL_THICKNESS', 7.1, 'SHELL_OUTER_DIAMETER', 201, 'SHELL_WALL_THICKNESS', 3.1, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 2.20472), ARRAY[16.6,23.3,39.9], ARRAY[false,false,false]),
    ('Б.17', 79, jsonb_build_object('PIPE_SIZE', '140/225', 'PRESSURE_PIPE_OUTER_DIAMETER', 140, 'PRESSURE_PIPE_WALL_THICKNESS', 12.7, 'SHELL_OUTER_DIAMETER', 225, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 2.37080), ARRAY[15.8,22.1,37.9], ARRAY[false,false,false]),
    ('Б.17', 80, jsonb_build_object('PIPE_SIZE', '125/225', 'PRESSURE_PIPE_OUTER_DIAMETER', 140, 'PRESSURE_PIPE_WALL_THICKNESS', 19.2, 'SHELL_OUTER_DIAMETER', 225, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 2.42123), ARRAY[15.6,21.7,37.3], ARRAY[false,false,false]),
    ('Б.17', 81, jsonb_build_object('PIPE_SIZE', '125/225', 'PRESSURE_PIPE_OUTER_DIAMETER', 140, 'PRESSURE_PIPE_WALL_THICKNESS', 19.2, 'SHELL_OUTER_DIAMETER', 225, 'SHELL_WALL_THICKNESS', 3.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 2.38019), ARRAY[15.7,22.1,37.8], ARRAY[false,false,false]),
    ('Б.17', 82, jsonb_build_object('PIPE_SIZE', '160/200', 'PRESSURE_PIPE_OUTER_DIAMETER', 144, 'PRESSURE_PIPE_WALL_THICKNESS', 7.5, 'SHELL_OUTER_DIAMETER', 200, 'SHELL_WALL_THICKNESS', 3.1, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 1.60104), ARRAY[21.6,31.0,52.6], ARRAY[false,false,false]),
    ('Б.17', 83, jsonb_build_object('PIPE_SIZE', '160/200', 'PRESSURE_PIPE_OUTER_DIAMETER', 144, 'PRESSURE_PIPE_WALL_THICKNESS', 7.5, 'SHELL_OUTER_DIAMETER', 200.5, 'SHELL_WALL_THICKNESS', 3.1, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 1.61316), ARRAY[21.4,30.8,52.2], ARRAY[false,false,false]),
    ('Б.17', 84, jsonb_build_object('PIPE_SIZE', '160/200', 'PRESSURE_PIPE_OUTER_DIAMETER', 144, 'PRESSURE_PIPE_WALL_THICKNESS', 7.5, 'SHELL_OUTER_DIAMETER', 201, 'SHELL_WALL_THICKNESS', 3.1, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 1.62525), ARRAY[21.3,30.6,51.9], ARRAY[false,false,false]),
    ('Б.17', 85, jsonb_build_object('PIPE_SIZE', '160/225', 'PRESSURE_PIPE_OUTER_DIAMETER', 144, 'PRESSURE_PIPE_WALL_THICKNESS', 7.5, 'SHELL_OUTER_DIAMETER', 225, 'SHELL_WALL_THICKNESS', 3.2, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 2.16948), ARRAY[17.0,23.9,40.9], ARRAY[false,false,false]),
    ('Б.17', 86, jsonb_build_object('PIPE_SIZE', '160/225', 'PRESSURE_PIPE_OUTER_DIAMETER', 144, 'PRESSURE_PIPE_WALL_THICKNESS', 7.5, 'SHELL_OUTER_DIAMETER', 226, 'SHELL_WALL_THICKNESS', 3.2, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.5, 'THERMAL_RESISTANCE', 2.19000), ARRAY[17.1,23.9,41.0], ARRAY[false,false,false]),
    ('Б.17', 87, jsonb_build_object('PIPE_SIZE', '160/250', 'PRESSURE_PIPE_OUTER_DIAMETER', 160, 'PRESSURE_PIPE_WALL_THICKNESS', 14.6, 'SHELL_OUTER_DIAMETER', 250, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.5, 'THERMAL_RESISTANCE', 2.23571), ARRAY[16.7,23.5,40.2], ARRAY[false,false,false]),
    ('Б.17', 88, jsonb_build_object('PIPE_SIZE', '140/250', 'PRESSURE_PIPE_OUTER_DIAMETER', 160, 'PRESSURE_PIPE_WALL_THICKNESS', 21.9, 'SHELL_OUTER_DIAMETER', 250, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.5, 'THERMAL_RESISTANCE', 2.28528), ARRAY[16.5,23.0,39.5], ARRAY[false,false,false]),
    ('Б.17', 89, jsonb_build_object('PIPE_SIZE', '140/250', 'PRESSURE_PIPE_OUTER_DIAMETER', 160, 'PRESSURE_PIPE_WALL_THICKNESS', 21.9, 'SHELL_OUTER_DIAMETER', 250, 'SHELL_WALL_THICKNESS', 3.9, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.5, 'THERMAL_RESISTANCE', 2.23367), ARRAY[16.8,23.5,40.3], ARRAY[false,false,false]),
    ('Б.17', 90, jsonb_build_object('PIPE_SIZE', '180/250', 'PRESSURE_PIPE_OUTER_DIAMETER', 180, 'PRESSURE_PIPE_WALL_THICKNESS', 16.4, 'SHELL_OUTER_DIAMETER', 250, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.5, 'THERMAL_RESISTANCE', 1.66751), ARRAY[21.2,30.2,51.4], ARRAY[false,false,false]),
    ('Б.17', 91, jsonb_build_object('PIPE_SIZE', '160/250', 'PRESSURE_PIPE_OUTER_DIAMETER', 180, 'PRESSURE_PIPE_WALL_THICKNESS', 24.6, 'SHELL_OUTER_DIAMETER', 250, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.5, 'THERMAL_RESISTANCE', 1.71698), ARRAY[20.7,29.5,50.2], ARRAY[false,false,false]),
    ('Б.17', 92, jsonb_build_object('PIPE_SIZE', '160/250', 'PRESSURE_PIPE_OUTER_DIAMETER', 180, 'PRESSURE_PIPE_WALL_THICKNESS', 24.6, 'SHELL_OUTER_DIAMETER', 250, 'SHELL_WALL_THICKNESS', 3.9, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.5, 'THERMAL_RESISTANCE', 1.66538), ARRAY[21.2,30.3,51.5], ARRAY[false,false,false]),
    ('Б.18', 1, jsonb_build_object('PIPE_SIZE', '25/63', 'PRESSURE_PIPE_OUTER_DIAMETER', 25, 'PRESSURE_PIPE_WALL_THICKNESS', 2.3, 'SHELL_OUTER_DIAMETER', 63, 'SHELL_WALL_THICKNESS', 2, 'AXIS_DISTANCE', 0.213), ARRAY[9.4,12.9,22.3], ARRAY[false,false,false]),
    ('Б.18', 2, jsonb_build_object('PIPE_SIZE', '25/63', 'PRESSURE_PIPE_OUTER_DIAMETER', 25, 'PRESSURE_PIPE_WALL_THICKNESS', 3.5, 'SHELL_OUTER_DIAMETER', 63, 'SHELL_WALL_THICKNESS', 2, 'AXIS_DISTANCE', 0.213), ARRAY[9.3,12.8,22.1], ARRAY[false,false,false]),
    ('Б.18', 3, jsonb_build_object('PIPE_SIZE', '25/63', 'PRESSURE_PIPE_OUTER_DIAMETER', 25, 'PRESSURE_PIPE_WALL_THICKNESS', 2.3, 'SHELL_OUTER_DIAMETER', 64, 'SHELL_WALL_THICKNESS', 2, 'AXIS_DISTANCE', 0.214), ARRAY[9.3,12.7,22.0], ARRAY[false,false,false]),
    ('Б.18', 4, jsonb_build_object('PIPE_SIZE', '32/63', 'PRESSURE_PIPE_OUTER_DIAMETER', 32, 'PRESSURE_PIPE_WALL_THICKNESS', 2.9, 'SHELL_OUTER_DIAMETER', 63, 'SHELL_WALL_THICKNESS', 2, 'AXIS_DISTANCE', 0.213), ARRAY[12.6,17.4,30.0], ARRAY[false,false,false]),
    ('Б.18', 5, jsonb_build_object('PIPE_SIZE', '32/63', 'PRESSURE_PIPE_OUTER_DIAMETER', 32, 'PRESSURE_PIPE_WALL_THICKNESS', 4.4, 'SHELL_OUTER_DIAMETER', 63, 'SHELL_WALL_THICKNESS', 2, 'AXIS_DISTANCE', 0.213), ARRAY[12.4,17.1,29.5], ARRAY[false,false,false]),
    ('Б.18', 6, jsonb_build_object('PIPE_SIZE', '32/63', 'PRESSURE_PIPE_OUTER_DIAMETER', 32, 'PRESSURE_PIPE_WALL_THICKNESS', 2.9, 'SHELL_OUTER_DIAMETER', 64, 'SHELL_WALL_THICKNESS', 2, 'AXIS_DISTANCE', 0.214), ARRAY[12.3,17.0,29.3], ARRAY[false,false,false]),
    ('Б.18', 7, jsonb_build_object('PIPE_SIZE', '32/90', 'PRESSURE_PIPE_OUTER_DIAMETER', 32, 'PRESSURE_PIPE_WALL_THICKNESS', 2.9, 'SHELL_OUTER_DIAMETER', 90, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.24), ARRAY[8.5,11.5,20.0], ARRAY[false,false,false]),
    ('Б.18', 8, jsonb_build_object('PIPE_SIZE', '32/90', 'PRESSURE_PIPE_OUTER_DIAMETER', 32, 'PRESSURE_PIPE_WALL_THICKNESS', 4.4, 'SHELL_OUTER_DIAMETER', 94, 'SHELL_WALL_THICKNESS', 2.2, 'AXIS_DISTANCE', 0.244), ARRAY[8.0,10.9,18.9], ARRAY[false,false,false]),
    ('Б.18', 9, jsonb_build_object('PIPE_SIZE', '40/75', 'PRESSURE_PIPE_OUTER_DIAMETER', 40, 'PRESSURE_PIPE_WALL_THICKNESS', 2.8, 'SHELL_OUTER_DIAMETER', 75, 'SHELL_WALL_THICKNESS', 2, 'AXIS_DISTANCE', 0.225), ARRAY[13.4,18.5,31.9], ARRAY[false,false,false]),
    ('Б.18', 10, jsonb_build_object('PIPE_SIZE', '40/75', 'PRESSURE_PIPE_OUTER_DIAMETER', 40, 'PRESSURE_PIPE_WALL_THICKNESS', 3.7, 'SHELL_OUTER_DIAMETER', 75, 'SHELL_WALL_THICKNESS', 2, 'AXIS_DISTANCE', 0.225), ARRAY[13.3,18.4,31.7], ARRAY[false,false,false]),
    ('Б.18', 11, jsonb_build_object('PIPE_SIZE', '40/75', 'PRESSURE_PIPE_OUTER_DIAMETER', 40, 'PRESSURE_PIPE_WALL_THICKNESS', 5.5, 'SHELL_OUTER_DIAMETER', 75, 'SHELL_WALL_THICKNESS', 2, 'AXIS_DISTANCE', 0.225), ARRAY[13.1,18.1,31.2], ARRAY[false,false,false]),
    ('Б.18', 12, jsonb_build_object('PIPE_SIZE', '40/75', 'PRESSURE_PIPE_OUTER_DIAMETER', 40, 'PRESSURE_PIPE_WALL_THICKNESS', 2.8, 'SHELL_OUTER_DIAMETER', 79, 'SHELL_WALL_THICKNESS', 2, 'AXIS_DISTANCE', 0.229), ARRAY[12.4,17.1,29.5], ARRAY[false,false,false]),
    ('Б.18', 13, jsonb_build_object('PIPE_SIZE', '40/75', 'PRESSURE_PIPE_OUTER_DIAMETER', 40, 'PRESSURE_PIPE_WALL_THICKNESS', 4, 'SHELL_OUTER_DIAMETER', 79, 'SHELL_WALL_THICKNESS', 2, 'AXIS_DISTANCE', 0.229), ARRAY[12.3,17.0,29.3], ARRAY[false,false,false]),
    ('Б.18', 14, jsonb_build_object('PIPE_SIZE', '32/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 40, 'PRESSURE_PIPE_WALL_THICKNESS', 5.5, 'SHELL_OUTER_DIAMETER', 110, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.26), ARRAY[8.5,11.6,20.1], ARRAY[false,false,false]),
    ('Б.18', 15, jsonb_build_object('PIPE_SIZE', '40/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 40, 'PRESSURE_PIPE_WALL_THICKNESS', 3.7, 'SHELL_OUTER_DIAMETER', 110, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.26), ARRAY[8.6,11.7,20.3], ARRAY[false,false,false]),
    ('Б.18', 16, jsonb_build_object('PIPE_SIZE', '32/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 40, 'PRESSURE_PIPE_WALL_THICKNESS', 5.5, 'SHELL_OUTER_DIAMETER', 115, 'SHELL_WALL_THICKNESS', 2.4, 'AXIS_DISTANCE', 0.265), ARRAY[8.2,11.1,19.3], ARRAY[false,false,false]),
    ('Б.18', 17, jsonb_build_object('PIPE_SIZE', '50/90', 'PRESSURE_PIPE_OUTER_DIAMETER', 47.6, 'PRESSURE_PIPE_WALL_THICKNESS', 3.6, 'SHELL_OUTER_DIAMETER', 94, 'SHELL_WALL_THICKNESS', 2.2, 'AXIS_DISTANCE', 0.244), ARRAY[12.4,17.0,29.4], ARRAY[false,false,false]),
    ('Б.18', 18, jsonb_build_object('PIPE_SIZE', '50/100', 'PRESSURE_PIPE_OUTER_DIAMETER', 47.6, 'PRESSURE_PIPE_WALL_THICKNESS', 3.6, 'SHELL_OUTER_DIAMETER', 103, 'SHELL_WALL_THICKNESS', 2.2, 'AXIS_DISTANCE', 0.253), ARRAY[11.0,15.1,26.1], ARRAY[false,false,false]),
    ('Б.18', 19, jsonb_build_object('PIPE_SIZE', '50/90', 'PRESSURE_PIPE_OUTER_DIAMETER', 47.7, 'PRESSURE_PIPE_WALL_THICKNESS', 3.6, 'SHELL_OUTER_DIAMETER', 90, 'SHELL_WALL_THICKNESS', 2.2, 'AXIS_DISTANCE', 0.24), ARRAY[13.2,18.2,31.4], ARRAY[false,false,false]),
    ('Б.18', 20, jsonb_build_object('PIPE_SIZE', '50/90', 'PRESSURE_PIPE_OUTER_DIAMETER', 47.7, 'PRESSURE_PIPE_WALL_THICKNESS', 3.6, 'SHELL_OUTER_DIAMETER', 94.4, 'SHELL_WALL_THICKNESS', 2.2, 'AXIS_DISTANCE', 0.244), ARRAY[12.3,17.0,29.3], ARRAY[false,false,false]),
    ('Б.18', 21, jsonb_build_object('PIPE_SIZE', '50/100', 'PRESSURE_PIPE_OUTER_DIAMETER', 47.7, 'PRESSURE_PIPE_WALL_THICKNESS', 3.6, 'SHELL_OUTER_DIAMETER', 100, 'SHELL_WALL_THICKNESS', 2.2, 'AXIS_DISTANCE', 0.25), ARRAY[11.4,15.7,27.1], ARRAY[false,false,false]),
    ('Б.18', 22, jsonb_build_object('PIPE_SIZE', '50/90', 'PRESSURE_PIPE_OUTER_DIAMETER', 50, 'PRESSURE_PIPE_WALL_THICKNESS', 4.6, 'SHELL_OUTER_DIAMETER', 90, 'SHELL_WALL_THICKNESS', 2.2, 'AXIS_DISTANCE', 0.24), ARRAY[14.1,19.5,33.6], ARRAY[false,false,false]),
    ('Б.18', 23, jsonb_build_object('PIPE_SIZE', '50/90', 'PRESSURE_PIPE_OUTER_DIAMETER', 50, 'PRESSURE_PIPE_WALL_THICKNESS', 6.9, 'SHELL_OUTER_DIAMETER', 90, 'SHELL_WALL_THICKNESS', 2.2, 'AXIS_DISTANCE', 0.24), ARRAY[13.9,19.1,33.0], ARRAY[false,false,false]),
    ('Б.18', 24, jsonb_build_object('PIPE_SIZE', '50/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 50, 'PRESSURE_PIPE_WALL_THICKNESS', 4.6, 'SHELL_OUTER_DIAMETER', 110, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.26), ARRAY[10.6,14.8,25.6], ARRAY[false,false,false]),
    ('Б.18', 25, jsonb_build_object('PIPE_SIZE', '40/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 50, 'PRESSURE_PIPE_WALL_THICKNESS', 6.9, 'SHELL_OUTER_DIAMETER', 110, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.26), ARRAY[10.7,14.6,25.3], ARRAY[false,false,false]),
    ('Б.18', 26, jsonb_build_object('PIPE_SIZE', '40/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 50, 'PRESSURE_PIPE_WALL_THICKNESS', 6.9, 'SHELL_OUTER_DIAMETER', 115, 'SHELL_WALL_THICKNESS', 2.4, 'AXIS_DISTANCE', 0.265), ARRAY[10.1,13.8,23.9], ARRAY[false,false,false]),
    ('Б.18', 27, jsonb_build_object('PIPE_SIZE', '63/100', 'PRESSURE_PIPE_OUTER_DIAMETER', 58.5, 'PRESSURE_PIPE_WALL_THICKNESS', 4, 'SHELL_OUTER_DIAMETER', 100, 'SHELL_WALL_THICKNESS', 2.2, 'AXIS_DISTANCE', 0.25), ARRAY[15.3,21.2,36.5], ARRAY[false,false,false]),
    ('Б.18', 28, jsonb_build_object('PIPE_SIZE', '63/100', 'PRESSURE_PIPE_OUTER_DIAMETER', 58.5, 'PRESSURE_PIPE_WALL_THICKNESS', 4, 'SHELL_OUTER_DIAMETER', 103, 'SHELL_WALL_THICKNESS', 2.2, 'AXIS_DISTANCE', 0.253), ARRAY[14.6,20.2,34.8], ARRAY[false,false,false]),
    ('Б.18', 29, jsonb_build_object('PIPE_SIZE', '63/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 58.5, 'PRESSURE_PIPE_WALL_THICKNESS', 4, 'SHELL_OUTER_DIAMETER', 110, 'SHELL_WALL_THICKNESS', 2.4, 'AXIS_DISTANCE', 0.26), ARRAY[13.3,18.3,31.6], ARRAY[false,false,false]),
    ('Б.18', 30, jsonb_build_object('PIPE_SIZE', '63/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 58.5, 'PRESSURE_PIPE_WALL_THICKNESS', 4, 'SHELL_OUTER_DIAMETER', 115, 'SHELL_WALL_THICKNESS', 2.4, 'AXIS_DISTANCE', 0.265), ARRAY[12.5,17.1,29.6], ARRAY[false,false,false]),
    ('Б.18', 31, jsonb_build_object('PIPE_SIZE', '63/100', 'PRESSURE_PIPE_OUTER_DIAMETER', 63, 'PRESSURE_PIPE_WALL_THICKNESS', 5.8, 'SHELL_OUTER_DIAMETER', 100, 'SHELL_WALL_THICKNESS', 2.2, 'AXIS_DISTANCE', 0.25), ARRAY[17.2,24.1,41.3], ARRAY[false,false,false]),
    ('Б.18', 32, jsonb_build_object('PIPE_SIZE', '63/100', 'PRESSURE_PIPE_OUTER_DIAMETER', 63, 'PRESSURE_PIPE_WALL_THICKNESS', 8.6, 'SHELL_OUTER_DIAMETER', 100, 'SHELL_WALL_THICKNESS', 2.2, 'AXIS_DISTANCE', 0.25), ARRAY[16.9,23.6,40.5], ARRAY[false,false,false]),
    ('Б.18', 33, jsonb_build_object('PIPE_SIZE', '63/125', 'PRESSURE_PIPE_OUTER_DIAMETER', 63, 'PRESSURE_PIPE_WALL_THICKNESS', 5.8, 'SHELL_OUTER_DIAMETER', 125, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.275), ARRAY[12.2,16.8,29.0], ARRAY[false,false,false]),
    ('Б.18', 34, jsonb_build_object('PIPE_SIZE', '50/125', 'PRESSURE_PIPE_OUTER_DIAMETER', 63, 'PRESSURE_PIPE_WALL_THICKNESS', 8.6, 'SHELL_OUTER_DIAMETER', 125, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.275), ARRAY[12.1,16.6,28.7], ARRAY[false,false,false]),
    ('Б.18', 35, jsonb_build_object('PIPE_SIZE', '50/125', 'PRESSURE_PIPE_OUTER_DIAMETER', 63, 'PRESSURE_PIPE_WALL_THICKNESS', 8.6, 'SHELL_OUTER_DIAMETER', 130, 'SHELL_WALL_THICKNESS', 2.6, 'AXIS_DISTANCE', 0.28), ARRAY[11.5,15.7,27.2], ARRAY[false,false,false]),
    ('Б.18', 36, jsonb_build_object('PIPE_SIZE', '75/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 69.5, 'PRESSURE_PIPE_WALL_THICKNESS', 4.6, 'SHELL_OUTER_DIAMETER', 110, 'SHELL_WALL_THICKNESS', 2.4, 'AXIS_DISTANCE', 0.28), ARRAY[17.5,24.5,42.0], ARRAY[false,false,false]),
    ('Б.18', 37, jsonb_build_object('PIPE_SIZE', '75/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 69.5, 'PRESSURE_PIPE_WALL_THICKNESS', 4.6, 'SHELL_OUTER_DIAMETER', 114.8, 'SHELL_WALL_THICKNESS', 2.4, 'AXIS_DISTANCE', 0.2648), ARRAY[16.2,22.5,38.7], ARRAY[false,false,false]),
    ('Б.18', 38, jsonb_build_object('PIPE_SIZE', '75/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 69.5, 'PRESSURE_PIPE_WALL_THICKNESS', 4.6, 'SHELL_OUTER_DIAMETER', 115, 'SHELL_WALL_THICKNESS', 2.4, 'AXIS_DISTANCE', 0.265), ARRAY[16.2,22.5,38.7], ARRAY[false,false,false]),
    ('Б.18', 39, jsonb_build_object('PIPE_SIZE', '75/125', 'PRESSURE_PIPE_OUTER_DIAMETER', 69.5, 'PRESSURE_PIPE_WALL_THICKNESS', 4.6, 'SHELL_OUTER_DIAMETER', 125, 'SHELL_WALL_THICKNESS', 2.6, 'AXIS_DISTANCE', 0.275), ARRAY[14.2,19.6,33.8], ARRAY[false,false,false]),
    ('Б.18', 40, jsonb_build_object('PIPE_SIZE', '75/125', 'PRESSURE_PIPE_OUTER_DIAMETER', 69.5, 'PRESSURE_PIPE_WALL_THICKNESS', 4.6, 'SHELL_OUTER_DIAMETER', 130, 'SHELL_WALL_THICKNESS', 2.6, 'AXIS_DISTANCE', 0.28), ARRAY[13.4,18.4,31.8], ARRAY[false,false,false]),
    ('Б.18', 41, jsonb_build_object('PIPE_SIZE', '75/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 75, 'PRESSURE_PIPE_WALL_THICKNESS', 6.8, 'SHELL_OUTER_DIAMETER', 110, 'SHELL_WALL_THICKNESS', 2.4, 'AXIS_DISTANCE', 0.26), ARRAY[20.2,28.5,48.7], ARRAY[false,false,false]),
    ('Б.18', 42, jsonb_build_object('PIPE_SIZE', '75/110', 'PRESSURE_PIPE_OUTER_DIAMETER', 75, 'PRESSURE_PIPE_WALL_THICKNESS', 10.3, 'SHELL_OUTER_DIAMETER', 110, 'SHELL_WALL_THICKNESS', 2.4, 'AXIS_DISTANCE', 0.26), ARRAY[19.8,27.8,47.6], ARRAY[false,false,false]),
    ('Б.18', 43, jsonb_build_object('PIPE_SIZE', '75/140', 'PRESSURE_PIPE_OUTER_DIAMETER', 75, 'PRESSURE_PIPE_WALL_THICKNESS', 6.8, 'SHELL_OUTER_DIAMETER', 140, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.29), ARRAY[13.3,18.2,31.5], ARRAY[false,false,false]),
    ('Б.18', 44, jsonb_build_object('PIPE_SIZE', '63/140', 'PRESSURE_PIPE_OUTER_DIAMETER', 75, 'PRESSURE_PIPE_WALL_THICKNESS', 10.3, 'SHELL_OUTER_DIAMETER', 140, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.29), ARRAY[13.1,18.0,31.1], ARRAY[false,false,false]),
    ('Б.18', 45, jsonb_build_object('PIPE_SIZE', '63/145', 'PRESSURE_PIPE_OUTER_DIAMETER', 75, 'PRESSURE_PIPE_WALL_THICKNESS', 10.3, 'SHELL_OUTER_DIAMETER', 150, 'SHELL_WALL_THICKNESS', 2.7, 'AXIS_DISTANCE', 0.3), ARRAY[11.9,16.4,28.3], ARRAY[false,false,false]),
    ('Б.18', 46, jsonb_build_object('PIPE_SIZE', '90/125', 'PRESSURE_PIPE_OUTER_DIAMETER', 84, 'PRESSURE_PIPE_WALL_THICKNESS', 6, 'SHELL_OUTER_DIAMETER', 125, 'SHELL_WALL_THICKNESS', 2.6, 'AXIS_DISTANCE', 0.275), ARRAY[19.8,27.8,47.6], ARRAY[false,false,false]),
    ('Б.18', 47, jsonb_build_object('PIPE_SIZE', '90/125', 'PRESSURE_PIPE_OUTER_DIAMETER', 84, 'PRESSURE_PIPE_WALL_THICKNESS', 6, 'SHELL_OUTER_DIAMETER', 128.7, 'SHELL_WALL_THICKNESS', 2.6, 'AXIS_DISTANCE', 0.2797), ARRAY[18.3,25.6,43.9], ARRAY[false,false,false]),
    ('Б.18', 48, jsonb_build_object('PIPE_SIZE', '90/125', 'PRESSURE_PIPE_OUTER_DIAMETER', 84, 'PRESSURE_PIPE_WALL_THICKNESS', 6, 'SHELL_OUTER_DIAMETER', 130, 'SHELL_WALL_THICKNESS', 2.6, 'AXIS_DISTANCE', 0.28), ARRAY[18.3,25.5,43.8], ARRAY[false,false,false]),
    ('Б.18', 49, jsonb_build_object('PIPE_SIZE', '90/145', 'PRESSURE_PIPE_OUTER_DIAMETER', 84, 'PRESSURE_PIPE_WALL_THICKNESS', 6, 'SHELL_OUTER_DIAMETER', 145, 'SHELL_WALL_THICKNESS', 2.7, 'AXIS_DISTANCE', 0.295), ARRAY[15.1,20.8,35.9], ARRAY[false,false,false]),
    ('Б.18', 50, jsonb_build_object('PIPE_SIZE', '90/145', 'PRESSURE_PIPE_OUTER_DIAMETER', 84, 'PRESSURE_PIPE_WALL_THICKNESS', 6, 'SHELL_OUTER_DIAMETER', 150, 'SHELL_WALL_THICKNESS', 2.7, 'AXIS_DISTANCE', 0.3), ARRAY[14.3,19.7,34.0], ARRAY[false,false,false]),
    ('Б.18', 51, jsonb_build_object('PIPE_SIZE', '90/125', 'PRESSURE_PIPE_OUTER_DIAMETER', 90, 'PRESSURE_PIPE_WALL_THICKNESS', 8.2, 'SHELL_OUTER_DIAMETER', 125, 'SHELL_WALL_THICKNESS', 2.6, 'AXIS_DISTANCE', 0.275), ARRAY[22.9,32.5,55.4], ARRAY[false,false,false]),
    ('Б.18', 52, jsonb_build_object('PIPE_SIZE', '90/125', 'PRESSURE_PIPE_OUTER_DIAMETER', 90, 'PRESSURE_PIPE_WALL_THICKNESS', 12.3, 'SHELL_OUTER_DIAMETER', 125, 'SHELL_WALL_THICKNESS', 2.6, 'AXIS_DISTANCE', 0.275), ARRAY[22.4,31.7,54.1], ARRAY[false,false,false]),
    ('Б.18', 53, jsonb_build_object('PIPE_SIZE', '90/140', 'PRESSURE_PIPE_OUTER_DIAMETER', 90, 'PRESSURE_PIPE_WALL_THICKNESS', 8.2, 'SHELL_OUTER_DIAMETER', 140, 'SHELL_WALL_THICKNESS', 2.7, 'AXIS_DISTANCE', 0.29), ARRAY[18.0,25.0,43.0], ARRAY[false,false,false]),
    ('Б.18', 54, jsonb_build_object('PIPE_SIZE', '90/160', 'PRESSURE_PIPE_OUTER_DIAMETER', 90, 'PRESSURE_PIPE_WALL_THICKNESS', 8.2, 'SHELL_OUTER_DIAMETER', 160, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.31), ARRAY[14.2,19.6,33.8], ARRAY[false,false,false]),
    ('Б.18', 55, jsonb_build_object('PIPE_SIZE', '75/160', 'PRESSURE_PIPE_OUTER_DIAMETER', 90, 'PRESSURE_PIPE_WALL_THICKNESS', 12.3, 'SHELL_OUTER_DIAMETER', 160, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.31), ARRAY[14.0,19.3,33.3], ARRAY[false,false,false]),
    ('Б.18', 56, jsonb_build_object('PIPE_SIZE', '75/160', 'PRESSURE_PIPE_OUTER_DIAMETER', 90, 'PRESSURE_PIPE_WALL_THICKNESS', 12.3, 'SHELL_OUTER_DIAMETER', 165, 'SHELL_WALL_THICKNESS', 2.9, 'AXIS_DISTANCE', 0.315), ARRAY[13.6,18.7,32.3], ARRAY[false,false,false]),
    ('Б.18', 57, jsonb_build_object('PIPE_SIZE', '110/145', 'PRESSURE_PIPE_OUTER_DIAMETER', 101, 'PRESSURE_PIPE_WALL_THICKNESS', 6.5, 'SHELL_OUTER_DIAMETER', 145, 'SHELL_WALL_THICKNESS', 2.7, 'AXIS_DISTANCE', 0.295), ARRAY[21.4,30.2,51.6], ARRAY[false,false,false]),
    ('Б.18', 58, jsonb_build_object('PIPE_SIZE', '110/145', 'PRESSURE_PIPE_OUTER_DIAMETER', 101, 'PRESSURE_PIPE_WALL_THICKNESS', 6.5, 'SHELL_OUTER_DIAMETER', 150, 'SHELL_WALL_THICKNESS', 2.7, 'AXIS_DISTANCE', 0.3), ARRAY[19.9,27.9,47.8], ARRAY[false,false,false]),
    ('Б.18', 59, jsonb_build_object('PIPE_SIZE', '110/145', 'PRESSURE_PIPE_OUTER_DIAMETER', 101, 'PRESSURE_PIPE_WALL_THICKNESS', 6.5, 'SHELL_OUTER_DIAMETER', 150.4, 'SHELL_WALL_THICKNESS', 2.7, 'AXIS_DISTANCE', 0.3004), ARRAY[19.8,27.7,47.5], ARRAY[false,false,false]),
    ('Б.18', 60, jsonb_build_object('PIPE_SIZE', '110/160', 'PRESSURE_PIPE_OUTER_DIAMETER', 101, 'PRESSURE_PIPE_WALL_THICKNESS', 6.5, 'SHELL_OUTER_DIAMETER', 160, 'SHELL_WALL_THICKNESS', 2.7, 'AXIS_DISTANCE', 0.31), ARRAY[17.5,24.3,41.8], ARRAY[false,false,false]),
    ('Б.18', 61, jsonb_build_object('PIPE_SIZE', '110/160', 'PRESSURE_PIPE_OUTER_DIAMETER', 101, 'PRESSURE_PIPE_WALL_THICKNESS', 6.5, 'SHELL_OUTER_DIAMETER', 165, 'SHELL_WALL_THICKNESS', 2.9, 'AXIS_DISTANCE', 0.315), ARRAY[16.8,23.2,40.0], ARRAY[false,false,false]),
    ('Б.18', 62, jsonb_build_object('PIPE_SIZE', '110/145', 'PRESSURE_PIPE_OUTER_DIAMETER', 110, 'PRESSURE_PIPE_WALL_THICKNESS', 10, 'SHELL_OUTER_DIAMETER', 145, 'SHELL_WALL_THICKNESS', 2.7, 'AXIS_DISTANCE', 0.295), ARRAY[26.2,37.5,63.7], ARRAY[false,false,false]),
    ('Б.18', 63, jsonb_build_object('PIPE_SIZE', '110/145', 'PRESSURE_PIPE_OUTER_DIAMETER', 110, 'PRESSURE_PIPE_WALL_THICKNESS', 15.1, 'SHELL_OUTER_DIAMETER', 145, 'SHELL_WALL_THICKNESS', 2.7, 'AXIS_DISTANCE', 0.295), ARRAY[25.5,36.4,61.9], ARRAY[false,false,false]),
    ('Б.18', 64, jsonb_build_object('PIPE_SIZE', '110/160', 'PRESSURE_PIPE_OUTER_DIAMETER', 110, 'PRESSURE_PIPE_WALL_THICKNESS', 10, 'SHELL_OUTER_DIAMETER', 160, 'SHELL_WALL_THICKNESS', 2.7, 'AXIS_DISTANCE', 0.31), ARRAY[20.5,28.8,49.3], ARRAY[false,false,false]),
    ('Б.18', 65, jsonb_build_object('PIPE_SIZE', '110/180', 'PRESSURE_PIPE_OUTER_DIAMETER', 110, 'PRESSURE_PIPE_WALL_THICKNESS', 10, 'SHELL_OUTER_DIAMETER', 180, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.33), ARRAY[16.4,22.7,39.1], ARRAY[false,false,false]),
    ('Б.18', 66, jsonb_build_object('PIPE_SIZE', '90/180', 'PRESSURE_PIPE_OUTER_DIAMETER', 110, 'PRESSURE_PIPE_WALL_THICKNESS', 15.1, 'SHELL_OUTER_DIAMETER', 180, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.33), ARRAY[16.1,22.3,38.4], ARRAY[false,false,false]),
    ('Б.18', 67, jsonb_build_object('PIPE_SIZE', '90/180', 'PRESSURE_PIPE_OUTER_DIAMETER', 110, 'PRESSURE_PIPE_WALL_THICKNESS', 15.1, 'SHELL_OUTER_DIAMETER', 185, 'SHELL_WALL_THICKNESS', 3, 'AXIS_DISTANCE', 0.335), ARRAY[15.5,21.4,36.9], ARRAY[false,false,false]),
    ('Б.18', 68, jsonb_build_object('PIPE_SIZE', '125/160', 'PRESSURE_PIPE_OUTER_DIAMETER', 116, 'PRESSURE_PIPE_WALL_THICKNESS', 6.8, 'SHELL_OUTER_DIAMETER', 160, 'SHELL_WALL_THICKNESS', 2.7, 'AXIS_DISTANCE', 0.31), ARRAY[23.6,33.4,57.0], ARRAY[false,false,false]),
    ('Б.18', 69, jsonb_build_object('PIPE_SIZE', '125/160', 'PRESSURE_PIPE_OUTER_DIAMETER', 116, 'PRESSURE_PIPE_WALL_THICKNESS', 6.8, 'SHELL_OUTER_DIAMETER', 165, 'SHELL_WALL_THICKNESS', 2.9, 'AXIS_DISTANCE', 0.315), ARRAY[22.3,31.5,53.8], ARRAY[false,false,false]),
    ('Б.18', 70, jsonb_build_object('PIPE_SIZE', '125/180', 'PRESSURE_PIPE_OUTER_DIAMETER', 116, 'PRESSURE_PIPE_WALL_THICKNESS', 6.8, 'SHELL_OUTER_DIAMETER', 180, 'SHELL_WALL_THICKNESS', 3, 'AXIS_DISTANCE', 0.33), ARRAY[18.5,25.7,44.2], ARRAY[false,false,false]),
    ('Б.18', 71, jsonb_build_object('PIPE_SIZE', '125/180', 'PRESSURE_PIPE_OUTER_DIAMETER', 116, 'PRESSURE_PIPE_WALL_THICKNESS', 6.8, 'SHELL_OUTER_DIAMETER', 185, 'SHELL_WALL_THICKNESS', 3, 'AXIS_DISTANCE', 0.335), ARRAY[17.5,24.3,41.8], ARRAY[false,false,false]),
    ('Б.18', 72, jsonb_build_object('PIPE_SIZE', '125/200', 'PRESSURE_PIPE_OUTER_DIAMETER', 125, 'PRESSURE_PIPE_WALL_THICKNESS', 11.4, 'SHELL_OUTER_DIAMETER', 200, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.35), ARRAY[17.0,23.6,40.6], ARRAY[false,false,false]),
    ('Б.18', 73, jsonb_build_object('PIPE_SIZE', '110/200', 'PRESSURE_PIPE_OUTER_DIAMETER', 125, 'PRESSURE_PIPE_WALL_THICKNESS', 17.1, 'SHELL_OUTER_DIAMETER', 200, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.35), ARRAY[16.7,23.1,39.8], ARRAY[false,false,false]),
    ('Б.18', 74, jsonb_build_object('PIPE_SIZE', '110/200', 'PRESSURE_PIPE_OUTER_DIAMETER', 125, 'PRESSURE_PIPE_WALL_THICKNESS', 17.1, 'SHELL_OUTER_DIAMETER', 201, 'SHELL_WALL_THICKNESS', 3.1, 'AXIS_DISTANCE', 0.351), ARRAY[16.8,23.2,40.0], ARRAY[false,false,false]),
    ('Б.18', 75, jsonb_build_object('PIPE_SIZE', '140/180', 'PRESSURE_PIPE_OUTER_DIAMETER', 127, 'PRESSURE_PIPE_WALL_THICKNESS', 7.1, 'SHELL_OUTER_DIAMETER', 180, 'SHELL_WALL_THICKNESS', 3, 'AXIS_DISTANCE', 0.33), ARRAY[22.6,31.7,54.3], ARRAY[false,false,false]),
    ('Б.18', 76, jsonb_build_object('PIPE_SIZE', '140/180', 'PRESSURE_PIPE_OUTER_DIAMETER', 127, 'PRESSURE_PIPE_WALL_THICKNESS', 7.1, 'SHELL_OUTER_DIAMETER', 185, 'SHELL_WALL_THICKNESS', 3, 'AXIS_DISTANCE', 0.335), ARRAY[21.2,29.6,50.8], ARRAY[false,false,false]),
    ('Б.18', 77, jsonb_build_object('PIPE_SIZE', '140/200', 'PRESSURE_PIPE_OUTER_DIAMETER', 127, 'PRESSURE_PIPE_WALL_THICKNESS', 7.1, 'SHELL_OUTER_DIAMETER', 200, 'SHELL_WALL_THICKNESS', 3.1, 'AXIS_DISTANCE', 0.35), ARRAY[18.0,25.0,43.0], ARRAY[false,false,false]),
    ('Б.18', 78, jsonb_build_object('PIPE_SIZE', '140/200', 'PRESSURE_PIPE_OUTER_DIAMETER', 127, 'PRESSURE_PIPE_WALL_THICKNESS', 7.1, 'SHELL_OUTER_DIAMETER', 201, 'SHELL_WALL_THICKNESS', 3.1, 'AXIS_DISTANCE', 0.351), ARRAY[17.6,24.7,42.5], ARRAY[false,false,false]),
    ('Б.18', 79, jsonb_build_object('PIPE_SIZE', '140/225', 'PRESSURE_PIPE_OUTER_DIAMETER', 140, 'PRESSURE_PIPE_WALL_THICKNESS', 12.7, 'SHELL_OUTER_DIAMETER', 225, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.375), ARRAY[16.9,23.4,40.3], ARRAY[false,false,false]),
    ('Б.18', 80, jsonb_build_object('PIPE_SIZE', '125/225', 'PRESSURE_PIPE_OUTER_DIAMETER', 140, 'PRESSURE_PIPE_WALL_THICKNESS', 19.2, 'SHELL_OUTER_DIAMETER', 225, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.375), ARRAY[16.6,22.9,39.5], ARRAY[false,false,false]),
    ('Б.18', 81, jsonb_build_object('PIPE_SIZE', '125/225', 'PRESSURE_PIPE_OUTER_DIAMETER', 140, 'PRESSURE_PIPE_WALL_THICKNESS', 19.2, 'SHELL_OUTER_DIAMETER', 225, 'SHELL_WALL_THICKNESS', 3.5, 'AXIS_DISTANCE', 0.375), ARRAY[16.9,23.3,40.2], ARRAY[false,false,false]),
    ('Б.18', 82, jsonb_build_object('PIPE_SIZE', '160/200', 'PRESSURE_PIPE_OUTER_DIAMETER', 144, 'PRESSURE_PIPE_WALL_THICKNESS', 7.5, 'SHELL_OUTER_DIAMETER', 200, 'SHELL_WALL_THICKNESS', 3.1, 'AXIS_DISTANCE', 0.35), ARRAY[23.8,33.5,57.3], ARRAY[false,false,false]),
    ('Б.18', 83, jsonb_build_object('PIPE_SIZE', '160/200', 'PRESSURE_PIPE_OUTER_DIAMETER', 144, 'PRESSURE_PIPE_WALL_THICKNESS', 7.5, 'SHELL_OUTER_DIAMETER', 200.5, 'SHELL_WALL_THICKNESS', 3.1, 'AXIS_DISTANCE', 0.3505), ARRAY[23.6,33.2,56.8], ARRAY[false,false,false]),
    ('Б.18', 84, jsonb_build_object('PIPE_SIZE', '160/200', 'PRESSURE_PIPE_OUTER_DIAMETER', 144, 'PRESSURE_PIPE_WALL_THICKNESS', 7.5, 'SHELL_OUTER_DIAMETER', 201, 'SHELL_WALL_THICKNESS', 3.1, 'AXIS_DISTANCE', 0.351), ARRAY[23.5,33.0,56.5], ARRAY[false,false,false]),
    ('Б.18', 85, jsonb_build_object('PIPE_SIZE', '160/225', 'PRESSURE_PIPE_OUTER_DIAMETER', 144, 'PRESSURE_PIPE_WALL_THICKNESS', 7.5, 'SHELL_OUTER_DIAMETER', 225, 'SHELL_WALL_THICKNESS', 3.2, 'AXIS_DISTANCE', 0.375), ARRAY[18.3,25.4,43.7], ARRAY[false,false,false]),
    ('Б.18', 86, jsonb_build_object('PIPE_SIZE', '160/225', 'PRESSURE_PIPE_OUTER_DIAMETER', 144, 'PRESSURE_PIPE_WALL_THICKNESS', 7.5, 'SHELL_OUTER_DIAMETER', 226, 'SHELL_WALL_THICKNESS', 3.2, 'AXIS_DISTANCE', 0.476), ARRAY[18.3,25.3,43.6], ARRAY[false,false,false]),
    ('Б.18', 87, jsonb_build_object('PIPE_SIZE', '160/250', 'PRESSURE_PIPE_OUTER_DIAMETER', 160, 'PRESSURE_PIPE_WALL_THICKNESS', 14.6, 'SHELL_OUTER_DIAMETER', 250, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.5), ARRAY[18.0,24.8,42.8], ARRAY[false,false,false]),
    ('Б.18', 88, jsonb_build_object('PIPE_SIZE', '140/250', 'PRESSURE_PIPE_OUTER_DIAMETER', 160, 'PRESSURE_PIPE_WALL_THICKNESS', 21.9, 'SHELL_OUTER_DIAMETER', 250, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.5), ARRAY[17.7,24.3,42.0], ARRAY[false,false,false]),
    ('Б.18', 89, jsonb_build_object('PIPE_SIZE', '140/250', 'PRESSURE_PIPE_OUTER_DIAMETER', 160, 'PRESSURE_PIPE_WALL_THICKNESS', 21.9, 'SHELL_OUTER_DIAMETER', 250, 'SHELL_WALL_THICKNESS', 3.9, 'AXIS_DISTANCE', 0.5), ARRAY[18.0,24.8,42.8], ARRAY[false,false,false]),
    ('Б.18', 90, jsonb_build_object('PIPE_SIZE', '180/250', 'PRESSURE_PIPE_OUTER_DIAMETER', 180, 'PRESSURE_PIPE_WALL_THICKNESS', 16.4, 'SHELL_OUTER_DIAMETER', 250, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.5), ARRAY[23.3,32.4,55.7], ARRAY[false,false,false]),
    ('Б.18', 91, jsonb_build_object('PIPE_SIZE', '160/250', 'PRESSURE_PIPE_OUTER_DIAMETER', 180, 'PRESSURE_PIPE_WALL_THICKNESS', 24.6, 'SHELL_OUTER_DIAMETER', 250, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.5), ARRAY[22.7,31.5,54.2], ARRAY[false,false,false]),
    ('Б.18', 92, jsonb_build_object('PIPE_SIZE', '160/250', 'PRESSURE_PIPE_OUTER_DIAMETER', 180, 'PRESSURE_PIPE_WALL_THICKNESS', 24.6, 'SHELL_OUTER_DIAMETER', 250, 'SHELL_WALL_THICKNESS', 3.9, 'AXIS_DISTANCE', 0.5), ARRAY[23.3,32.4,55.7], ARRAY[false,false,false]),
    ('Б.19', 1, jsonb_build_object('PIPE_SIZE', '29/90', 'PRESSURE_PIPE_INNER_DIAMETER', 29, 'PRESSURE_PIPE_OUTER_DIAMETER', 34, 'PRESSURE_PIPE_WALL_THICKNESS', 0.3, 'SHELL_OUTER_DIAMETER', 90, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 5.42806), ARRAY[7.6,10.3,17.9], ARRAY[false,false,false]),
    ('Б.19', 2, jsonb_build_object('PIPE_SIZE', '39/110', 'PRESSURE_PIPE_INNER_DIAMETER', 39, 'PRESSURE_PIPE_OUTER_DIAMETER', 44, 'PRESSURE_PIPE_WALL_THICKNESS', 0.4, 'SHELL_OUTER_DIAMETER', 110, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 5.06024), ARRAY[8.1,11.0,19.1], ARRAY[false,false,false]),
    ('Б.19', 3, jsonb_build_object('PIPE_SIZE', '48/110', 'PRESSURE_PIPE_INNER_DIAMETER', 48, 'PRESSURE_PIPE_OUTER_DIAMETER', 55, 'PRESSURE_PIPE_WALL_THICKNESS', 0.5, 'SHELL_OUTER_DIAMETER', 110, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.88414), ARRAY[10.2,14.1,24.3], ARRAY[false,false,false]),
    ('Б.19', 4, jsonb_build_object('PIPE_SIZE', '55/110', 'PRESSURE_PIPE_INNER_DIAMETER', 48, 'PRESSURE_PIPE_OUTER_DIAMETER', 54.3, 'PRESSURE_PIPE_WALL_THICKNESS', 0.5, 'SHELL_OUTER_DIAMETER', 114.8, 'SHELL_WALL_THICKNESS', 2.4, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 4.17538), ARRAY[9.6,13.2,22.8], ARRAY[false,false,false]),
    ('Б.19', 5, jsonb_build_object('PIPE_SIZE', '55/110', 'PRESSURE_PIPE_INNER_DIAMETER', 48, 'PRESSURE_PIPE_OUTER_DIAMETER', 54.3, 'PRESSURE_PIPE_WALL_THICKNESS', 0.5, 'SHELL_OUTER_DIAMETER', 115, 'SHELL_WALL_THICKNESS', 2.4, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 4.18532), ARRAY[9.5,13.2,22.7], ARRAY[false,false,false]),
    ('Б.19', 6, jsonb_build_object('PIPE_SIZE', '60/125', 'PRESSURE_PIPE_INNER_DIAMETER', 60, 'PRESSURE_PIPE_OUTER_DIAMETER', 66, 'PRESSURE_PIPE_WALL_THICKNESS', 0.5, 'SHELL_OUTER_DIAMETER', 125, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.45486), ARRAY[11.2,15.5,26.7], ARRAY[false,false,false]),
    ('Б.19', 7, jsonb_build_object('PIPE_SIZE', '66/125', 'PRESSURE_PIPE_INNER_DIAMETER', 60, 'PRESSURE_PIPE_OUTER_DIAMETER', 66, 'PRESSURE_PIPE_WALL_THICKNESS', 0.5, 'SHELL_OUTER_DIAMETER', 128.7, 'SHELL_WALL_THICKNESS', 2.6, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.69717), ARRAY[10.7,14.7,25.4], ARRAY[false,false,false]),
    ('Б.19', 8, jsonb_build_object('PIPE_SIZE', '66/125', 'PRESSURE_PIPE_INNER_DIAMETER', 60, 'PRESSURE_PIPE_OUTER_DIAMETER', 66, 'PRESSURE_PIPE_WALL_THICKNESS', 0.5, 'SHELL_OUTER_DIAMETER', 130, 'SHELL_WALL_THICKNESS', 2.6, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.71039), ARRAY[10.7,14.7,25.4], ARRAY[false,false,false]),
    ('Б.19', 9, jsonb_build_object('PIPE_SIZE', '76/140', 'PRESSURE_PIPE_INNER_DIAMETER', 76, 'PRESSURE_PIPE_OUTER_DIAMETER', 85, 'PRESSURE_PIPE_WALL_THICKNESS', 0.6, 'SHELL_OUTER_DIAMETER', 140, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.76886), ARRAY[13.6,19.4,32.5], ARRAY[false,false,false]),
    ('Б.19', 10, jsonb_build_object('PIPE_SIZE', '86/145', 'PRESSURE_PIPE_INNER_DIAMETER', 75, 'PRESSURE_PIPE_OUTER_DIAMETER', 85.6, 'PRESSURE_PIPE_WALL_THICKNESS', 0.6, 'SHELL_OUTER_DIAMETER', 150, 'SHELL_WALL_THICKNESS', 2.7, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.18894), ARRAY[12.1,16.9,29.0], ARRAY[false,false,false]),
    ('Б.19', 11, jsonb_build_object('PIPE_SIZE', '86/145', 'PRESSURE_PIPE_INNER_DIAMETER', 75, 'PRESSURE_PIPE_OUTER_DIAMETER', 85.6, 'PRESSURE_PIPE_WALL_THICKNESS', 0.6, 'SHELL_OUTER_DIAMETER', 150.4, 'SHELL_WALL_THICKNESS', 2.7, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.20510), ARRAY[12.1,16.8,28.9], ARRAY[false,false,false]),
    ('Б.19', 12, jsonb_build_object('PIPE_SIZE', '88/160', 'PRESSURE_PIPE_INNER_DIAMETER', 88, 'PRESSURE_PIPE_OUTER_DIAMETER', 98, 'PRESSURE_PIPE_WALL_THICKNESS', 0.7, 'SHELL_OUTER_DIAMETER', 160, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 2.76463), ARRAY[13.8,19.1,32.9], ARRAY[false,false,false]),
    ('Б.19', 13, jsonb_build_object('PIPE_SIZE', '109/160', 'PRESSURE_PIPE_INNER_DIAMETER', 98, 'PRESSURE_PIPE_OUTER_DIAMETER', 109.2, 'PRESSURE_PIPE_WALL_THICKNESS', 0.8, 'SHELL_OUTER_DIAMETER', 165, 'SHELL_WALL_THICKNESS', 2.9, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.21679), ARRAY[16.1,22.6,39.7], ARRAY[false,false,false]),
    ('Б.19', 14, jsonb_build_object('PIPE_SIZE', '109/160', 'PRESSURE_PIPE_INNER_DIAMETER', 98, 'PRESSURE_PIPE_OUTER_DIAMETER', 109.2, 'PRESSURE_PIPE_WALL_THICKNESS', 0.8, 'SHELL_OUTER_DIAMETER', 165.3, 'SHELL_WALL_THICKNESS', 2.9, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.23212), ARRAY[16.0,22.5,38.5], ARRAY[false,false,false]),
    ('Б.19', 15, jsonb_build_object('PIPE_SIZE', '98/180', 'PRESSURE_PIPE_INNER_DIAMETER', 98, 'PRESSURE_PIPE_OUTER_DIAMETER', 109, 'PRESSURE_PIPE_WALL_THICKNESS', 0.8, 'SHELL_OUTER_DIAMETER', 180, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 2.74526), ARRAY[13.8,19.1,32.9], ARRAY[false,false,false]),
    ('Б.19', 16, jsonb_build_object('PIPE_SIZE', '109/200', 'PRESSURE_PIPE_INNER_DIAMETER', 109, 'PRESSURE_PIPE_OUTER_DIAMETER', 119, 'PRESSURE_PIPE_WALL_THICKNESS', 0.8, 'SHELL_OUTER_DIAMETER', 200, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 2.86765), ARRAY[13.5,18.7,32.2], ARRAY[false,false,false]),
    ('Б.19', 17, jsonb_build_object('PIPE_SIZE', '143/200', 'PRESSURE_PIPE_INNER_DIAMETER', 127, 'PRESSURE_PIPE_OUTER_DIAMETER', 142.9, 'PRESSURE_PIPE_WALL_THICKNESS', 0.9, 'SHELL_OUTER_DIAMETER', 200.7, 'SHELL_WALL_THICKNESS', 3.1, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 1.93065), ARRAY[18.7,26.4,45.1], ARRAY[false,false,false]),
    ('Б.19', 18, jsonb_build_object('PIPE_SIZE', '143/200', 'PRESSURE_PIPE_INNER_DIAMETER', 127, 'PRESSURE_PIPE_OUTER_DIAMETER', 142.9, 'PRESSURE_PIPE_WALL_THICKNESS', 0.9, 'SHELL_OUTER_DIAMETER', 201, 'SHELL_WALL_THICKNESS', 3.1, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 1.93018), ARRAY[18.7,26.3,45.0], ARRAY[false,false,false]),
    ('Б.19', 19, jsonb_build_object('PIPE_SIZE', '127/225', 'PRESSURE_PIPE_INNER_DIAMETER', 127, 'PRESSURE_PIPE_OUTER_DIAMETER', 143, 'PRESSURE_PIPE_WALL_THICKNESS', 0.9, 'SHELL_OUTER_DIAMETER', 225, 'SHELL_WALL_THICKNESS', 2.6, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 2.56975), ARRAY[14.7,20.4,35.1], ARRAY[false,false,false]),
    ('Б.19', 20, jsonb_build_object('PIPE_SIZE', '144/250', 'PRESSURE_PIPE_INNER_DIAMETER', 144, 'PRESSURE_PIPE_OUTER_DIAMETER', 160, 'PRESSURE_PIPE_WALL_THICKNESS', 0.9, 'SHELL_OUTER_DIAMETER', 250, 'SHELL_WALL_THICKNESS', 2.5, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.5, 'THERMAL_RESISTANCE', 2.61668), ARRAY[14.7,20.4,35.1], ARRAY[false,false,false]),
    ('Б.19', 21, jsonb_build_object('PIPE_SIZE', '163/225', 'PRESSURE_PIPE_INNER_DIAMETER', 147, 'PRESSURE_PIPE_OUTER_DIAMETER', 163, 'PRESSURE_PIPE_WALL_THICKNESS', 1, 'SHELL_OUTER_DIAMETER', 226, 'SHELL_WALL_THICKNESS', 3.2, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.5, 'THERMAL_RESISTANCE', 1.83010), ARRAY[19.7,27.9,47.6], ARRAY[false,false,false]),
    ('Б.20', 1, jsonb_build_object('PIPE_SIZE', '29/90', 'PRESSURE_PIPE_INNER_DIAMETER', 29, 'PRESSURE_PIPE_OUTER_DIAMETER', 34, 'PRESSURE_PIPE_WALL_THICKNESS', 0.3, 'SHELL_OUTER_DIAMETER', 90, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.24), ARRAY[9.0,12.3,21.3], ARRAY[false,false,false]),
    ('Б.20', 2, jsonb_build_object('PIPE_SIZE', '39/110', 'PRESSURE_PIPE_INNER_DIAMETER', 39, 'PRESSURE_PIPE_OUTER_DIAMETER', 44, 'PRESSURE_PIPE_WALL_THICKNESS', 0.4, 'SHELL_OUTER_DIAMETER', 110, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.26), ARRAY[9.5,13.0,22.5], ARRAY[false,false,false]),
    ('Б.20', 3, jsonb_build_object('PIPE_SIZE', '48/110', 'PRESSURE_PIPE_INNER_DIAMETER', 48, 'PRESSURE_PIPE_OUTER_DIAMETER', 55, 'PRESSURE_PIPE_WALL_THICKNESS', 0.5, 'SHELL_OUTER_DIAMETER', 110, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.26), ARRAY[12.2,16.8,29.0], ARRAY[false,false,false]),
    ('Б.20', 4, jsonb_build_object('PIPE_SIZE', '55/110', 'PRESSURE_PIPE_INNER_DIAMETER', 48, 'PRESSURE_PIPE_OUTER_DIAMETER', 54.3, 'PRESSURE_PIPE_WALL_THICKNESS', 0.5, 'SHELL_OUTER_DIAMETER', 114.8, 'SHELL_WALL_THICKNESS', 2.4, 'AXIS_DISTANCE', 0.2648), ARRAY[11.4,15.6,27.0], ARRAY[false,false,false]),
    ('Б.20', 5, jsonb_build_object('PIPE_SIZE', '55/110', 'PRESSURE_PIPE_INNER_DIAMETER', 48, 'PRESSURE_PIPE_OUTER_DIAMETER', 54.3, 'PRESSURE_PIPE_WALL_THICKNESS', 0.5, 'SHELL_OUTER_DIAMETER', 115, 'SHELL_WALL_THICKNESS', 2.4, 'AXIS_DISTANCE', 0.265), ARRAY[11.4,15.6,27.0], ARRAY[false,false,false]),
    ('Б.20', 6, jsonb_build_object('PIPE_SIZE', '60/125', 'PRESSURE_PIPE_INNER_DIAMETER', 60, 'PRESSURE_PIPE_OUTER_DIAMETER', 66, 'PRESSURE_PIPE_WALL_THICKNESS', 0.5, 'SHELL_OUTER_DIAMETER', 125, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.275), ARRAY[13.4,18.5,31.9], ARRAY[false,false,false]),
    ('Б.20', 7, jsonb_build_object('PIPE_SIZE', '66/125', 'PRESSURE_PIPE_INNER_DIAMETER', 60, 'PRESSURE_PIPE_OUTER_DIAMETER', 66, 'PRESSURE_PIPE_WALL_THICKNESS', 0.5, 'SHELL_OUTER_DIAMETER', 128.7, 'SHELL_WALL_THICKNESS', 2.6, 'AXIS_DISTANCE', 0.2797), ARRAY[12.7,17.5,30.2], ARRAY[false,false,false]),
    ('Б.20', 8, jsonb_build_object('PIPE_SIZE', '66/125', 'PRESSURE_PIPE_INNER_DIAMETER', 60, 'PRESSURE_PIPE_OUTER_DIAMETER', 66, 'PRESSURE_PIPE_WALL_THICKNESS', 0.5, 'SHELL_OUTER_DIAMETER', 130, 'SHELL_WALL_THICKNESS', 2.6, 'AXIS_DISTANCE', 0.28), ARRAY[12.7,17.4,30.1], ARRAY[false,false,false]),
    ('Б.20', 9, jsonb_build_object('PIPE_SIZE', '76/140', 'PRESSURE_PIPE_INNER_DIAMETER', 76, 'PRESSURE_PIPE_OUTER_DIAMETER', 85, 'PRESSURE_PIPE_WALL_THICKNESS', 0.6, 'SHELL_OUTER_DIAMETER', 140, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.29), ARRAY[16.3,22.6,38.9], ARRAY[false,false,false]),
    ('Б.20', 10, jsonb_build_object('PIPE_SIZE', '86/145', 'PRESSURE_PIPE_INNER_DIAMETER', 75, 'PRESSURE_PIPE_OUTER_DIAMETER', 85.6, 'PRESSURE_PIPE_WALL_THICKNESS', 0.6, 'SHELL_OUTER_DIAMETER', 150, 'SHELL_WALL_THICKNESS', 2.7, 'AXIS_DISTANCE', 0.3), ARRAY[14.5,20.0,34.5], ARRAY[false,false,false]),
    ('Б.20', 11, jsonb_build_object('PIPE_SIZE', '86/145', 'PRESSURE_PIPE_INNER_DIAMETER', 75, 'PRESSURE_PIPE_OUTER_DIAMETER', 85.6, 'PRESSURE_PIPE_WALL_THICKNESS', 0.6, 'SHELL_OUTER_DIAMETER', 150.4, 'SHELL_WALL_THICKNESS', 2.7, 'AXIS_DISTANCE', 0.3004), ARRAY[14.4,19.9,34.3], ARRAY[false,false,false]),
    ('Б.20', 12, jsonb_build_object('PIPE_SIZE', '88/160', 'PRESSURE_PIPE_INNER_DIAMETER', 88, 'PRESSURE_PIPE_OUTER_DIAMETER', 98, 'PRESSURE_PIPE_WALL_THICKNESS', 0.7, 'SHELL_OUTER_DIAMETER', 160, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.31), ARRAY[16.5,22.8,39.3], ARRAY[false,false,false]),
    ('Б.20', 13, jsonb_build_object('PIPE_SIZE', '109/160', 'PRESSURE_PIPE_INNER_DIAMETER', 98, 'PRESSURE_PIPE_OUTER_DIAMETER', 109.2, 'PRESSURE_PIPE_WALL_THICKNESS', 0.8, 'SHELL_OUTER_DIAMETER', 165, 'SHELL_WALL_THICKNESS', 2.9, 'AXIS_DISTANCE', 0.315), ARRAY[19.2,26.8,46.0], ARRAY[false,false,false]),
    ('Б.20', 14, jsonb_build_object('PIPE_SIZE', '109/160', 'PRESSURE_PIPE_INNER_DIAMETER', 98, 'PRESSURE_PIPE_OUTER_DIAMETER', 109.2, 'PRESSURE_PIPE_WALL_THICKNESS', 0.8, 'SHELL_OUTER_DIAMETER', 165.3, 'SHELL_WALL_THICKNESS', 2.9, 'AXIS_DISTANCE', 0.3153), ARRAY[19.1,26.7,45.8], ARRAY[false,false,false]),
    ('Б.20', 15, jsonb_build_object('PIPE_SIZE', '98/180', 'PRESSURE_PIPE_INNER_DIAMETER', 98, 'PRESSURE_PIPE_OUTER_DIAMETER', 109, 'PRESSURE_PIPE_WALL_THICKNESS', 0.8, 'SHELL_OUTER_DIAMETER', 180, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.33), ARRAY[16.3,22.5,38.8], ARRAY[false,false,false]),
    ('Б.20', 16, jsonb_build_object('PIPE_SIZE', '109/200', 'PRESSURE_PIPE_INNER_DIAMETER', 109, 'PRESSURE_PIPE_OUTER_DIAMETER', 119, 'PRESSURE_PIPE_WALL_THICKNESS', 0.8, 'SHELL_OUTER_DIAMETER', 200, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.35), ARRAY[15.9,22.0,37.9], ARRAY[false,false,false]),
    ('Б.20', 17, jsonb_build_object('PIPE_SIZE', '143/200', 'PRESSURE_PIPE_INNER_DIAMETER', 127, 'PRESSURE_PIPE_OUTER_DIAMETER', 142.9, 'PRESSURE_PIPE_WALL_THICKNESS', 0.9, 'SHELL_OUTER_DIAMETER', 200.7, 'SHELL_WALL_THICKNESS', 3.1, 'AXIS_DISTANCE', 0.3507), ARRAY[22.4,31.4,53.8], ARRAY[false,false,false]),
    ('Б.20', 18, jsonb_build_object('PIPE_SIZE', '143/200', 'PRESSURE_PIPE_INNER_DIAMETER', 127, 'PRESSURE_PIPE_OUTER_DIAMETER', 142.9, 'PRESSURE_PIPE_WALL_THICKNESS', 0.9, 'SHELL_OUTER_DIAMETER', 201, 'SHELL_WALL_THICKNESS', 3.1, 'AXIS_DISTANCE', 0.351), ARRAY[22.3,31.3,53.6], ARRAY[false,false,false]),
    ('Б.20', 19, jsonb_build_object('PIPE_SIZE', '127/225', 'PRESSURE_PIPE_INNER_DIAMETER', 127, 'PRESSURE_PIPE_OUTER_DIAMETER', 143, 'PRESSURE_PIPE_WALL_THICKNESS', 0.9, 'SHELL_OUTER_DIAMETER', 225, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.375), ARRAY[17.4,24.0,41.4], ARRAY[false,false,false]),
    ('Б.20', 20, jsonb_build_object('PIPE_SIZE', '144/250', 'PRESSURE_PIPE_INNER_DIAMETER', 144, 'PRESSURE_PIPE_OUTER_DIAMETER', 160, 'PRESSURE_PIPE_WALL_THICKNESS', 0.9, 'SHELL_OUTER_DIAMETER', 250, 'SHELL_WALL_THICKNESS', 2.5, 'AXIS_DISTANCE', 0.5), ARRAY[17.5,24.0,41.5], ARRAY[false,false,false]),
    ('Б.20', 21, jsonb_build_object('PIPE_SIZE', '163/225', 'PRESSURE_PIPE_INNER_DIAMETER', 147, 'PRESSURE_PIPE_OUTER_DIAMETER', 163, 'PRESSURE_PIPE_WALL_THICKNESS', 1, 'SHELL_OUTER_DIAMETER', 226, 'SHELL_WALL_THICKNESS', 3.2, 'AXIS_DISTANCE', 0.476), ARRAY[23.8,33.2,57.0], ARRAY[false,false,false]),
    ('Б.21', 1, jsonb_build_object('OUTER_DIAMETER', 26.9, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 6.62846), ARRAY[6.2,12.2,18.4], ARRAY[false,false,false]),
    ('Б.21', 2, jsonb_build_object('OUTER_DIAMETER', 33.7, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 5.39160), ARRAY[7.4,14.9,22.3], ARRAY[false,false,false]),
    ('Б.21', 3, jsonb_build_object('OUTER_DIAMETER', 42.4, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 5.23429), ARRAY[7.6,15.3,22.9], ARRAY[false,false,false]),
    ('Б.21', 4, jsonb_build_object('OUTER_DIAMETER', 48.3, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 4.51028), ARRAY[8.7,17.6,26.3], ARRAY[false,false,false]),
    ('Б.21', 5, jsonb_build_object('OUTER_DIAMETER', 60.3, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 4.00802), ARRAY[9.6,19.7,29.3], ARRAY[false,false,false]),
    ('Б.21', 6, jsonb_build_object('OUTER_DIAMETER', 76.1, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.34670), ARRAY[11.2,23.2,34.4], ARRAY[false,false,false]),
    ('Б.21', 7, jsonb_build_object('OUTER_DIAMETER', 88.9, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 0.9, 'THERMAL_RESISTANCE', 3.22846), ARRAY[11.5,24.0,35.5], ARRAY[false,false,false]),
    ('Б.21', 8, jsonb_build_object('OUTER_DIAMETER', 108, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 3.07429), ARRAY[11.3,23.2,34.5], ARRAY[false,false,false]),
    ('Б.21', 9, jsonb_build_object('OUTER_DIAMETER', 114.3, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 3.16024), ARRAY[12.3,25.3,37.6], ARRAY[false,false,false]),
    ('Б.21', 10, jsonb_build_object('OUTER_DIAMETER', 133, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.2, 'THERMAL_RESISTANCE', 2.98979), ARRAY[12.9,26.9,39.8], ARRAY[false,false,false]),
    ('Б.21', 11, jsonb_build_object('OUTER_DIAMETER', 139, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.5, 'THERMAL_RESISTANCE', 2.46144), ARRAY[14.8,31.1,45.9], ARRAY[false,false,false]),
    ('Б.21', 12, jsonb_build_object('OUTER_DIAMETER', 168.3, 'CHANNEL_HEIGHT', 0.45, 'CHANNEL_WIDTH', 1.5, 'THERMAL_RESISTANCE', 2.10447), ARRAY[16.4,35.1,51.5], ARRAY[false,false,false]),
    ('Б.21', 13, jsonb_build_object('OUTER_DIAMETER', 219.1, 'CHANNEL_HEIGHT', 0.6, 'CHANNEL_WIDTH', 1.5, 'THERMAL_RESISTANCE', 1.85848), ARRAY[17.9,38.4,56.3], ARRAY[false,false,false]),
    ('Б.21', 14, jsonb_build_object('OUTER_DIAMETER', 273, 'CHANNEL_HEIGHT', 0.6, 'CHANNEL_WIDTH', 1.8, 'THERMAL_RESISTANCE', 2.05166), ARRAY[17.5,37.0,54.5], ARRAY[false,false,false]),
    ('Б.21', 15, jsonb_build_object('OUTER_DIAMETER', 323.9, 'CHANNEL_HEIGHT', 0.9, 'CHANNEL_WIDTH', 1.8, 'THERMAL_RESISTANCE', 1.75582), ARRAY[20.2,42.9,63.1], ARRAY[false,false,false]),
    ('Б.21', 16, jsonb_build_object('OUTER_DIAMETER', 355.6, 'CHANNEL_HEIGHT', 0.9, 'CHANNEL_WIDTH', 1.8, 'THERMAL_RESISTANCE', 1.81607), ARRAY[19.6,41.6,61.2], ARRAY[false,false,false]),
    ('Б.21', 17, jsonb_build_object('OUTER_DIAMETER', 406.4, 'CHANNEL_HEIGHT', 0.9, 'CHANNEL_WIDTH', 2.1, 'THERMAL_RESISTANCE', 1.70646), ARRAY[20.8,44.3,65.1], ARRAY[false,false,false]),
    ('Б.21', 18, jsonb_build_object('OUTER_DIAMETER', 457.2, 'CHANNEL_HEIGHT', 0.91, 'CHANNEL_WIDTH', 2.1, 'THERMAL_RESISTANCE', 1.70163), ARRAY[20.6,44.1,64.7], ARRAY[false,false,false]),
    ('Б.21', 19, jsonb_build_object('OUTER_DIAMETER', 508, 'CHANNEL_HEIGHT', 0.91, 'CHANNEL_WIDTH', 2.1, 'THERMAL_RESISTANCE', 1.12340), ARRAY[27.6,63.2,90.8], ARRAY[false,false,false]),
    ('Б.21', 20, jsonb_build_object('OUTER_DIAMETER', 558.8, 'CHANNEL_HEIGHT', 0.99, 'CHANNEL_WIDTH', 2.4, 'THERMAL_RESISTANCE', 1.25422), ARRAY[26.2,58.0,84.2], ARRAY[false,false,false]),
    ('Б.21', 21, jsonb_build_object('OUTER_DIAMETER', 609.6, 'CHANNEL_HEIGHT', 1.08, 'CHANNEL_WIDTH', 2.4, 'THERMAL_RESISTANCE', 1.42941), ARRAY[23.9,51.9,75.8], ARRAY[false,false,false]),
    ('Б.21', 22, jsonb_build_object('OUTER_DIAMETER', 711.2, 'CHANNEL_HEIGHT', 1.18, 'CHANNEL_WIDTH', 3, 'THERMAL_RESISTANCE', 1.22758), ARRAY[27.3,60.0,87.3], ARRAY[false,false,false]),
    ('Б.21', 23, jsonb_build_object('OUTER_DIAMETER', 812.8, 'CHANNEL_HEIGHT', 1.3, 'CHANNEL_WIDTH', 3.05, 'THERMAL_RESISTANCE', 1.07222), ARRAY[30.4,67.6,98.0], ARRAY[false,false,false]),
    ('Б.21', 24, jsonb_build_object('OUTER_DIAMETER', 914.4, 'CHANNEL_HEIGHT', 1.5, 'CHANNEL_WIDTH', 3.25, 'THERMAL_RESISTANCE', 0.94732), ARRAY[33.5,75.7,109.2], ARRAY[false,false,false]),
    ('Б.21', 25, jsonb_build_object('OUTER_DIAMETER', 1016, 'CHANNEL_HEIGHT', 1.6, 'CHANNEL_WIDTH', 3.45, 'THERMAL_RESISTANCE', 0.84357), ARRAY[36.5,84.0,120.5], ARRAY[false,false,false]),
    ('Б.22', 1, jsonb_build_object('OUTER_DIAMETER', 26.9, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.24), ARRAY[6.5,12.7,19.2], ARRAY[false,false,false]),
    ('Б.22', 2, jsonb_build_object('OUTER_DIAMETER', 33.7, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.24), ARRAY[7.9,15.6,23.5], ARRAY[false,false,false]),
    ('Б.22', 3, jsonb_build_object('OUTER_DIAMETER', 42.4, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.26), ARRAY[8.1,16.0,24.1], ARRAY[false,false,false]),
    ('Б.22', 4, jsonb_build_object('OUTER_DIAMETER', 48.3, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.26), ARRAY[9.2,18.4,27.6], ARRAY[false,false,false]),
    ('Б.22', 5, jsonb_build_object('OUTER_DIAMETER', 60.3, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.275), ARRAY[10.3,20.6,30.9], ARRAY[false,false,false]),
    ('Б.22', 6, jsonb_build_object('OUTER_DIAMETER', 76.1, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.29), ARRAY[12.1,24.4,36.5], ARRAY[false,false,false]),
    ('Б.22', 7, jsonb_build_object('OUTER_DIAMETER', 88.9, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.31), ARRAY[12.5,25.2,37.7], ARRAY[false,false,false]),
    ('Б.22', 8, jsonb_build_object('OUTER_DIAMETER', 108, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.35), ARRAY[12.0,24.0,36.0], ARRAY[false,false,false]),
    ('Б.22', 9, jsonb_build_object('OUTER_DIAMETER', 114.3, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.35), ARRAY[13.1,26.4,39.5], ARRAY[false,false,false]),
    ('Б.22', 10, jsonb_build_object('OUTER_DIAMETER', 133, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.375), ARRAY[13.8,28.0,41.8], ARRAY[false,false,false]),
    ('Б.22', 11, jsonb_build_object('OUTER_DIAMETER', 159, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.5), ARRAY[16.1,32.4,48.5], ARRAY[false,false,false]),
    ('Б.22', 12, jsonb_build_object('OUTER_DIAMETER', 168.3, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.5), ARRAY[18.1,36.8,54.9], ARRAY[false,false,false]),
    ('Б.22', 13, jsonb_build_object('OUTER_DIAMETER', 219.1, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.565), ARRAY[19.7,40.1,59.8], ARRAY[false,false,false]),
    ('Б.22', 14, jsonb_build_object('OUTER_DIAMETER', 273, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.65), ARRAY[19.1,38.5,57.6], ARRAY[false,false,false]),
    ('Б.22', 15, jsonb_build_object('OUTER_DIAMETER', 323.9, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.7), ARRAY[21.9,44.5,66.4], ARRAY[false,false,false]),
    ('Б.22', 16, jsonb_build_object('OUTER_DIAMETER', 355.6, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.75), ARRAY[21.4,43.2,64.6], ARRAY[false,false,false]),
    ('Б.22', 17, jsonb_build_object('OUTER_DIAMETER', 406.4, 'BURIAL_DEPTH', 1, 'AXIS_DISTANCE', 0.81), ARRAY[22.8,45.9,68.7], ARRAY[false,false,false]),
    ('Б.22', 18, jsonb_build_object('OUTER_DIAMETER', 457.2, 'BURIAL_DEPTH', 1.1, 'AXIS_DISTANCE', 0.88), ARRAY[22.8,45.9,68.7], ARRAY[false,false,false]),
    ('Б.22', 19, jsonb_build_object('OUTER_DIAMETER', 508, 'BURIAL_DEPTH', 1.1, 'AXIS_DISTANCE', 0.96), ARRAY[32.1,66.8,98.9], ARRAY[false,false,false]),
    ('Б.22', 20, jsonb_build_object('OUTER_DIAMETER', 558.8, 'BURIAL_DEPTH', 1.1, 'AXIS_DISTANCE', 0.96), ARRAY[29.7,60.9,90.6], ARRAY[false,false,false]),
    ('Б.22', 21, jsonb_build_object('OUTER_DIAMETER', 609.6, 'BURIAL_DEPTH', 1.1, 'AXIS_DISTANCE', 1.05), ARRAY[27.0,54.4,81.4], ARRAY[false,false,false]),
    ('Б.22', 22, jsonb_build_object('OUTER_DIAMETER', 711.2, 'BURIAL_DEPTH', 1.2, 'AXIS_DISTANCE', 1.25), ARRAY[30.9,62.5,93.4], ARRAY[false,false,false]),
    ('Б.22', 23, jsonb_build_object('OUTER_DIAMETER', 812.8, 'BURIAL_DEPTH', 1.3, 'AXIS_DISTANCE', 1.35), ARRAY[34.5,70.5,105.0], ARRAY[false,false,false]),
    ('Б.22', 24, jsonb_build_object('OUTER_DIAMETER', 914.4, 'BURIAL_DEPTH', 1.3, 'AXIS_DISTANCE', 1.45), ARRAY[38.6,79.3,117.9], ARRAY[false,false,false]),
    ('Б.22', 25, jsonb_build_object('OUTER_DIAMETER', 1016, 'BURIAL_DEPTH', 1.3, 'AXIS_DISTANCE', 1.55), ARRAY[42.9,88.5,131.4], ARRAY[false,false,false]);

-- ============================================================
-- 5. КОНФИГУРАЦИЯ КОЛОНОК qh
-- ============================================================

CREATE TEMP TABLE tmp_qh_columns_seed (
    table_code            varchar(10) NOT NULL,
    ordinal_no            integer NOT NULL,
    pipeline_role         varchar(30) NOT NULL,
    temperature_c         numeric,
    supply_temperature_c  numeric,
    return_temperature_c  numeric,
    PRIMARY KEY (table_code, ordinal_no)
) ON COMMIT DROP;


-- Б.11-Б.14:
-- RETURN 50 / SUPPLY 65 / TOTAL 65/50 / SUPPLY 90 / TOTAL 90/50
INSERT INTO tmp_qh_columns_seed
SELECT
    t.table_code,
    c.ordinal_no,
    c.pipeline_role,
    NULL,
    c.supply_temperature_c,
    c.return_temperature_c
FROM (
    VALUES ('Б.11'),('Б.12'),('Б.13'),('Б.14')
) AS t(table_code)
CROSS JOIN (
    VALUES
        (1, 'RETURN',         NULL::numeric, 50::numeric),
        (2, 'SUPPLY',         65,            NULL),
        (3, 'TWO_PIPE_TOTAL', 65,            50),
        (4, 'SUPPLY',         90,            NULL),
        (5, 'TWO_PIPE_TOTAL', 90,            50)
) AS c(
    ordinal_no,
    pipeline_role,
    supply_temperature_c,
    return_temperature_c
);


-- Б.15, Б.16, Б.21, Б.22:
-- RETURN 50 / SUPPLY 90 / TOTAL 90/50
INSERT INTO tmp_qh_columns_seed
SELECT
    t.table_code,
    c.ordinal_no,
    c.pipeline_role,
    NULL,
    c.supply_temperature_c,
    c.return_temperature_c
FROM (
    VALUES ('Б.15'),('Б.16'),('Б.21'),('Б.22')
) AS t(table_code)
CROSS JOIN (
    VALUES
        (1, 'RETURN',         NULL::numeric, 50::numeric),
        (2, 'SUPPLY',         90,            NULL),
        (3, 'TWO_PIPE_TOTAL', 90,            50)
) AS c(
    ordinal_no,
    pipeline_role,
    supply_temperature_c,
    return_temperature_c
);


-- Б.17-Б.20:
-- RETURN 50 / SUPPLY 65 / TOTAL 65/50
INSERT INTO tmp_qh_columns_seed
SELECT
    t.table_code,
    c.ordinal_no,
    c.pipeline_role,
    NULL,
    c.supply_temperature_c,
    c.return_temperature_c
FROM (
    VALUES ('Б.17'),('Б.18'),('Б.19'),('Б.20')
) AS t(table_code)
CROSS JOIN (
    VALUES
        (1, 'RETURN',         NULL::numeric, 50::numeric),
        (2, 'SUPPLY',         65,            NULL),
        (3, 'TWO_PIPE_TOTAL', 65,            50)
) AS c(
    ordinal_no,
    pipeline_role,
    supply_temperature_c,
    return_temperature_c
);


-- ============================================================
-- 6. СТАРЫЕ СТРОКИ ДЕЛАЕМ НЕАКТИВНЫМИ
--    Затем реальные строки источника снова активируются.
-- ============================================================

UPDATE qh_rows r
SET is_active = false
FROM qh_tables t
WHERE t.id = r.table_id
  AND t.code IN (
      'Б.11','Б.12','Б.13','Б.14',
      'Б.15','Б.16','Б.17','Б.18',
      'Б.19','Б.20','Б.21','Б.22'
  );


-- ============================================================
-- 7. СОЗДАЕМ / ОБНОВЛЯЕМ qh_rows
-- ============================================================

INSERT INTO qh_rows (
    table_id,
    source_row_no,
    note,
    is_active
)
SELECT
    t.id,
    s.source_row_no,
    NULL,
    true
FROM tmp_qh_rows_seed s
JOIN qh_tables t
    ON t.code = s.table_code
ON CONFLICT (table_id, source_row_no)
DO UPDATE SET
    note = EXCLUDED.note,
    is_active = true;


-- ============================================================
-- 8. УДАЛЯЕМ СТАРЫЕ qh VALUES / DIMENSION VALUES
--    ДЛЯ Б.11-Б.22
-- ============================================================

DELETE FROM qh_values
WHERE row_id IN (
    SELECT r.id
    FROM qh_rows r
    JOIN qh_tables t
        ON t.id = r.table_id
    WHERE t.code IN (
        'Б.11','Б.12','Б.13','Б.14',
        'Б.15','Б.16','Б.17','Б.18',
        'Б.19','Б.20','Б.21','Б.22'
    )
);


DELETE FROM qh_row_dimension_values
WHERE row_id IN (
    SELECT r.id
    FROM qh_rows r
    JOIN qh_tables t
        ON t.id = r.table_id
    WHERE t.code IN (
        'Б.11','Б.12','Б.13','Б.14',
        'Б.15','Б.16','Б.17','Б.18',
        'Б.19','Б.20','Б.21','Б.22'
    )
);


-- ============================================================
-- 9. ЗАПОЛНЯЕМ qh_row_dimension_values
--
-- PIPE_SIZE -> TEXT
-- остальные dimensions -> NUMBER
-- value_type берём из qh_dimensions.
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

    CASE
        WHEN d.value_type = 'NUMBER'
        THEN e.value::numeric
        ELSE NULL
    END,

    CASE
        WHEN d.value_type = 'TEXT'
        THEN e.value
        ELSE NULL
    END

FROM tmp_qh_rows_seed s

JOIN qh_tables t
    ON t.code = s.table_code

JOIN qh_rows r
    ON r.table_id = t.id
   AND r.source_row_no = s.source_row_no

CROSS JOIN LATERAL
    jsonb_each_text(s.dimensions) AS e(code, value)

JOIN qh_dimensions d
    ON d.code = e.code;


-- ============================================================
-- 10. ЗАПОЛНЯЕМ qh_values
-- ============================================================

WITH cells AS (
    SELECT
        s.table_code,
        s.source_row_no,
        u.ordinality::integer AS ordinal_no,
        u.qh_value,
        s.interpolated[u.ordinality::integer] AS source_interpolated
    FROM tmp_qh_rows_seed s
    CROSS JOIN LATERAL
        unnest(s.qh_values)
        WITH ORDINALITY AS u(qh_value, ordinality)
)

INSERT INTO qh_values (
    row_id,
    pipeline_role,
    placement_variant,
    density_kind,
    temperature_c,
    supply_temperature_c,
    return_temperature_c,
    qh_value,
    source_interpolated,
    note
)
SELECT
    r.id,
    c.pipeline_role,
    NULL,
    'LINEAR',
    c.temperature_c,
    c.supply_temperature_c,
    c.return_temperature_c,
    cells.qh_value,
    cells.source_interpolated,
    NULL
FROM cells
JOIN qh_tables t
    ON t.code = cells.table_code
JOIN qh_rows r
    ON r.table_id = t.id
   AND r.source_row_no = cells.source_row_no
JOIN tmp_qh_columns_seed c
    ON c.table_code = cells.table_code
   AND c.ordinal_no = cells.ordinal_no;


COMMIT;


-- ============================================================
-- ПРОВЕРКА
--
-- ОЖИДАЕМЫЕ ACTIVE qh_rows:
-- Б.11=25  Б.12=25  Б.13=22  Б.14=22
-- Б.15=31  Б.16=31
-- Б.17=92  Б.18=92
-- Б.19=21  Б.20=21
-- Б.21=25  Б.22=25
-- ИТОГО = 432
--
-- ОЖИДАЕМЫЕ qh_values:
-- Б.11=125 Б.12=125 Б.13=110 Б.14=110
-- Б.15=93  Б.16=93
-- Б.17=276 Б.18=276
-- Б.19=63  Б.20=63
-- Б.21=75  Б.22=75
-- ИТОГО = 1484
-- ============================================================

SELECT
    t.code,
    count(*) AS active_rows
FROM qh_rows r
JOIN qh_tables t
    ON t.id = r.table_id
WHERE t.code IN (
    'Б.11','Б.12','Б.13','Б.14',
    'Б.15','Б.16','Б.17','Б.18',
    'Б.19','Б.20','Б.21','Б.22'
)
AND r.is_active = true
GROUP BY t.code
ORDER BY regexp_replace(t.code, '\D', '', 'g')::integer;


SELECT
    t.code,
    count(*) AS qh_values_count
FROM qh_values v
JOIN qh_rows r
    ON r.id = v.row_id
JOIN qh_tables t
    ON t.id = r.table_id
WHERE t.code IN (
    'Б.11','Б.12','Б.13','Б.14',
    'Б.15','Б.16','Б.17','Б.18',
    'Б.19','Б.20','Б.21','Б.22'
)
AND r.is_active = true
GROUP BY t.code
ORDER BY regexp_replace(t.code, '\D', '', 'g')::integer;
