BEGIN;

-- ============================================================
-- ПРИЛОЖЕНИЕ В: В.1 - В.7
--
-- Заполняются:
--   qh_table_dimensions
--   qh_rows
--   qh_row_dimension_values
--   qh_values
--
-- НЕ заполняются здесь:
--   qh_selection_rules
--   qh_rule_conditions
--   qh_adjustment_rules
--
-- В.1, В.2, В.7:
--   OUTER_DIAMETER
--   SINGLE
--   LINEAR
--
-- В.3 - В.6:
--   PIPE    -> OBJECT_KIND + NOMINAL_BORE, LINEAR
--   SURFACE -> OBJECT_KIND, без NOMINAL_BORE, SURFACE
-- ============================================================


-- ============================================================
-- 1. ПРОВЕРКА qh_tables
-- ============================================================

DO $$
DECLARE
    missing text;
BEGIN
    SELECT string_agg(x.code, ', ' ORDER BY x.code)
    INTO missing
    FROM (
        VALUES ('В.1'),('В.2'),('В.3'),('В.4'),('В.5'),('В.6'),('В.7')
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
-- 2. ПРОВЕРКА dimensions
-- ============================================================

DO $$
DECLARE
    missing text;
BEGIN
    SELECT string_agg(x.code, ', ' ORDER BY x.code)
    INTO missing
    FROM (
        VALUES ('OUTER_DIAMETER'),('OBJECT_KIND'),('NOMINAL_BORE')
    ) AS x(code)
    WHERE NOT EXISTS (
        SELECT 1
        FROM qh_dimensions d
        WHERE d.code = x.code
    );

    IF missing IS NOT NULL THEN
        RAISE EXCEPTION 'Отсутствуют qh_dimensions: %', missing;
    END IF;
END $$;


-- ============================================================
-- 3. КОНФИГУРАЦИЯ DIMENSIONS
-- ============================================================

DELETE FROM qh_table_dimensions
WHERE table_id IN (
    SELECT id
    FROM qh_tables
    WHERE code IN ('В.1','В.2','В.3','В.4','В.5','В.6','В.7')
);

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
FROM (
    VALUES
        ('В.1','OUTER_DIAMETER',1,true),
        ('В.2','OUTER_DIAMETER',1,true),

        ('В.3','OBJECT_KIND',1,true),
        ('В.3','NOMINAL_BORE',2,true),

        ('В.4','OBJECT_KIND',1,true),
        ('В.4','NOMINAL_BORE',2,true),

        ('В.5','OBJECT_KIND',1,true),
        ('В.5','NOMINAL_BORE',2,true),

        ('В.6','OBJECT_KIND',1,true),
        ('В.6','NOMINAL_BORE',2,true),

        ('В.7','OUTER_DIAMETER',1,true)
) AS x(table_code, dimension_code, sequence_no, is_selector)
JOIN qh_tables t
    ON t.code = x.table_code
JOIN qh_dimensions d
    ON d.code = x.dimension_code;


-- ============================================================
-- 4. ИСХОДНЫЕ СТРОКИ
-- ============================================================

CREATE TEMP TABLE tmp_v_rows_seed (
    table_code          varchar(10) NOT NULL,
    source_row_no       integer NOT NULL,
    object_kind         varchar(20),
    dimension_code      varchar(60),
    dimension_value     numeric,
    qh_values           numeric[] NOT NULL,
    interpolated        boolean[] NOT NULL,
    note                text,
    PRIMARY KEY (table_code, source_row_no)
) ON COMMIT DROP;

INSERT INTO tmp_v_rows_seed (
    table_code,
    source_row_no,
    object_kind,
    dimension_code,
    dimension_value,
    qh_values,
    interpolated,
    note
)
VALUES
('В.1', 1, NULL, 'OUTER_DIAMETER', 19, ARRAY[12.1,13.3,50.5,90.7,124.8,160.8]::numeric[], ARRAY[true,true,true,true,true,true]::boolean[], NULL),
('В.1', 2, NULL, 'OUTER_DIAMETER', 21, ARRAY[12.9,15.2,52.4,93,127.9,165.1]::numeric[], ARRAY[true,true,true,true,true,true]::boolean[], NULL),
('В.1', 3, NULL, 'OUTER_DIAMETER', 25, ARRAY[13.9,17.8,55,96.1,132,170.8]::numeric[], ARRAY[true,true,true,true,true,true]::boolean[], NULL),
('В.1', 4, NULL, 'OUTER_DIAMETER', 27, ARRAY[14.4,19.1,56.3,97.7,134.1,173.6]::numeric[], ARRAY[true,true,true,true,true,true]::boolean[], NULL),
('В.1', 5, NULL, 'OUTER_DIAMETER', 32, ARRAY[15.7,22.3,59.5,101.6,139.3,180.7]::numeric[], ARRAY[true,true,true,true,true,true]::boolean[], NULL),
('В.1', 6, NULL, 'OUTER_DIAMETER', 34, ARRAY[16.2,23.6,60.8,103.1,141.3,183.6]::numeric[], ARRAY[true,true,true,true,true,true]::boolean[], NULL),
('В.1', 7, NULL, 'OUTER_DIAMETER', 38, ARRAY[17.2,26.2,63.4,106.2,145.5,189.3]::numeric[], ARRAY[true,true,true,true,true,true]::boolean[], NULL),
('В.1', 8, NULL, 'OUTER_DIAMETER', 42, ARRAY[18.3,28.7,65.9,109.3,149.6,195]::numeric[], ARRAY[true,true,true,true,true,true]::boolean[], NULL),
('В.1', 9, NULL, 'OUTER_DIAMETER', 45, ARRAY[19,30.7,67.9,111.7,152.7,199.2]::numeric[], ARRAY[true,true,true,true,true,true]::boolean[], NULL),
('В.1', 10, NULL, 'OUTER_DIAMETER', 48, ARRAY[19.8,32.6,69.8,114,155.8,203.5]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.1', 11, NULL, 'OUTER_DIAMETER', 57, ARRAY[22.1,38.4,75.6,121,165.1,216.3]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.1', 12, NULL, 'OUTER_DIAMETER', 76, ARRAY[24.4,43,86.1,136.1,184.9,240.7]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.1', 13, NULL, 'OUTER_DIAMETER', 89, ARRAY[27.9,47.7,93,145.4,197.7,255.9]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.1', 14, NULL, 'OUTER_DIAMETER', 108, ARRAY[30.2,53.5,101.2,156.2,214,278]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.1', 15, NULL, 'OUTER_DIAMETER', 114, ARRAY[31.3,54.9,104,162.1,219,284.1]::numeric[], ARRAY[true,true,true,true,true,true]::boolean[], NULL),
('В.1', 16, NULL, 'OUTER_DIAMETER', 133, ARRAY[34.9,59.3,112.8,174.5,234.9,303.5]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.1', 17, NULL, 'OUTER_DIAMETER', 159, ARRAY[38.4,66.3,123.3,190.7,257,329.1]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.1', 18, NULL, 'OUTER_DIAMETER', 219, ARRAY[46.5,81.4,147.7,225.6,300.1,383.8]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.1', 19, NULL, 'OUTER_DIAMETER', 273, ARRAY[53.5,91.9,164,247.7,321,419.8]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.1', 20, NULL, 'OUTER_DIAMETER', 325, ARRAY[61.6,102.3,181.4,275.6,354.7,450.4]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.1', 21, NULL, 'OUTER_DIAMETER', 377, ARRAY[68.6,114,196.9,301.2,389.6,504.7]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.1', 22, NULL, 'OUTER_DIAMETER', 426, ARRAY[75.6,123.3,218.6,326.8,415.2,536.1]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.1', 23, NULL, 'OUTER_DIAMETER', 478, ARRAY[81.4,133.7,229.1,347.7,443.1,569.9]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.1', 24, NULL, 'OUTER_DIAMETER', 529, ARRAY[88.4,144.2,250,374.5,475.7,610.6]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.1', 25, NULL, 'OUTER_DIAMETER', 630, ARRAY[102.3,164,281.4,412.9,524.5,665.2]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.1', 26, NULL, 'OUTER_DIAMETER', 720, ARRAY[114,181.4,309.4,453.6,579.2,732.7]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.1', 27, NULL, 'OUTER_DIAMETER', 820, ARRAY[126.8,200,341,512.9,651.3,810.6]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.1', 28, NULL, 'OUTER_DIAMETER', 920, ARRAY[138.4,223.3,373.3,553.6,693.1,885]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.1', 29, NULL, 'OUTER_DIAMETER', 1020, ARRAY[150,240.7,400.1,587.3,759.4,945.5]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.2', 1, NULL, 'OUTER_DIAMETER', 18, ARRAY[17.7,22,59.8,97.1,141.1,180.6]::numeric[], ARRAY[true,true,true,true,true,true]::boolean[], NULL),
('В.2', 2, NULL, 'OUTER_DIAMETER', 21, ARRAY[18.3,23.9,61.7,99.8,144.2,184.9]::numeric[], ARRAY[true,true,true,true,true,true]::boolean[], NULL),
('В.2', 3, NULL, 'OUTER_DIAMETER', 25, ARRAY[19,26.4,64.3,103.4,148.3,190.6]::numeric[], ARRAY[true,true,true,true,true,true]::boolean[], NULL),
('В.2', 4, NULL, 'OUTER_DIAMETER', 27, ARRAY[19.4,27.6,65.6,105.3,150.4,193.4]::numeric[], ARRAY[true,true,true,true,true,true]::boolean[], NULL),
('В.2', 5, NULL, 'OUTER_DIAMETER', 32, ARRAY[20.3,30.5,68.8,109.8,155.6,200.5]::numeric[], ARRAY[true,true,true,true,true,true]::boolean[], NULL),
('В.2', 6, NULL, 'OUTER_DIAMETER', 34, ARRAY[20.7,31.7,70.1,111.6,157.6,203.4]::numeric[], ARRAY[true,true,true,true,true,true]::boolean[], NULL),
('В.2', 7, NULL, 'OUTER_DIAMETER', 38, ARRAY[21.5,34,72.7,115.3,161.6,209.1]::numeric[], ARRAY[true,true,true,true,true,true]::boolean[], NULL),
('В.2', 8, NULL, 'OUTER_DIAMETER', 42, ARRAY[22.2,36.2,75.2,118.9,165.5,214.6]::numeric[], ARRAY[true,true,true,true,true,true]::boolean[], NULL),
('В.2', 9, NULL, 'OUTER_DIAMETER', 45, ARRAY[22.8,37.8,77.2,121.7,169,219]::numeric[], ARRAY[true,true,true,true,true,true]::boolean[], NULL),
('В.2', 10, NULL, 'OUTER_DIAMETER', 48, ARRAY[23.3,38.4,79.1,124.4,172.1,223.3]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.2', 11, NULL, 'OUTER_DIAMETER', 57, ARRAY[25.6,45.4,84.9,132.6,181.4,236.1]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.2', 12, NULL, 'OUTER_DIAMETER', 76, ARRAY[27.9,51.2,96.5,148.9,203.5,264]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.2', 13, NULL, 'OUTER_DIAMETER', 89, ARRAY[31.4,57,104.7,160.5,217.5,281.4]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.2', 14, NULL, 'OUTER_DIAMETER', 108, ARRAY[34.9,62.8,111.6,174.5,234.9,305.9]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.2', 15, NULL, 'OUTER_DIAMETER', 114, ARRAY[36,64.5,115.5,178.7,240.5,312.6]::numeric[], ARRAY[true,true,true,true,true,true]::boolean[], NULL),
('В.2', 16, NULL, 'OUTER_DIAMETER', 133, ARRAY[39.5,69.8,127.9,191.9,258.2,333.8]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.2', 17, NULL, 'OUTER_DIAMETER', 159, ARRAY[44.2,79.1,139.6,209.3,282.6,361.7]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.2', 18, NULL, 'OUTER_DIAMETER', 219, ARRAY[53.5,95.4,167.5,247.7,330.3,422.2]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.2', 19, NULL, 'OUTER_DIAMETER', 273, ARRAY[60.5,111.6,197.7,294.2,381.5,495.4]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.2', 20, NULL, 'OUTER_DIAMETER', 325, ARRAY[69.8,124.4,219.8,328,422.2,542]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.2', 21, NULL, 'OUTER_DIAMETER', 377, ARRAY[77.9,138.4,240.7,358.2,462.9,585.5]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.2', 22, NULL, 'OUTER_DIAMETER', 426, ARRAY[84.9,148.9,260.5,386.1,494.3,624.5]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.2', 23, NULL, 'OUTER_DIAMETER', 478, ARRAY[93,162.8,276.8,414,526.8,672.2]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.2', 24, NULL, 'OUTER_DIAMETER', 529, ARRAY[101.2,175.6,302.4,445.4,566.4,721.1]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.2', 25, NULL, 'OUTER_DIAMETER', 630, ARRAY[116.3,200,340.8,490.8,624.5,785]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.2', 26, NULL, 'OUTER_DIAMETER', 720, ARRAY[127.9,221,374.5,539.6,688.5,872.3]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.2', 27, NULL, 'OUTER_DIAMETER', 820, ARRAY[141.9,244.2,414,610.6,774.6,986]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.2', 28, NULL, 'OUTER_DIAMETER', 920, ARRAY[157,272.1,451.2,658.3,824.6,1052.5]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.2', 29, NULL, 'OUTER_DIAMETER', 1020, ARRAY[171,294.2,483.8,697.8,903.7,1115.3]::numeric[], ARRAY[false,false,false,false,false,false]::boolean[], NULL),
('В.3', 1, 'PIPE', 'NOMINAL_BORE', 15, ARRAY[3.2,8,16,24,33.6,44,54.4,66.4,79.2,92]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.3', 2, 'PIPE', 'NOMINAL_BORE', 20, ARRAY[4,8.8,17.6,27.2,37.6,48,60,72.8,86.4,101.6]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.3', 3, 'PIPE', 'NOMINAL_BORE', 25, ARRAY[4,10.4,21,29.6,41.6,52.8,65.6,79.2,93.6,109.6]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.3', 4, 'PIPE', 'NOMINAL_BORE', 32, ARRAY[4.7,11.1,21.5,32.2,44.2,56.8,70.5,85.2,100.7,117.4]::numeric[], ARRAY[true,true,true,true,true,true,true,true,true,true]::boolean[], NULL),
('В.3', 5, 'PIPE', 'NOMINAL_BORE', 40, ARRAY[5.6,12,23.2,35.2,47.2,61.6,76,92,108.8,126.4]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.3', 6, 'PIPE', 'NOMINAL_BORE', 50, ARRAY[5.6,13.6,24.8,37.6,51.2,65.6,81.6,96.4,116,134.4]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.3', 7, 'PIPE', 'NOMINAL_BORE', 65, ARRAY[7.2,15.2,28,43.2,57.6,74.4,91.2,109.6,129.6,149.6]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.3', 8, 'PIPE', 'NOMINAL_BORE', 80, ARRAY[8,16.8,31.2,46.4,61.6,79.2,97.6,117.6,137.6,160]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.3', 9, 'PIPE', 'NOMINAL_BORE', 100, ARRAY[8.8,19.2,34.4,51.2,68,87.2,107.2,128,149.6,172.8]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.3', 10, 'PIPE', 'NOMINAL_BORE', 125, ARRAY[9.6,21.6,38.2,56,74.4,97.6,119.2,142.4,166.4,192]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.3', 11, 'PIPE', 'NOMINAL_BORE', 150, ARRAY[11.2,24,43.2,61.6,81.6,107.2,131.2,155.2,180.8,208]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.3', 12, 'PIPE', 'NOMINAL_BORE', 200, ARRAY[14.4,29.6,52,74.4,97.6,127.2,155.2,182.4,212.8,244]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.3', 13, 'PIPE', 'NOMINAL_BORE', 250, ARRAY[16.8,34.4,60,84.8,110.4,143.2,172,203.2,235.2,269.6]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.3', 14, 'PIPE', 'NOMINAL_BORE', 300, ARRAY[20,39.2,67.2,94.4,124,158.4,191.2,224,259.2,296]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.3', 15, 'PIPE', 'NOMINAL_BORE', 350, ARRAY[22.4,44,74.4,104.8,136,174.4,208.8,244.8,282.4,322.4]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.3', 16, 'PIPE', 'NOMINAL_BORE', 400, ARRAY[24,48.8,81.6,113.6,148,188.6,225.6,264,304,346.4]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.3', 17, 'PIPE', 'NOMINAL_BORE', 450, ARRAY[26.4,52,87.2,121.6,157.6,201.6,240.8,280.8,320,368]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.3', 18, 'PIPE', 'NOMINAL_BORE', 500, ARRAY[28.8,56.8,95.2,132.8,168.8,216.8,257.6,300.8,344.8,392.8]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.3', 19, 'PIPE', 'NOMINAL_BORE', 600, ARRAY[33.6,65.6,108.8,150.4,192,244.8,290.4,337.6,386.4,438.4]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.3', 20, 'PIPE', 'NOMINAL_BORE', 700, ARRAY[38.4,73.6,120.8,167.2,211.2,269.6,319.2,370.4,423.2,479.2]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.3', 21, 'PIPE', 'NOMINAL_BORE', 800, ARRAY[42.4,82.4,133.6,170.4,233.6,296.8,350.4,405.6,463.2,523.2]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.3', 22, 'PIPE', 'NOMINAL_BORE', 900, ARRAY[47.2,90.4,147.2,202.4,255.2,324,381.6,440.8,502.4,567.2]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.3', 23, 'PIPE', 'NOMINAL_BORE', 1000, ARRAY[52,99.2,160.8,220,276.8,350.4,412.8,476,541.6,610.4]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.3', 24, 'SURFACE', NULL, NULL, ARRAY[15.2,28,43.2,56,68,84,96,108,120,132]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], 'Криволинейные поверхности диаметром более 1020 мм и плоские'),
('В.4', 1, 'PIPE', 'NOMINAL_BORE', 15, ARRAY[4,8.8,17.6,27.2,36.8,47.2,59.2,72,84.8,99.2]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.4', 2, 'PIPE', 'NOMINAL_BORE', 20, ARRAY[4.8,10.4,20,30.4,41.6,52.8,65.6,79.2,94.4,110.4]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.4', 3, 'PIPE', 'NOMINAL_BORE', 25, ARRAY[4.8,12,22.4,33.6,45.6,58.4,72,86.4,101.6,119.2]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.4', 4, 'PIPE', 'NOMINAL_BORE', 32, ARRAY[5.5,13.1,24.3,36.2,49,63.3,77.6,93.1,109.8,128.2]::numeric[], ARRAY[true,true,true,true,true,true,true,true,true,true]::boolean[], NULL),
('В.4', 5, 'PIPE', 'NOMINAL_BORE', 40, ARRAY[6.4,14.4,26.4,39.2,52.6,68.8,84,100.8,119.2,138.4]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.4', 6, 'PIPE', 'NOMINAL_BORE', 50, ARRAY[7.2,15.2,28.8,42.4,56.8,72.8,90.4,108,127.2,147.2]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.4', 7, 'PIPE', 'NOMINAL_BORE', 65, ARRAY[8,18.4,32.8,48.8,64.8,83.2,101.6,121.6,142.4,165.6]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.4', 8, 'PIPE', 'NOMINAL_BORE', 80, ARRAY[8.8,20,36,52.8,69.6,89.6,109.6,130.4,152.8,176.8]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.4', 9, 'PIPE', 'NOMINAL_BORE', 100, ARRAY[10.4,22.4,40,59.4,77.6,98.4,120,142.4,166.4,192.8]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.4', 10, 'PIPE', 'NOMINAL_BORE', 125, ARRAY[12,25.6,44.8,64.8,85.6,111.2,134.4,160,186.4,215.2]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.4', 11, 'PIPE', 'NOMINAL_BORE', 150, ARRAY[14.4,28,50.4,71.2,94.4,122.4,148,175.2,204.8,235.2]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.4', 12, 'PIPE', 'NOMINAL_BORE', 200, ARRAY[17.6,35.2,61.6,87.2,113.6,147.2,176.8,209.6,242.4,276.8]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.4', 13, 'PIPE', 'NOMINAL_BORE', 250, ARRAY[20.8,40.8,70.4,100,126.8,165.6,198.4,234.4,268.8,308]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.4', 14, 'PIPE', 'NOMINAL_BORE', 300, ARRAY[24,47.2,80.8,112,144.8,184.8,222.4,259.2,299.2,340.8]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.4', 15, 'PIPE', 'NOMINAL_BORE', 350, ARRAY[28,52.6,89.6,124,160,204,244,284,327.2,372.8]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.4', 16, 'PIPE', 'NOMINAL_BORE', 400, ARRAY[30.4,58.4,97.6,136,173.6,220.8,264.8,308.8,353.6,401.6]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.4', 17, 'PIPE', 'NOMINAL_BORE', 450, ARRAY[32.8,64,105.6,145.6,186.4,238.4,282.4,329.6,376.8,428]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.4', 18, 'PIPE', 'NOMINAL_BORE', 500, ARRAY[36,70.4,114.4,157.6,200.8,257.6,303.2,353.6,404.8,458.4]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.4', 19, 'PIPE', 'NOMINAL_BORE', 600, ARRAY[42.4,80,132,180,230.4,292,345.6,399.2,456,515.2]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.4', 20, 'PIPE', 'NOMINAL_BORE', 700, ARRAY[48,91.2,147.2,200,255.2,323.2,380,440,500.8,565.6]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.4', 21, 'PIPE', 'NOMINAL_BORE', 800, ARRAY[53.6,102.4,164,222.4,282.4,357.6,420.8,484,550.4,620]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.4', 22, 'PIPE', 'NOMINAL_BORE', 900, ARRAY[60,112.8,180.8,244.8,310.4,389.6,459.2,528,599.2,674.4]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.4', 23, 'PIPE', 'NOMINAL_BORE', 1000, ARRAY[66.4,124,197.6,266.4,336.8,424.8,497.6,572,648,728.8]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.4', 24, 'SURFACE', NULL, NULL, ARRAY[20,35.2,56.8,70.4,86.4,106.4,121.6,132,152,167.2]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], 'Криволинейные поверхности диаметром более 1020 мм и плоские'),
('В.5', 1, 'PIPE', 'NOMINAL_BORE', 15, ARRAY[4,9,17,25,35,45,56,68,81,93]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 2, 'PIPE', 'NOMINAL_BORE', 20, ARRAY[4,10,19,28,39,50,62,75,88,102]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 3, 'PIPE', 'NOMINAL_BORE', 25, ARRAY[5,11,20,31,42,54,67,81,94,110]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 4, 'PIPE', 'NOMINAL_BORE', 32, ARRAY[5,11,21,33,44,57,71,85,99,116]::numeric[], ARRAY[true,true,true,true,true,true,true,true,true,true]::boolean[], NULL),
('В.5', 5, 'PIPE', 'NOMINAL_BORE', 40, ARRAY[5,12,23,35,47,60,75,89,105,122]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 6, 'PIPE', 'NOMINAL_BORE', 50, ARRAY[6,14,26,38,51,66,81,97,114,132]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 7, 'PIPE', 'NOMINAL_BORE', 65, ARRAY[7,16,29,43,58,74,89,107,126,145]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 8, 'PIPE', 'NOMINAL_BORE', 80, ARRAY[8,17,31,46,62,78,95,114,134,154]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 9, 'PIPE', 'NOMINAL_BORE', 100, ARRAY[9,19,34,50,67,85,103,123,145,166]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 10, 'PIPE', 'NOMINAL_BORE', 125, ARRAY[10,21,38,55,74,92,115,137,160,184]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 11, 'PIPE', 'NOMINAL_BORE', 150, ARRAY[11,24,42,61,80,100,126,150,175,201]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 12, 'PIPE', 'NOMINAL_BORE', 200, ARRAY[14,30,52,75,98,121,153,180,210,239]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 13, 'PIPE', 'NOMINAL_BORE', 250, ARRAY[16,35,60,86,113,139,171,202,234,267]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 14, 'PIPE', 'NOMINAL_BORE', 300, ARRAY[18,40,68,97,126,156,189,222,256,293]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 15, 'PIPE', 'NOMINAL_BORE', 350, ARRAY[22,45,76,107,138,172,206,242,276,317]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 16, 'PIPE', 'NOMINAL_BORE', 400, ARRAY[25,49,83,116,151,186,221,260,298,340]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 17, 'PIPE', 'NOMINAL_BORE', 450, ARRAY[27,54,90,126,162,199,237,276,315,362]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 18, 'PIPE', 'NOMINAL_BORE', 500, ARRAY[30,58,97,135,174,214,254,297,340,386]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 19, 'PIPE', 'NOMINAL_BORE', 600, ARRAY[34,67,111,153,196,240,284,331,380,429]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 20, 'PIPE', 'NOMINAL_BORE', 700, ARRAY[38,75,124,169,216,263,312,362,414,468]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 21, 'PIPE', 'NOMINAL_BORE', 800, ARRAY[43,83,137,188,237,289,342,396,452,510]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 22, 'PIPE', 'NOMINAL_BORE', 900, ARRAY[47,91,150,205,259,315,372,430,490,551]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 23, 'PIPE', 'NOMINAL_BORE', 1000, ARRAY[52,100,163,222,282,341,401,464,526,593]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 24, 'PIPE', 'NOMINAL_BORE', 1200, ARRAY[62,117,190,257,324,391,459,528,600,673]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 25, 'PIPE', 'NOMINAL_BORE', 1400, ARRAY[72,133,216,292,365,441,516,591,672,752]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.5', 26, 'SURFACE', NULL, NULL, ARRAY[16,27,42,55,67,78,90,101,111,135]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], 'Криволинейные поверхности диаметром более 1020 мм и плоские'),
('В.6', 1, 'PIPE', 'NOMINAL_BORE', 15, ARRAY[4,10,18,28,38,49,61,74,86,101]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 2, 'PIPE', 'NOMINAL_BORE', 20, ARRAY[5,11,21,31,42,54,67,80,95,111]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 3, 'PIPE', 'NOMINAL_BORE', 25, ARRAY[5,12,23,34,46,59,73,87,103,119]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 4, 'PIPE', 'NOMINAL_BORE', 32, ARRAY[5,13,24,36,49,63,77,92,109,126]::numeric[], ARRAY[true,true,true,true,true,true,true,true,true,true]::boolean[], NULL),
('В.6', 5, 'PIPE', 'NOMINAL_BORE', 40, ARRAY[6,14,26,39,52,67,81,98,115,133]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 6, 'PIPE', 'NOMINAL_BORE', 50, ARRAY[7,16,29,43,57,73,89,106,125,144]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 7, 'PIPE', 'NOMINAL_BORE', 65, ARRAY[8,18,33,48,65,81,99,119,139,160]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 8, 'PIPE', 'NOMINAL_BORE', 80, ARRAY[9,20,36,52,69,87,106,127,148,170]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 9, 'PIPE', 'NOMINAL_BORE', 100, ARRAY[10,22,39,57,75,95,115,137,160,185]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 10, 'PIPE', 'NOMINAL_BORE', 125, ARRAY[12,25,44,63,83,112,135,160,186,213]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 11, 'PIPE', 'NOMINAL_BORE', 150, ARRAY[13,27,48,69,91,122,147,174,202,232]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 12, 'PIPE', 'NOMINAL_BORE', 200, ARRAY[16,34,59,82,108,144,174,204,237,270]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 13, 'PIPE', 'NOMINAL_BORE', 250, ARRAY[19,39,66,94,123,164,197,231,266,303]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 14, 'PIPE', 'NOMINAL_BORE', 300, ARRAY[22,44,75,105,137,182,217,255,293,334]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 15, 'PIPE', 'NOMINAL_BORE', 350, ARRAY[27,53,91,127,162,200,238,279,320,364]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 16, 'PIPE', 'NOMINAL_BORE', 400, ARRAY[30,59,99,138,176,217,257,301,345,391]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 17, 'PIPE', 'NOMINAL_BORE', 450, ARRAY[33,64,108,149,190,233,277,323,369,418]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 18, 'PIPE', 'NOMINAL_BORE', 500, ARRAY[35,70,117,161,205,251,297,346,395,447]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 19, 'PIPE', 'NOMINAL_BORE', 600, ARRAY[41,81,134,184,233,283,335,388,444,500]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 20, 'PIPE', 'NOMINAL_BORE', 700, ARRAY[47,90,149,203,258,312,369,427,486,548]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 21, 'PIPE', 'NOMINAL_BORE', 800, ARRAY[53,102,165,225,285,345,406,468,533,600]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 22, 'PIPE', 'NOMINAL_BORE', 900, ARRAY[59,112,183,248,312,376,442,510,580,651]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 23, 'PIPE', 'NOMINAL_BORE', 1000, ARRAY[64,123,199,269,339,408,479,552,626,702]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 24, 'PIPE', 'NOMINAL_BORE', 1200, ARRAY[75,145,233,313,393,471,551,633,716,796]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 25, 'PIPE', 'NOMINAL_BORE', 1400, ARRAY[86,166,266,356,446,534,623,713,805,890]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], NULL),
('В.6', 26, 'SURFACE', NULL, NULL, ARRAY[20,36,55,71,86,100,113,126,142,159]::numeric[], ARRAY[false,false,false,false,false,false,false,false,false,false]::boolean[], 'Криволинейные поверхности диаметром более 1020 мм и плоские'),
('В.7', 1, NULL, 'OUTER_DIAMETER', 32, ARRAY[9,17]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 2, NULL, 'OUTER_DIAMETER', 33.5, ARRAY[9.4,17.8]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 3, NULL, 'OUTER_DIAMETER', 38, ARRAY[8.8,16.6]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 4, NULL, 'OUTER_DIAMETER', 42.3, ARRAY[9.7,18.4]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 5, NULL, 'OUTER_DIAMETER', 45, ARRAY[10.4,19.7]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 6, NULL, 'OUTER_DIAMETER', 48, ARRAY[11.2,21.2]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 7, NULL, 'OUTER_DIAMETER', 57, ARRAY[11.9,22.4]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 8, NULL, 'OUTER_DIAMETER', 60, ARRAY[12.7,24]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 9, NULL, 'OUTER_DIAMETER', 75.5, ARRAY[15.1,28.5]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 10, NULL, 'OUTER_DIAMETER', 76, ARRAY[15.2,28.8]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 11, NULL, 'OUTER_DIAMETER', 88.5, ARRAY[15.7,29.7]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 12, NULL, 'OUTER_DIAMETER', 89, ARRAY[15.9,30]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 13, NULL, 'OUTER_DIAMETER', 108, ARRAY[15.1,28.6]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 14, NULL, 'OUTER_DIAMETER', 114, ARRAY[16.6,31.3]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 15, NULL, 'OUTER_DIAMETER', 133, ARRAY[17.7,33.5]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 16, NULL, 'OUTER_DIAMETER', 159, ARRAY[20.6,38.9]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 17, NULL, 'OUTER_DIAMETER', 219, ARRAY[25.7,48.5]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 18, NULL, 'OUTER_DIAMETER', 273, ARRAY[24.4,46.1]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 19, NULL, 'OUTER_DIAMETER', 325, ARRAY[28.7,54.1]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 20, NULL, 'OUTER_DIAMETER', 377, ARRAY[33.1,62.5]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 21, NULL, 'OUTER_DIAMETER', 426, ARRAY[34.1,64.5]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 22, NULL, 'OUTER_DIAMETER', 530, ARRAY[31.9,60.3]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 23, NULL, 'OUTER_DIAMETER', 630, ARRAY[39.1,73.8]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 24, NULL, 'OUTER_DIAMETER', 720, ARRAY[42,79.3]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 25, NULL, 'OUTER_DIAMETER', 820, ARRAY[47.2,89.1]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 26, NULL, 'OUTER_DIAMETER', 920, ARRAY[52.4,99]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 27, NULL, 'OUTER_DIAMETER', 1020, ARRAY[57.6,108.9]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 28, NULL, 'OUTER_DIAMETER', 1220, ARRAY[78.6,148.4]::numeric[], ARRAY[false,false]::boolean[], NULL),
('В.7', 29, NULL, 'OUTER_DIAMETER', 1420, ARRAY[90.7,171.3]::numeric[], ARRAY[false,false]::boolean[], NULL);


-- ============================================================
-- 5. КОЛОНКИ / ТЕМПЕРАТУРЫ
-- ============================================================

CREATE TEMP TABLE tmp_v_columns_seed (
    table_code      varchar(10) NOT NULL,
    ordinal_no      integer NOT NULL,
    temperature_c   numeric NOT NULL,
    PRIMARY KEY (table_code, ordinal_no)
) ON COMMIT DROP;

INSERT INTO tmp_v_columns_seed VALUES
('В.1',1,50),('В.1',2,100),('В.1',3,200),('В.1',4,300),('В.1',5,400),('В.1',6,500),
('В.2',1,50),('В.2',2,100),('В.2',3,200),('В.2',4,300),('В.2',5,400),('В.2',6,500),

('В.3',1,20),('В.3',2,50),('В.3',3,100),('В.3',4,150),('В.3',5,200),
('В.3',6,250),('В.3',7,300),('В.3',8,350),('В.3',9,400),('В.3',10,450),

('В.4',1,20),('В.4',2,50),('В.4',3,100),('В.4',4,150),('В.4',5,200),
('В.4',6,250),('В.4',7,300),('В.4',8,350),('В.4',9,400),('В.4',10,450),

('В.5',1,20),('В.5',2,50),('В.5',3,100),('В.5',4,150),('В.5',5,200),
('В.5',6,250),('В.5',7,300),('В.5',8,350),('В.5',9,400),('В.5',10,450),

('В.6',1,20),('В.6',2,50),('В.6',3,100),('В.6',4,150),('В.6',5,200),
('В.6',6,250),('В.6',7,300),('В.6',8,350),('В.6',9,400),('В.6',10,450),

('В.7',1,50),('В.7',2,90);


-- ============================================================
-- 6. ОЧИЩАЕМ СТАРЫЕ ЗНАЧЕНИЯ
-- ============================================================

DELETE FROM qh_values
WHERE row_id IN (
    SELECT r.id
    FROM qh_rows r
    JOIN qh_tables t ON t.id = r.table_id
    WHERE t.code IN ('В.1','В.2','В.3','В.4','В.5','В.6','В.7')
);

DELETE FROM qh_row_dimension_values
WHERE row_id IN (
    SELECT r.id
    FROM qh_rows r
    JOIN qh_tables t ON t.id = r.table_id
    WHERE t.code IN ('В.1','В.2','В.3','В.4','В.5','В.6','В.7')
);


-- ============================================================
-- 7. qh_rows
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
    s.note,
    true
FROM tmp_v_rows_seed s
JOIN qh_tables t
    ON t.code = s.table_code
ON CONFLICT (table_id, source_row_no)
DO UPDATE SET
    note = EXCLUDED.note,
    is_active = true;

-- Если в БД случайно остались старые строки, которых нет в источнике,
-- они не должны участвовать в выборе.
UPDATE qh_rows r
SET is_active = false
FROM qh_tables t
WHERE t.id = r.table_id
  AND t.code IN ('В.1','В.2','В.3','В.4','В.5','В.6','В.7')
  AND NOT EXISTS (
      SELECT 1
      FROM tmp_v_rows_seed s
      WHERE s.table_code = t.code
        AND s.source_row_no = r.source_row_no
  );


-- ============================================================
-- 8. qh_row_dimension_values
-- ============================================================

-- Основная числовая характеристика строки:
-- OUTER_DIAMETER либо NOMINAL_BORE.
INSERT INTO qh_row_dimension_values (
    row_id,
    dimension_id,
    value_numeric,
    value_text
)
SELECT
    r.id,
    d.id,
    s.dimension_value,
    NULL
FROM tmp_v_rows_seed s
JOIN qh_tables t
    ON t.code = s.table_code
JOIN qh_rows r
    ON r.table_id = t.id
   AND r.source_row_no = s.source_row_no
JOIN qh_dimensions d
    ON d.code = s.dimension_code
WHERE s.dimension_code IS NOT NULL
  AND s.dimension_value IS NOT NULL;

-- В.3 - В.6: PIPE / SURFACE.
INSERT INTO qh_row_dimension_values (
    row_id,
    dimension_id,
    value_numeric,
    value_text
)
SELECT
    r.id,
    d.id,
    NULL,
    s.object_kind
FROM tmp_v_rows_seed s
JOIN qh_tables t
    ON t.code = s.table_code
JOIN qh_rows r
    ON r.table_id = t.id
   AND r.source_row_no = s.source_row_no
JOIN qh_dimensions d
    ON d.code = 'OBJECT_KIND'
WHERE s.object_kind IS NOT NULL;


-- ============================================================
-- 9. qh_values
-- ============================================================

WITH cells AS (
    SELECT
        s.table_code,
        s.source_row_no,
        s.object_kind,
        u.ordinality::integer AS ordinal_no,
        u.qh_value,
        s.interpolated[u.ordinality::integer] AS source_interpolated
    FROM tmp_v_rows_seed s
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
    'SINGLE',
    NULL,
    CASE
        WHEN cells.object_kind = 'SURFACE' THEN 'SURFACE'
        ELSE 'LINEAR'
    END,
    c.temperature_c,
    NULL,
    NULL,
    cells.qh_value,
    cells.source_interpolated,
    NULL
FROM cells
JOIN tmp_v_columns_seed c
    ON c.table_code = cells.table_code
   AND c.ordinal_no = cells.ordinal_no
JOIN qh_tables t
    ON t.code = cells.table_code
JOIN qh_rows r
    ON r.table_id = t.id
   AND r.source_row_no = cells.source_row_no;


-- ============================================================
-- 10. ПРОВЕРКА
-- ============================================================

-- Ожидаемые qh_rows:
-- В.1 = 29
-- В.2 = 29
-- В.3 = 24 (23 PIPE + 1 SURFACE)
-- В.4 = 24 (23 PIPE + 1 SURFACE)
-- В.5 = 26 (25 PIPE + 1 SURFACE)
-- В.6 = 26 (25 PIPE + 1 SURFACE)
-- В.7 = 29
-- ИТОГО = 187

SELECT
    t.code,
    count(*) AS rows_count
FROM qh_rows r
JOIN qh_tables t
    ON t.id = r.table_id
WHERE t.code IN ('В.1','В.2','В.3','В.4','В.5','В.6','В.7')
  AND r.is_active = true
GROUP BY t.code
ORDER BY t.code;


-- Ожидаемые qh_values:
-- В.1 = 174
-- В.2 = 174
-- В.3 = 240
-- В.4 = 240
-- В.5 = 260
-- В.6 = 260
-- В.7 = 58
-- ИТОГО = 1406

SELECT
    t.code,
    count(*) AS values_count
FROM qh_values v
JOIN qh_rows r
    ON r.id = v.row_id
JOIN qh_tables t
    ON t.id = r.table_id
WHERE t.code IN ('В.1','В.2','В.3','В.4','В.5','В.6','В.7')
GROUP BY t.code
ORDER BY t.code;


-- LINEAR / SURFACE отдельно:
SELECT
    t.code,
    v.density_kind,
    count(*) AS values_count
FROM qh_values v
JOIN qh_rows r
    ON r.id = v.row_id
JOIN qh_tables t
    ON t.id = r.table_id
WHERE t.code IN ('В.1','В.2','В.3','В.4','В.5','В.6','В.7')
GROUP BY t.code, v.density_kind
ORDER BY t.code, v.density_kind;


COMMIT;
