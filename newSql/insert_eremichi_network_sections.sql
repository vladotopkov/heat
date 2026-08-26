BEGIN;

-- В исходном Excel встречаются и числовые значения, и '<5000',
-- поэтому сохраняем проектную продолжительность работы как текст.
ALTER TABLE "NetworkSection"
    ALTER COLUMN project_operating_hours TYPE VARCHAR(50)
    USING project_operating_hours::VARCHAR;

WITH qh AS (
    INSERT INTO qh_tables (table_name, table_code)
    VALUES (
        'Расчетная линейная плотность теплового потока через изолированную поверхность для трубопроводов двухтрубных водяных тепловых сетей при прокладке в непроходных каналах ПИ-трубопроводами, изготовленными в соответствии с СТБ 2252',
        'Б.15'
    )
    ON CONFLICT (table_code)
    DO UPDATE SET table_name = EXCLUDED.table_name
    RETURNING id
),
network AS (
    INSERT INTO "HeatNetwork" (name)
    VALUES ('Еремичи')
    RETURNING id
),
src (
    laying_type,
    underground_laying_type,
    project_operating_hours,
    burial_depth_m,
    insulation_layer,
    project_temperature_schedule,
    supply_outer_diameter_mm,
    supply_wall_thickness_mm,
    supply_shell_outer_diameter_mm,
    return_outer_diameter_mm,
    return_wall_thickness_mm,
    return_shell_outer_diameter_mm,
    length_m,
    project_year
) AS (
    VALUES
        ('Подземный', 'канальная', '3531', 1.2, '45.5', '+16', 159, 4.5, 250, 159, 4.5, 250, 150, 2011),
        ('Подземный', 'канальная', NULL, 1.15, '36', '+14', 38, 3, 110, 38, 3, 110, 35, 2011),
        ('Подземный', 'канальная', '<5000', 1.17, '34', '+13', 57, 3.5, 125, 57, 3.5, 125, 22, 2022),
        ('Подземный', 'канальная', NULL, 1.21, '25.5', '+17', 89, 3.5, 140, 89, 3.5, 140, 49, 2022),
        ('Подземный', 'канальная', NULL, 1.2, '34', '+22', 57, 3.5, 125, 57, 3.5, 125, 3, 2022),
        ('Подземный', 'канальная', NULL, 1.2, '34', '+14', 57, 3.5, 125, 57, 3.5, 125, 56, 2022),
        ('Подземный', 'канальная', '3531', 1.23, '34', '+16', 57, 3.5, 125, 57, 3.5, 125, 8, 2011),
        ('Подземный', 'канальная', '2488', 1.2, '35.5', '+16', 89, 3.5, 160, 89, 3.5, 160, 2, 2014),
        ('Подземный', 'канальная', '1916', 1.15, '46', '+14', 108, 4, 200, 108, 4, 200, 100, 2014),
        ('Подземный', 'канальная', NULL, 1.17, '46', '+13', 108, 4, 200, 108, 4, 200, 32, 2014),
        ('Подземный', 'канальная', '<5000', 1.21, '46', '+17', 108, 4, 200, 108, 4, 200, 160, 2013),
        ('Подземный', 'канальная', '<5000', 1.2, '46', '+22', 108, 4, 200, 108, 4, 200, 30, 2022),
        ('Подземный', 'канальная', NULL, 1.2, '34', '+14', 57, 3.5, 125, 57, 3.5, 125, 14, 2022),
        ('Подземный', 'канальная', NULL, 1.23, '32', '+16', 76, 3.5, 140, 76, 3.5, 140, 88, 2022),
        ('Подземный', 'канальная', '1916', 1.2, '34', '+16', 57, 3.5, 125, 57, 3.5, 125, 17, 2014),
        ('Подземный', 'канальная', '<5000', 1.15, '32', '+14', 76, 3.5, 140, 76, 3.5, 140, 57, 2022),
        ('Подземный', 'канальная', '2488', 1.17, '45.5', '+13', 159, 4.5, 250, 159, 4.5, 250, 14, 2014),
        ('Подземный', 'канальная', NULL, 1.21, '45.5', '+17', 159, 4.5, 250, 159, 4.5, 250, 77, 2014),
        ('Подземный', 'канальная', NULL, 1.2, '35.5', '+22', 89, 3.5, 160, 89, 3.5, 160, 10, 2014),
        ('Подземный', 'канальная', NULL, 1.2, '46', '+14', 108, 4, 200, 108, 4, 200, 35, 2014),
        ('Подземный', 'канальная', NULL, 1.23, '46', '+16', 108, 4, 200, 108, 4, 200, 43, 2014),
        ('Подземный', 'канальная', NULL, 1.2, '32', '+16', 76, 3.5, 140, 76, 3.5, 140, 18, 2014),
        ('Подземный', 'канальная', NULL, 1.15, '35.5', '+14', 89, 3.5, 160, 89, 3.5, 160, 17, 2014),
        ('Подземный', 'канальная', NULL, 1.17, '32', '+13', 76, 3.5, 140, 76, 3.5, 140, 12, 2014),
        ('Подземный', 'канальная', '2378', 1.21, '46', '+17', 133, 4, 225, 133, 4, 225, 110, 2018),
        ('Подземный', 'канальная', NULL, 1.2, '35.5', '+22', 89, 3.5, 160, 89, 3.5, 160, 25, 2018),
        ('Подземный', 'канальная', NULL, 1.2, '46', '+14', 108, 4, 200, 108, 4, 200, 30, 2018),
        ('Подземный', 'канальная', NULL, 1.23, '34', '+16', 57, 3.5, 125, 57, 3.5, 125, 2, 2018),
        ('Подземный', 'канальная', NULL, 1.2, '32.5', '+16', 45, 3, 110, 45, 3, 110, 4, 2018),
        ('Подземный', 'канальная', NULL, 1.15, '34', '+14', 57, 3.5, 125, 57, 3.5, 125, 25, 2018),
        ('Подземный', 'канальная', NULL, 1.17, '32.5', '+13', 45, 3, 110, 45, 3, 110, 110, 2018),
        ('Подземный', 'канальная', '<5000', 1.21, '34', '+17', 57, 3.5, 125, 57, 3.5, 125, 16, 2022),
        ('Подземный', 'канальная', NULL, 1.2, '34', '+22', 57, 3.5, 125, 57, 3.5, 125, 18, 2022),
        ('Подземный', 'канальная', '2488', 1.2, '34', '+14', 57, 3.5, 125, 57, 3.5, 125, 29, 2014)
)
INSERT INTO "NetworkSection" (
    heat_network_id,
    laying_type,
    underground_laying_type,
    project_operating_hours,
    burial_depth_m,
    insulation_layer,
    project_temperature_schedule,
    temperature_c,
    supply_temperature_c,
    return_temperature_c,
    supply_outer_diameter_mm,
    supply_wall_thickness_mm,
    supply_shell_outer_diameter_mm,
    return_outer_diameter_mm,
    return_wall_thickness_mm,
    return_shell_outer_diameter_mm,
    length_m,
    project_date,
    qh_table_id,
    beta
)
SELECT
    network.id,
    src.laying_type,
    src.underground_laying_type,
    src.project_operating_hours,
    src.burial_depth_m,
    src.insulation_layer,
    src.project_temperature_schedule,
    NULL,
    NULL,
    NULL,
    src.supply_outer_diameter_mm,
    src.supply_wall_thickness_mm,
    src.supply_shell_outer_diameter_mm,
    src.return_outer_diameter_mm,
    src.return_wall_thickness_mm,
    src.return_shell_outer_diameter_mm,
    src.length_m,
    CASE
        WHEN src.project_year IS NULL THEN NULL
        ELSE make_date(src.project_year, 1, 1)
    END,
    qh.id,
    NULL
FROM src
CROSS JOIN network
CROSS JOIN qh;

COMMIT;
