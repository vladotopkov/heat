BEGIN;

-- Таблица Б.15, qh_table_id = 1.
-- Одна строка Б.15 разворачивается в три записи qh_values:
-- RETURN, SUPPLY и TWO_PIPE_TOTAL.

DELETE FROM qh_values
WHERE qh_table_id = 1;

WITH src (
    outer_diameter_mm,
    channel_height_m,
    channel_width_m,
    thermal_resistance,
    return_qh,
    supply_qh,
    total_qh
) AS (
    VALUES
        (32.0,   0.45,  0.90, 5.06537,  7.9,  15.8,  23.7),
        (33.5,   0.45,  0.90, 4.84444,  8.2,  16.4,  24.6),
        (38.0,   0.45,  0.90, 5.16583,  7.7,  15.5,  23.2),
        (42.3,   0.45,  0.90, 4.64881,  8.5,  17.1,  25.6),
        (45.0,   0.45,  0.90, 4.35039,  9.0,  18.2,  27.2),
        (48.0,   0.45,  0.90, 4.03913,  9.6,  19.5,  29.1),
        (57.0,   0.45,  0.90, 3.82284, 10.0,  20.5,  30.6),
        (60.0,   0.45,  0.90, 3.57546, 10.6,  21.8,  32.4),
        (75.5,   0.45,  0.90, 3.01050, 12.2,  25.6,  37.8),
        (76.0,   0.45,  0.90, 2.94531, 12.5,  26.0,  38.5),
        (88.5,   0.45,  0.90, 2.85572, 12.8,  26.8,  39.6),
        (89.0,   0.45,  0.90, 2.82854, 12.9,  27.0,  39.9),
        (108.0,  0.45,  1.20, 2.95844, 12.6,  26.1,  38.7),
        (114.0,  0.45,  1.20, 2.69768, 13.6,  28.4,  42.0),
        (133.0,  0.45,  1.20, 2.51180, 14.4,  30.3,  44.7),
        (140.0,  0.45,  1.20, 2.26441, 15.6,  33.3,  48.9),
        (159.0,  0.45,  1.50, 2.14669, 16.5,  35.1,  51.6),
        (165.0,  0.45,  1.50, 1.96805, 17.6,  37.9,  55.5),
        (219.0,  0.60,  1.50, 1.69297, 20.0,  43.6,  63.6),
        (273.0,  0.60,  1.80, 1.77476, 19.6,  42.1,  61.7),
        (325.0,  0.90,  1.80, 1.50560, 22.6,  49.2,  71.8),
        (377.0,  0.90,  1.80, 1.29167, 25.2,  56.2,  81.4),
        (426.0,  0.90,  2.10, 1.24190, 26.3,  58.5,  84.8),
        (530.0,  1.00,  2.40, 1.32000, 25.2,  55.5,  80.7),
        (630.0,  1.10,  2.40, 1.05746, 29.5,  67.3,  96.8),
        (720.0,  1.20,  3.00, 0.97695, 32.0,  73.0, 105.0),
        (820.0,  1.30,  3.10, 0.85514, 35.2,  81.9, 117.1),
        (920.0,  1.50,  3.30, 0.75512, 38.6,  91.6, 130.3),
        (1020.0, 1.60,  3.50, 0.67624, 41.7, 100.9, 142.6),
        (1220.0, 1.825, 3.90, 0.66198, 43.5, 103.9, 147.4),
        (1420.0, 2.00,  4.25, 0.48504, 52.2, 134.7, 186.9)
)
INSERT INTO qh_values (
    qh_table_id,
    outer_diameter_mm,
    channel_height_m,
    channel_width_m,
    thermal_resistance,
    pipeline_role,
    temperature_c,
    supply_temperature_c,
    return_temperature_c,
    qh_value,
    source_interpolated,
    note
)
SELECT
    1,
    s.outer_diameter_mm,
    s.channel_height_m,
    s.channel_width_m,
    s.thermal_resistance,
    v.pipeline_role,
    NULL,
    v.supply_temperature_c,
    v.return_temperature_c,
    v.qh_value,
    FALSE,
    NULL
FROM src s
CROSS JOIN LATERAL (
    VALUES
        ('RETURN'::varchar,         NULL::numeric, 50::numeric, s.return_qh),
        ('SUPPLY'::varchar,         90::numeric,   NULL::numeric, s.supply_qh),
        ('TWO_PIPE_TOTAL'::varchar, 90::numeric,   50::numeric,   s.total_qh)
) AS v (
    pipeline_role,
    supply_temperature_c,
    return_temperature_c,
    qh_value
);

COMMIT;

-- Проверка: должно вернуть 93 строки.
SELECT COUNT(*) AS b15_qh_values_count
FROM qh_values
WHERE qh_table_id = 1;
