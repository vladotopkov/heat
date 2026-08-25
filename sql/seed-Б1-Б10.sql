BEGIN;

-- ============================================================
-- Б.1 - Б.10
--
-- Б.1       OUTER_DIAMETER + SINGLE + 50/65/70
-- Б.2       OUTER_DIAMETER + RETURN/SUPPLY/TOTAL
-- Б.3-Б.6   NOMINAL_BORE   + RETURN/SUPPLY/TOTAL
-- Б.7       NOMINAL_BORE   + RETURN/SUPPLY/TOTAL
-- Б.8       коэффициенты Кт
-- Б.9       NOMINAL_BORE   + RETURN/SUPPLY/TOTAL
-- Б.10      коэффициенты Кт
-- ============================================================


-- ============================================================
-- 1. ПРОВЕРКА НЕОБХОДИМЫХ DIMENSIONS
-- ============================================================

DO $$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM qh_dimensions
        WHERE code = 'OUTER_DIAMETER'
    ) THEN
        RAISE EXCEPTION 'Dimension OUTER_DIAMETER отсутствует';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM qh_dimensions
        WHERE code = 'NOMINAL_BORE'
    ) THEN
        RAISE EXCEPTION 'Dimension NOMINAL_BORE отсутствует';
    END IF;

END $$;


-- ============================================================
-- 2. НАСТРАИВАЕМ DIMENSIONS ТАБЛИЦ
-- ============================================================

DELETE FROM qh_table_dimensions
WHERE table_id IN (
    SELECT id
    FROM qh_tables
    WHERE code IN (
        'Б.1',
        'Б.2',
        'Б.3',
        'Б.4',
        'Б.5',
        'Б.6',
        'Б.7',
        'Б.9'
    )
);


-- Б.1 / Б.2 -> наружный диаметр

INSERT INTO qh_table_dimensions (
    table_id,
    dimension_id,
    sequence_no,
    is_selector
)
SELECT
    t.id,
    d.id,
    1,
    true
FROM qh_tables t
JOIN qh_dimensions d
    ON d.code = 'OUTER_DIAMETER'
WHERE t.code IN (
    'Б.1',
    'Б.2'
);


-- Б.3-Б.7 / Б.9 -> условный проход

INSERT INTO qh_table_dimensions (
    table_id,
    dimension_id,
    sequence_no,
    is_selector
)
SELECT
    t.id,
    d.id,
    1,
    true
FROM qh_tables t
JOIN qh_dimensions d
    ON d.code = 'NOMINAL_BORE'
WHERE t.code IN (
    'Б.3',
    'Б.4',
    'Б.5',
    'Б.6',
    'Б.7',
    'Б.9'
);


-- ============================================================
-- 3. ВРЕМЕННАЯ ТАБЛИЦА ИСХОДНЫХ СТРОК
-- ============================================================

CREATE TEMP TABLE tmp_qh_rows_seed (
    table_code          varchar(10) NOT NULL,
    source_row_no       integer NOT NULL,
    dimension_code      varchar(60) NOT NULL,
    dimension_value     numeric NOT NULL,
    qh_values           numeric[] NOT NULL,
    interpolated        boolean[] NOT NULL
) ON COMMIT DROP;


-- ============================================================
-- Б.1
-- OUTER_DIAMETER
-- 50 / 65 / 70
-- ============================================================

INSERT INTO tmp_qh_rows_seed VALUES

('Б.1',  1, 'OUTER_DIAMETER', 18,  ARRAY[12.8,17.5,19.5], ARRAY[true,true,true]),
('Б.1',  2, 'OUTER_DIAMETER', 21,  ARRAY[13.7,18.5,20.6], ARRAY[true,true,true]),
('Б.1',  3, 'OUTER_DIAMETER', 25,  ARRAY[15.0,20.0,22.0], ARRAY[true,true,true]),
('Б.1',  4, 'OUTER_DIAMETER', 27,  ARRAY[15.7,20.6,22.8], ARRAY[true,true,true]),
('Б.1',  5, 'OUTER_DIAMETER', 32,  ARRAY[17.2,23.3,24.4], ARRAY[false,false,false]),
('Б.1',  6, 'OUTER_DIAMETER', 34,  ARRAY[17.8,23.0,25.2], ARRAY[true,true,true]),
('Б.1',  7, 'OUTER_DIAMETER', 38,  ARRAY[19.2,24.4,26.7], ARRAY[false,false,false]),
('Б.1',  8, 'OUTER_DIAMETER', 42,  ARRAY[20.2,25.7,27.9], ARRAY[true,true,true]),
('Б.1',  9, 'OUTER_DIAMETER', 45,  ARRAY[20.9,26.7,29.1], ARRAY[false,false,false]),
('Б.1', 10, 'OUTER_DIAMETER', 48,  ARRAY[21.9,27.6,30.0], ARRAY[true,true,true]),
('Б.1', 11, 'OUTER_DIAMETER', 57,  ARRAY[24.4,30.2,32.6], ARRAY[false,false,false]),
('Б.1', 12, 'OUTER_DIAMETER', 76,  ARRAY[29.1,36.1,38.4], ARRAY[false,false,false]),
('Б.1', 13, 'OUTER_DIAMETER', 89,  ARRAY[32.6,39.5,41.9], ARRAY[false,false,false]),
('Б.1', 14, 'OUTER_DIAMETER', 108, ARRAY[36.1,44.2,46.5], ARRAY[false,false,false]),
('Б.1', 15, 'OUTER_DIAMETER', 114, ARRAY[37.2,45.3,47.9], ARRAY[true,true,true]),
('Б.1', 16, 'OUTER_DIAMETER', 133, ARRAY[40.7,48.8,52.3], ARRAY[false,false,false]),
('Б.1', 17, 'OUTER_DIAMETER', 159, ARRAY[44.2,52.3,55.8], ARRAY[false,false,false]),
('Б.1', 18, 'OUTER_DIAMETER', 194, ARRAY[48.8,59.3,62.8], ARRAY[false,false,false]),
('Б.1', 19, 'OUTER_DIAMETER', 219, ARRAY[53.5,62.8,66.3], ARRAY[false,false,false]),
('Б.1', 20, 'OUTER_DIAMETER', 273, ARRAY[61.6,73.3,77.9], ARRAY[false,false,false]),
('Б.1', 21, 'OUTER_DIAMETER', 325, ARRAY[69.8,84.9,89.6], ARRAY[false,false,false]),
('Б.1', 22, 'OUTER_DIAMETER', 377, ARRAY[82.6,96.5,102.3],ARRAY[false,false,false]),
('Б.1', 23, 'OUTER_DIAMETER', 426, ARRAY[95.4,111.6,116.3],ARRAY[false,false,false]),
('Б.1', 24, 'OUTER_DIAMETER', 478, ARRAY[103.5,121.0,126.8],ARRAY[false,false,false]),
('Б.1', 25, 'OUTER_DIAMETER', 529, ARRAY[110.5,127.9,133.7],ARRAY[false,false,false]),
('Б.1', 26, 'OUTER_DIAMETER', 630, ARRAY[121.0,140.7,146.5],ARRAY[false,false,false]),
('Б.1', 27, 'OUTER_DIAMETER', 720, ARRAY[133.7,154.7,161.7],ARRAY[false,false,false]),
('Б.1', 28, 'OUTER_DIAMETER', 820, ARRAY[157.0,180.3,187.2],ARRAY[false,false,false]);


-- ============================================================
-- Б.2
-- OUTER_DIAMETER
-- RETURN50 / SUPPLY65 / TOTAL65-50 /
-- SUPPLY90 / TOTAL90-50 /
-- SUPPLY110 / TOTAL110-50
-- ============================================================

INSERT INTO tmp_qh_rows_seed VALUES

('Б.2',1,'OUTER_DIAMETER',18,
 ARRAY[17.9,23.7,41.6,31.8,49.7,36.0,53.9],
 ARRAY[true,true,true,true,true,true,true]),

('Б.2',2,'OUTER_DIAMETER',21,
 ARRAY[19.1,24.9,44.0,33.0,52.1,37.8,56.9],
 ARRAY[true,true,true,true,true,true,true]),

('Б.2',3,'OUTER_DIAMETER',25,
 ARRAY[20.6,26.4,47.0,34.5,55.1,40.1,60.7],
 ARRAY[true,true,true,true,true,true,true]),

('Б.2',4,'OUTER_DIAMETER',27,
 ARRAY[21.4,27.2,48.6,35.3,56.7,41.3,62.7],
 ARRAY[true,true,true,true,true,true,true]),

('Б.2',5,'OUTER_DIAMETER',32,
 ARRAY[23.3,29.1,52.4,37.2,60.5,44.2,67.5],
 ARRAY[false,false,false,false,false,false,false]),

('Б.2',6,'OUTER_DIAMETER',34,
 ARRAY[24.1,29.9,54.0,38.0,62.1,45.4,69.5],
 ARRAY[true,true,true,true,true,true,true]),

('Б.2',7,'OUTER_DIAMETER',38,
 ARRAY[25.6,31.4,57.0,39.5,65.1,47.7,73.3],
 ARRAY[false,false,false,false,false,false,false]),

('Б.2',8,'OUTER_DIAMETER',42,
 ARRAY[26.5,32.3,58.8,40.9,67.4,49.1,75.6],
 ARRAY[true,true,true,true,true,true,true]),

('Б.2',9,'OUTER_DIAMETER',45,
 ARRAY[27.2,33.0,60.2,42.0,69.2,50.2,77.4],
 ARRAY[true,true,true,true,true,true,true]),

('Б.2',10,'OUTER_DIAMETER',48,
 ARRAY[27.9,33.7,61.6,43.0,70.9,51.2,79.1],
 ARRAY[false,false,false,false,false,false,false]),

('Б.2',11,'OUTER_DIAMETER',57,
 ARRAY[29.1,36.1,65.2,46.5,75.6,54.7,83.8],
 ARRAY[false,false,false,false,false,false,false]),

('Б.2',12,'OUTER_DIAMETER',76,
 ARRAY[33.7,40.7,74.4,52.3,86.0,61.6,95.3],
 ARRAY[false,false,false,false,false,false,false]),

('Б.2',13,'OUTER_DIAMETER',89,
 ARRAY[36.1,44.2,80.3,57.0,93.1,66.3,102.4],
 ARRAY[false,false,false,false,false,false,false]),

('Б.2',14,'OUTER_DIAMETER',108,
 ARRAY[39.5,48.8,88.3,62.8,102.3,72.1,111.6],
 ARRAY[false,false,false,false,false,false,false]),

('Б.2',15,'OUTER_DIAMETER',114,
 ARRAY[40.6,50.2,90.8,64.5,105.1,74.0,114.6],
 ARRAY[true,true,true,true,true,true,true]),

('Б.2',16,'OUTER_DIAMETER',133,
 ARRAY[44.2,54.7,98.9,69.8,114.0,80.2,124.4],
 ARRAY[false,false,false,false,false,false,false]),

('Б.2',17,'OUTER_DIAMETER',159,
 ARRAY[48.8,60.5,109.3,75.6,124.4,87.2,136.0],
 ARRAY[false,false,false,false,false,false,false]),

('Б.2',18,'OUTER_DIAMETER',219,
 ARRAY[59.3,72.1,131.4,91.9,151.2,105.8,165.1],
 ARRAY[false,false,false,false,false,false,false]),

('Б.2',19,'OUTER_DIAMETER',273,
 ARRAY[69.8,83.7,153.5,104.7,174.5,119.8,189.6],
 ARRAY[false,false,false,false,false,false,false]),

('Б.2',20,'OUTER_DIAMETER',325,
 ARRAY[79.1,94.2,173.3,116.3,195.4,133.7,212.8],
 ARRAY[false,false,false,false,false,false,false]),

('Б.2',21,'OUTER_DIAMETER',377,
 ARRAY[88.4,104.7,193.1,124.4,212.8,146.5,234.9],
 ARRAY[false,false,false,false,false,false,false]),

('Б.2',22,'OUTER_DIAMETER',426,
 ARRAY[95.4,114.6,210.0,140.7,236.1,159.3,254.7],
 ARRAY[false,true,true,false,false,false,false]),

('Б.2',23,'OUTER_DIAMETER',478,
 ARRAY[105.8,125.0,230.9,153.5,259.3,174.5,280.3],
 ARRAY[false,true,true,false,false,false,false]),

('Б.2',24,'OUTER_DIAMETER',529,
 ARRAY[117.5,135.3,252.8,165.1,282.6,186.1,303.6],
 ARRAY[false,true,true,false,false,false,false]),

('Б.2',25,'OUTER_DIAMETER',630,
 ARRAY[132.6,155.6,288.2,189.6,322.2,214.0,346.6],
 ARRAY[false,true,true,false,false,false,false]),

('Б.2',26,'OUTER_DIAMETER',720,
 ARRAY[145.4,173.8,319.2,210.5,355.9,234.9,380.3],
 ARRAY[false,true,true,false,false,false,false]),

('Б.2',27,'OUTER_DIAMETER',820,
 ARRAY[164.0,193.9,357.9,232.6,396.6,259.3,423.3],
 ARRAY[false,true,true,false,false,false,false]),

('Б.2',28,'OUTER_DIAMETER',920,
 ARRAY[180.3,214.0,394.3,253.5,433.8,283.8,464.1],
 ARRAY[false,true,true,false,false,false,false]),

('Б.2',29,'OUTER_DIAMETER',1020,
 ARRAY[197.7,234.1,431.8,279.1,476.8,309.4,507.1],
 ARRAY[false,true,true,false,false,false,false]);


-- ============================================================
-- Б.3
-- ============================================================

INSERT INTO tmp_qh_rows_seed VALUES

('Б.3',1,'NOMINAL_BORE',15,ARRAY[6.7,10.2,16.9,15.1,21.1,17.6,22.9],ARRAY[true,true,true,true,true,true,true]),
('Б.3',2,'NOMINAL_BORE',20,ARRAY[7.2,10.7,17.9,15.6,22.1,18.6,24.4],ARRAY[true,true,true,true,true,true,true]),
('Б.3',3,'NOMINAL_BORE',25,ARRAY[7.7,11.2,18.9,16.1,23.1,19.6,25.9],ARRAY[false,false,false,false,false,false,false]),
('Б.3',4,'NOMINAL_BORE',32,ARRAY[8.4,11.9,20.3,16.8,24.5,21.0,28.0],ARRAY[false,false,false,false,false,false,false]),
('Б.3',5,'NOMINAL_BORE',40,ARRAY[9.1,12.6,21.7,18.2,26.6,22.4,30.1],ARRAY[false,false,false,false,false,false,false]),
('Б.3',6,'NOMINAL_BORE',50,ARRAY[9.8,14.0,23.8,19.6,28.7,24.5,32.9],ARRAY[false,false,false,false,false,false,false]),
('Б.3',7,'NOMINAL_BORE',65,ARRAY[11.2,16.1,27.3,23.8,34.3,28.0,37.1],ARRAY[false,false,false,false,false,false,false]),
('Б.3',8,'NOMINAL_BORE',80,ARRAY[11.9,17.5,29.4,25.2,36.4,30.8,40.6],ARRAY[false,false,false,false,false,false,false]),
('Б.3',9,'NOMINAL_BORE',100,ARRAY[13.3,19.6,32.9,28.7,40.6,33.6,44.1],ARRAY[false,false,false,false,false,false,false]),
('Б.3',10,'NOMINAL_BORE',125,ARRAY[14.7,21.7,36.4,29.4,42.0,35.0,46.2],ARRAY[false,false,false,false,false,false,false]),
('Б.3',11,'NOMINAL_BORE',150,ARRAY[15.4,22.4,37.8,30.8,44.1,38.5,50.4],ARRAY[false,false,false,false,false,false,false]),
('Б.3',12,'NOMINAL_BORE',200,ARRAY[18.9,27.3,46.2,37.8,53.2,47.6,62.3],ARRAY[false,false,false,false,false,false,false]),
('Б.3',13,'NOMINAL_BORE',250,ARRAY[21.0,31.5,52.5,44.8,62.3,53.9,70.0],ARRAY[false,false,false,false,false,false,false]),
('Б.3',14,'NOMINAL_BORE',300,ARRAY[23.1,35.0,58.1,49.0,68.6,58.8,76.3],ARRAY[false,false,false,false,false,false,false]),
('Б.3',15,'NOMINAL_BORE',350,ARRAY[25.9,38.5,64.4,52.5,73.5,65.8,84.0],ARRAY[false,false,false,false,false,false,false]),
('Б.3',16,'NOMINAL_BORE',400,ARRAY[26.6,40.6,67.2,57.4,80.5,70.7,90.3],ARRAY[false,false,false,false,false,false,false]),
('Б.3',17,'NOMINAL_BORE',450,ARRAY[30.1,46.9,77.0,65.1,90.3,74.9,95.2],ARRAY[false,false,false,false,false,false,false]),
('Б.3',18,'NOMINAL_BORE',500,ARRAY[30.8,47.6,78.4,68.6,95.2,81.9,104.3],ARRAY[false,false,false,false,false,false,false]),
('Б.3',19,'NOMINAL_BORE',600,ARRAY[35.0,55.3,90.3,76.3,105.0,92.4,116.2],ARRAY[false,false,false,false,false,false,false]),
('Б.3',20,'NOMINAL_BORE',700,ARRAY[38.5,62.3,100.8,88.2,118.3,105.7,131.6],ARRAY[false,false,false,false,false,false,false]),
('Б.3',21,'NOMINAL_BORE',800,ARRAY[42.0,70.0,112.0,98.0,129.5,114.1,142.1],ARRAY[false,false,false,false,false,false,false]),
('Б.3',22,'NOMINAL_BORE',900,ARRAY[46.2,74.2,120.4,105.7,143.5,130.2,160.3],ARRAY[false,false,false,false,false,false,false]),
('Б.3',23,'NOMINAL_BORE',1000,ARRAY[49.7,81.9,131.6,110.6,150.5,134.4,167.3],ARRAY[false,false,false,false,false,false,false]),
('Б.3',24,'NOMINAL_BORE',1200,ARRAY[55.3,100.8,156.1,129.5,174.3,160.3,196.7],ARRAY[false,false,false,false,false,false,false]),
('Б.3',25,'NOMINAL_BORE',1400,ARRAY[57.4,106.4,163.8,147.0,194.6,176.4,215.6],ARRAY[false,false,false,false,false,false,false]);


-- ============================================================
-- Б.4
-- ============================================================

INSERT INTO tmp_qh_rows_seed VALUES

('Б.4',1,'NOMINAL_BORE',15,ARRAY[7.4,11.6,19.0,17.2,23.9,19.7,25.7],ARRAY[true,true,true,true,true,true,true]),
('Б.4',2,'NOMINAL_BORE',20,ARRAY[7.9,12.1,20.0,17.7,24.9,20.7,27.2],ARRAY[true,true,true,true,true,true,true]),
('Б.4',3,'NOMINAL_BORE',25,ARRAY[8.4,12.6,21.0,18.2,25.9,21.7,26.7],ARRAY[false,false,false,false,false,false,false]),
('Б.4',4,'NOMINAL_BORE',32,ARRAY[9.1,13.3,22.4,18.9,27.3,23.1,30.8],ARRAY[false,false,false,false,false,false,false]),
('Б.4',5,'NOMINAL_BORE',40,ARRAY[9.8,14.7,24.5,20.3,29.4,25.2,33.6],ARRAY[false,false,false,false,false,false,false]),
('Б.4',6,'NOMINAL_BORE',50,ARRAY[10.5,15.4,25.9,23.1,32.9,28.0,37.1],ARRAY[false,false,false,false,false,false,false]),
('Б.4',7,'NOMINAL_BORE',65,ARRAY[13.3,18.9,32.2,26.6,37.8,32.9,42.7],ARRAY[false,false,false,false,false,false,false]),
('Б.4',8,'NOMINAL_BORE',80,ARRAY[14.0,20.3,34.3,28.7,40.6,35.7,46.2],ARRAY[false,false,false,false,false,false,false]),
('Б.4',9,'NOMINAL_BORE',100,ARRAY[16.4,23.1,38.5,32.2,45.5,39.9,51.8],ARRAY[false,false,false,false,false,false,false]),
('Б.4',10,'NOMINAL_BORE',125,ARRAY[16.1,23.8,39.9,34.3,46.3,42.7,55.3],ARRAY[false,false,false,false,false,false,false]),
('Б.4',11,'NOMINAL_BORE',150,ARRAY[18.2,26.6,44.8,37.8,53.2,45.5,59.8],ARRAY[false,false,false,false,false,false,false]),
('Б.4',12,'NOMINAL_BORE',200,ARRAY[21.7,33.6,55.3,46.2,64.4,58.1,74.2],ARRAY[false,false,false,false,false,false,false]),
('Б.4',13,'NOMINAL_BORE',250,ARRAY[24.5,37.8,62.3,53.2,73.5,65.1,82.7],ARRAY[false,false,false,false,false,false,false]),
('Б.4',14,'NOMINAL_BORE',300,ARRAY[28.0,43.4,71.4,60.9,83.3,72.1,91.7],ARRAY[false,false,false,false,false,false,false]),
('Б.4',15,'NOMINAL_BORE',350,ARRAY[30.8,47.6,78.4,65.1,88.9,81.9,102.2],ARRAY[false,false,false,false,false,false,false]),
('Б.4',16,'NOMINAL_BORE',400,ARRAY[32.9,53.2,86.1,76.3,102.2,86.1,107.1],ARRAY[false,false,false,false,false,false,false]),
('Б.4',17,'NOMINAL_BORE',450,ARRAY[34.3,53.9,88.2,78.4,105.7,94.5,116.9],ARRAY[false,false,false,false,false,false,false]),
('Б.4',18,'NOMINAL_BORE',500,ARRAY[37.6,61.6,99.4,88.2,118.3,116.9,140.0],ARRAY[false,false,false,false,false,false,false]),
('Б.4',19,'NOMINAL_BORE',600,ARRAY[40.6,68.6,109.2,98.0,129.5,119.7,144.2],ARRAY[false,false,false,false,false,false,false]),
('Б.4',20,'NOMINAL_BORE',700,ARRAY[44.1,74.9,119.0,114.1,147.0,129.5,156.1],ARRAY[false,false,false,false,false,false,false]),
('Б.4',21,'NOMINAL_BORE',800,ARRAY[50.4,91.0,141.4,126.7,160.3,149.1,178.5],ARRAY[false,false,false,false,false,false,false]),
('Б.4',22,'NOMINAL_BORE',900,ARRAY[52.5,96.6,149.1,133.0,172.9,163.8,194.6],ARRAY[false,false,false,false,false,false,false]),
('Б.4',23,'NOMINAL_BORE',1000,ARRAY[54.6,106.4,161.0,139.3,180.6,174.3,208.6],ARRAY[false,false,false,false,false,false,false]),
('Б.4',24,'NOMINAL_BORE',1200,ARRAY[60.2,129.5,189.7,179.9,226.1,210.0,247.8],ARRAY[false,false,false,false,false,false,false]),
('Б.4',25,'NOMINAL_BORE',1400,ARRAY[63.0,142.8,205.8,198.8,247.1,225.4,266.0],ARRAY[false,false,false,false,false,false,false]);


-- ============================================================
-- Б.5
-- ============================================================

INSERT INTO tmp_qh_rows_seed VALUES

('Б.5',1,'NOMINAL_BORE',15,ARRAY[6,8,14,10,16,13,19],ARRAY[true,true,true,true,true,true,true]),
('Б.5',2,'NOMINAL_BORE',20,ARRAY[7,9,16,12,19,16,23],ARRAY[true,true,true,true,true,true,true]),
('Б.5',3,'NOMINAL_BORE',25,ARRAY[8,11,19,16,23,19,25],ARRAY[false,false,false,false,false,false,false]),
('Б.5',4,'NOMINAL_BORE',32,ARRAY[8,12,20,16,24,20,27],ARRAY[false,false,false,false,false,false,false]),
('Б.5',5,'NOMINAL_BORE',40,ARRAY[9,12,21,18,26,22,30],ARRAY[false,false,false,false,false,false,false]),
('Б.5',6,'NOMINAL_BORE',50,ARRAY[10,14,24,19,28,24,32],ARRAY[false,false,false,false,false,false,false]),
('Б.5',7,'NOMINAL_BORE',65,ARRAY[11,16,27,23,33,27,36],ARRAY[false,false,false,false,false,false,false]),
('Б.5',8,'NOMINAL_BORE',80,ARRAY[12,17,29,24,35,30,40],ARRAY[false,false,false,false,false,false,false]),
('Б.5',9,'NOMINAL_BORE',100,ARRAY[13,19,32,28,40,32,42],ARRAY[false,false,false,false,false,false,false]),
('Б.5',10,'NOMINAL_BORE',125,ARRAY[14,21,35,28,40,33,44],ARRAY[false,false,false,false,false,false,false]),
('Б.5',11,'NOMINAL_BORE',150,ARRAY[15,22,37,30,43,37,49],ARRAY[false,false,false,false,false,false,false]),
('Б.5',12,'NOMINAL_BORE',200,ARRAY[18,26,44,36,51,45,59],ARRAY[false,false,false,false,false,false,false]),
('Б.5',13,'NOMINAL_BORE',250,ARRAY[20,30,50,43,60,51,67],ARRAY[false,false,false,false,false,false,false]),
('Б.5',14,'NOMINAL_BORE',300,ARRAY[22,33,55,47,66,56,72],ARRAY[false,false,false,false,false,false,false]),
('Б.5',15,'NOMINAL_BORE',350,ARRAY[25,37,62,50,70,63,81],ARRAY[false,false,false,false,false,false,false]),
('Б.5',16,'NOMINAL_BORE',400,ARRAY[26,39,65,55,77,67,86],ARRAY[false,false,false,false,false,false,false]),
('Б.5',17,'NOMINAL_BORE',450,ARRAY[29,45,74,62,86,71,91],ARRAY[false,false,false,false,false,false,false]),
('Б.5',18,'NOMINAL_BORE',500,ARRAY[30,46,76,65,91,76,100],ARRAY[false,false,false,false,false,false,false]),
('Б.5',19,'NOMINAL_BORE',600,ARRAY[33,53,86,73,101,88,111],ARRAY[false,false,false,false,false,false,false]),
('Б.5',20,'NOMINAL_BORE',700,ARRAY[37,59,96,84,113,101,126],ARRAY[false,false,false,false,false,false,false]),
('Б.5',21,'NOMINAL_BORE',800,ARRAY[40,67,107,93,123,108,135],ARRAY[false,false,false,false,false,false,false]),
('Б.5',22,'NOMINAL_BORE',900,ARRAY[44,71,115,99,135,122,151],ARRAY[false,false,false,false,false,false,false]),
('Б.5',23,'NOMINAL_BORE',1000,ARRAY[46,78,126,104,142,127,159],ARRAY[false,false,false,false,false,false,false]),
('Б.5',24,'NOMINAL_BORE',1200,ARRAY[53,95,148,122,165,152,187],ARRAY[false,false,false,false,false,false,false]),
('Б.5',25,'NOMINAL_BORE',1400,ARRAY[55,101,156,140,186,167,205],ARRAY[false,false,false,false,false,false,false]);


-- ============================================================
-- Б.6
-- ============================================================

INSERT INTO tmp_qh_rows_seed VALUES

('Б.6',1,'NOMINAL_BORE',15,ARRAY[5,8,13,12,17,14,19],ARRAY[true,true,true,true,true,true,true]),
('Б.6',2,'NOMINAL_BORE',20,ARRAY[6,9,15,14,20,16,22],ARRAY[true,true,true,true,true,true,true]),
('Б.6',3,'NOMINAL_BORE',25,ARRAY[8,12,20,18,26,21,28],ARRAY[false,false,false,false,false,false,false]),
('Б.6',4,'NOMINAL_BORE',32,ARRAY[9,13,22,18,26,22,30],ARRAY[false,false,false,false,false,false,false]),
('Б.6',5,'NOMINAL_BORE',40,ARRAY[10,14,24,20,29,24,32],ARRAY[false,false,false,false,false,false,false]),
('Б.6',6,'NOMINAL_BORE',50,ARRAY[10,15,25,22,32,27,36],ARRAY[false,false,false,false,false,false,false]),
('Б.6',7,'NOMINAL_BORE',65,ARRAY[13,18,31,25,36,31,41],ARRAY[false,false,false,false,false,false,false]),
('Б.6',8,'NOMINAL_BORE',80,ARRAY[14,20,34,27,39,34,44],ARRAY[false,false,false,false,false,false,false]),
('Б.6',9,'NOMINAL_BORE',100,ARRAY[15,22,37,31,44,38,50],ARRAY[false,false,false,false,false,false,false]),
('Б.6',10,'NOMINAL_BORE',125,ARRAY[16,23,39,33,47,41,53],ARRAY[false,false,false,false,false,false,false]),
('Б.6',11,'NOMINAL_BORE',150,ARRAY[18,25,43,36,51,43,56],ARRAY[false,false,false,false,false,false,false]),
('Б.6',12,'NOMINAL_BORE',200,ARRAY[21,32,53,44,62,55,71],ARRAY[false,false,false,false,false,false,false]),
('Б.6',13,'NOMINAL_BORE',250,ARRAY[23,36,59,50,70,62,79],ARRAY[false,false,false,false,false,false,false]),
('Б.6',14,'NOMINAL_BORE',300,ARRAY[27,41,68,56,79,68,87],ARRAY[false,false,false,false,false,false,false]),
('Б.6',15,'NOMINAL_BORE',350,ARRAY[29,45,74,61,84,77,97],ARRAY[false,false,false,false,false,false,false]),
('Б.6',16,'NOMINAL_BORE',400,ARRAY[31,50,81,72,97,81,101],ARRAY[false,false,false,false,false,false,false]),
('Б.6',17,'NOMINAL_BORE',450,ARRAY[33,51,84,74,100,89,110],ARRAY[false,false,false,false,false,false,false]),
('Б.6',18,'NOMINAL_BORE',500,ARRAY[36,58,94,83,112,110,132],ARRAY[false,false,false,false,false,false,false]),
('Б.6',19,'NOMINAL_BORE',600,ARRAY[39,65,104,92,122,113,136],ARRAY[false,false,false,false,false,false,false]),
('Б.6',20,'NOMINAL_BORE',700,ARRAY[42,71,113,107,138,122,147],ARRAY[false,false,false,false,false,false,false]),
('Б.6',21,'NOMINAL_BORE',800,ARRAY[48,86,134,119,151,140,168],ARRAY[false,false,false,false,false,false,false]),
('Б.6',22,'NOMINAL_BORE',900,ARRAY[50,91,141,125,163,153,182],ARRAY[false,false,false,false,false,false,false]),
('Б.6',23,'NOMINAL_BORE',1000,ARRAY[52,100,152,131,170,164,197],ARRAY[false,false,false,false,false,false,false]),
('Б.6',24,'NOMINAL_BORE',1200,ARRAY[57,122,179,169,213,197,233],ARRAY[false,false,false,false,false,false,false]),
('Б.6',25,'NOMINAL_BORE',1400,ARRAY[60,134,194,187,233,212,251],ARRAY[false,false,false,false,false,false,false]);


-- ============================================================
-- Б.7
-- RETURN50 / SUPPLY65 / TOTAL65-50 /
-- SUPPLY90 / TOTAL90-50
-- ============================================================

INSERT INTO tmp_qh_rows_seed VALUES

('Б.7',1,'NOMINAL_BORE',15,ARRAY[18.1,24.2,42.2,32.0,49.6],ARRAY[true,true,true,true,true]),
('Б.7',2,'NOMINAL_BORE',20,ARRAY[19.0,25.3,44.3,33.6,52.0],ARRAY[true,true,true,true,true]),
('Б.7',3,'NOMINAL_BORE',25,ARRAY[20.0,26.4,46.4,35.2,54.4],ARRAY[false,false,false,false,false]),
('Б.7',4,'NOMINAL_BORE',32,ARRAY[21.3,28.0,49.3,37.4,57.8],ARRAY[true,true,true,true,true]),
('Б.7',5,'NOMINAL_BORE',40,ARRAY[22.9,29.8,52.6,40.0,61.6],ARRAY[true,true,true,true,true]),
('Б.7',6,'NOMINAL_BORE',50,ARRAY[24.8,32.0,56.8,43.2,66.4],ARRAY[false,false,false,false,false]),
('Б.7',7,'NOMINAL_BORE',65,ARRAY[27.2,36.0,63.2,48.0,74.4],ARRAY[false,false,false,false,false]),
('Б.7',8,'NOMINAL_BORE',80,ARRAY[28.0,36.8,64.8,48.8,76.0],ARRAY[false,false,false,false,false]),
('Б.7',9,'NOMINAL_BORE',100,ARRAY[30.4,39.2,69.6,52.0,80.0],ARRAY[false,false,false,false,false]),
('Б.7',10,'NOMINAL_BORE',125,ARRAY[32.8,42.4,75.2,57.6,88.8],ARRAY[false,false,false,false,false]),
('Б.7',11,'NOMINAL_BORE',150,ARRAY[36.8,48.0,84.8,64.0,98.4],ARRAY[false,false,false,false,false]),
('Б.7',12,'NOMINAL_BORE',200,ARRAY[40.0,52.8,92.8,71.2,109.6],ARRAY[false,false,false,false,false]),
('Б.7',13,'NOMINAL_BORE',250,ARRAY[44.0,57.6,101.6,76.8,117.6],ARRAY[false,false,false,false,false]),
('Б.7',14,'NOMINAL_BORE',300,ARRAY[47.2,63.2,110.4,84.0,128.8],ARRAY[false,false,false,false,false]),
('Б.7',15,'NOMINAL_BORE',350,ARRAY[52.0,68.8,120.8,90.4,138.4],ARRAY[false,false,false,false,false]),
('Б.7',16,'NOMINAL_BORE',400,ARRAY[54.4,72.8,127.2,96.8,147.2],ARRAY[false,false,false,false,false]),
('Б.7',17,'NOMINAL_BORE',450,ARRAY[57.6,77.6,135.2,103.2,156.8],ARRAY[false,false,false,false,false]),
('Б.7',18,'NOMINAL_BORE',500,ARRAY[62.4,84.0,146.4,110.4,168.0],ARRAY[false,false,false,false,false]),
('Б.7',19,'NOMINAL_BORE',600,ARRAY[69.6,93.6,163.2,124.8,188.8],ARRAY[false,false,false,false,false]),
('Б.7',20,'NOMINAL_BORE',700,ARRAY[74.4,100.8,175.2,136.0,204.8],ARRAY[false,false,false,false,false]),
('Б.7',21,'NOMINAL_BORE',800,ARRAY[81.6,112.0,193.6,148.8,223.2],ARRAY[false,false,false,false,false]);


-- ============================================================
-- Б.9
-- ============================================================

INSERT INTO tmp_qh_rows_seed VALUES

('Б.9',1,'NOMINAL_BORE',15,ARRAY[19.4,26.2,45.6,34.6,53.4],ARRAY[true,true,true,true,true]),
('Б.9',2,'NOMINAL_BORE',20,ARRAY[20.5,27.5,48.0,36.5,56.3],ARRAY[true,true,true,true,true]),
('Б.9',3,'NOMINAL_BORE',25,ARRAY[21.6,28.8,50.4,38.4,59.2],ARRAY[false,false,false,false,false]),
('Б.9',4,'NOMINAL_BORE',32,ARRAY[23.2,30.6,53.8,41.1,63.2],ARRAY[true,true,true,true,true]),
('Б.9',5,'NOMINAL_BORE',40,ARRAY[25.0,32.6,57.6,44.2,67.8],ARRAY[true,true,true,true,true]),
('Б.9',6,'NOMINAL_BORE',50,ARRAY[27.2,35.2,62.4,48.0,73.6],ARRAY[false,false,false,false,false]),
('Б.9',7,'NOMINAL_BORE',65,ARRAY[30.4,40.0,70.4,53.6,82.4],ARRAY[false,false,false,false,false]),
('Б.9',8,'NOMINAL_BORE',80,ARRAY[31.2,40.8,72.0,55.2,84.8],ARRAY[false,false,false,false,false]),
('Б.9',9,'NOMINAL_BORE',100,ARRAY[33.6,44.0,77.6,59.2,91.2],ARRAY[false,false,false,false,false]),
('Б.9',10,'NOMINAL_BORE',125,ARRAY[36.8,48.8,85.6,64.8,100.0],ARRAY[false,false,false,false,false]),
('Б.9',11,'NOMINAL_BORE',150,ARRAY[41.6,55.2,96.8,72.8,112.0],ARRAY[false,false,false,false,false]),
('Б.9',12,'NOMINAL_BORE',200,ARRAY[47.2,61.6,108.8,80.8,124.0],ARRAY[false,false,false,false,false]),
('Б.9',13,'NOMINAL_BORE',250,ARRAY[50.4,66.4,116.8,88.8,136.0],ARRAY[false,false,false,false,false]),
('Б.9',14,'NOMINAL_BORE',300,ARRAY[55.2,72.8,128.0,97.6,148.8],ARRAY[false,false,false,false,false]),
('Б.9',15,'NOMINAL_BORE',350,ARRAY[60.0,80.8,140.8,106.4,161.6],ARRAY[false,false,false,false,false]),
('Б.9',16,'NOMINAL_BORE',400,ARRAY[64.0,86.4,150.4,112.0,170.4],ARRAY[false,false,false,false,false]),
('Б.9',17,'NOMINAL_BORE',450,ARRAY[68.8,92.8,161.6,120.8,183.2],ARRAY[false,false,false,false,false]),
('Б.9',18,'NOMINAL_BORE',500,ARRAY[72.8,98.4,171.2,130.4,196.8],ARRAY[false,false,false,false,false]),
('Б.9',19,'NOMINAL_BORE',600,ARRAY[82.4,112.0,194.4,148.8,224.0],ARRAY[false,false,false,false,false]),
('Б.9',20,'NOMINAL_BORE',700,ARRAY[89.6,124.8,214.4,162.4,242.4],ARRAY[false,false,false,false,false]),
('Б.9',21,'NOMINAL_BORE',800,ARRAY[97.6,135.2,232.8,180.8,268.0],ARRAY[false,false,false,false,false]);


-- ============================================================
-- 4. КОНФИГУРАЦИЯ КОЛОНОК qh
-- ============================================================

CREATE TEMP TABLE tmp_qh_columns_seed (
    table_code            varchar(10) NOT NULL,
    ordinal_no            integer NOT NULL,
    pipeline_role         varchar(30) NOT NULL,
    temperature_c         numeric,
    supply_temperature_c  numeric,
    return_temperature_c  numeric,
    PRIMARY KEY(table_code, ordinal_no)
) ON COMMIT DROP;


-- Б.1

INSERT INTO tmp_qh_columns_seed VALUES
('Б.1',1,'SINGLE',50,NULL,NULL),
('Б.1',2,'SINGLE',65,NULL,NULL),
('Б.1',3,'SINGLE',70,NULL,NULL);


-- Б.2-Б.6

INSERT INTO tmp_qh_columns_seed
SELECT
    t.table_code,
    c.ordinal_no,
    c.pipeline_role,
    NULL,
    c.supply_temperature_c,
    c.return_temperature_c
FROM (
    VALUES
        ('Б.2'),
        ('Б.3'),
        ('Б.4'),
        ('Б.5'),
        ('Б.6')
) AS t(table_code)
CROSS JOIN (
    VALUES
        (1,'RETURN',         NULL::numeric,50::numeric),
        (2,'SUPPLY',         65,           NULL),
        (3,'TWO_PIPE_TOTAL', 65,           50),
        (4,'SUPPLY',         90,           NULL),
        (5,'TWO_PIPE_TOTAL', 90,           50),
        (6,'SUPPLY',         110,          NULL),
        (7,'TWO_PIPE_TOTAL', 110,          50)
) AS c(
    ordinal_no,
    pipeline_role,
    supply_temperature_c,
    return_temperature_c
);


-- Б.7 / Б.9

INSERT INTO tmp_qh_columns_seed
SELECT
    t.table_code,
    c.ordinal_no,
    c.pipeline_role,
    NULL,
    c.supply_temperature_c,
    c.return_temperature_c
FROM (
    VALUES
        ('Б.7'),
        ('Б.9')
) AS t(table_code)
CROSS JOIN (
    VALUES
        (1,'RETURN',         NULL::numeric,50::numeric),
        (2,'SUPPLY',         65,           NULL),
        (3,'TWO_PIPE_TOTAL', 65,           50),
        (4,'SUPPLY',         90,           NULL),
        (5,'TWO_PIPE_TOTAL', 90,           50)
) AS c(
    ordinal_no,
    pipeline_role,
    supply_temperature_c,
    return_temperature_c
);


-- ============================================================
-- 5. СОЗДАЕМ / ОБНОВЛЯЕМ qh_rows
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
-- 6. УДАЛЯЕМ СТАРЫЕ DIMENSION VALUES И qh VALUES
--    ТОЛЬКО ДЛЯ Б.1-Б.7 И Б.9
-- ============================================================

DELETE FROM qh_row_dimension_values
WHERE row_id IN (
    SELECT r.id
    FROM qh_rows r
    JOIN qh_tables t
        ON t.id = r.table_id
    WHERE t.code IN (
        'Б.1','Б.2','Б.3','Б.4',
        'Б.5','Б.6','Б.7','Б.9'
    )
);


DELETE FROM qh_values
WHERE row_id IN (
    SELECT r.id
    FROM qh_rows r
    JOIN qh_tables t
        ON t.id = r.table_id
    WHERE t.code IN (
        'Б.1','Б.2','Б.3','Б.4',
        'Б.5','Б.6','Б.7','Б.9'
    )
);


-- ============================================================
-- 7. ЗАПОЛНЯЕМ qh_row_dimension_values
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
    s.dimension_value,
    NULL
FROM tmp_qh_rows_seed s

JOIN qh_tables t
    ON t.code = s.table_code

JOIN qh_rows r
    ON r.table_id = t.id
   AND r.source_row_no = s.source_row_no

JOIN qh_dimensions d
    ON d.code = s.dimension_code;


-- ============================================================
-- 8. ЗАПОЛНЯЕМ qh_values
-- ============================================================

WITH cells AS (

    SELECT
        s.table_code,
        s.source_row_no,

        u.ordinality::integer AS ordinal_no,
        u.qh_value,

        s.interpolated[u.ordinality] AS source_interpolated

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


-- ============================================================
-- 9. Б.8 / Б.10
-- КОЭФФИЦИЕНТЫ Кт
-- ============================================================

DELETE FROM qh_material_coefficients
WHERE source_table_code IN (
    'Б.8',
    'Б.10'
);


INSERT INTO qh_material_coefficients (
    source_table_code,
    insulation_material,
    nominal_bore_from_mm,
    nominal_bore_to_mm,
    factor
)
VALUES

-- ============================================================
-- Б.8
-- ============================================================

(
    'Б.8',
    'Пенополиуретан, фенольный поропласт ФП',
    0,
    24.999999,
    0.5
),
(
    'Б.8',
    'Пенополиуретан, фенольный поропласт ФП',
    25,
    65,
    0.5
),
(
    'Б.8',
    'Пенополиуретан, фенольный поропласт ФП',
    80,
    150,
    0.6
),
(
    'Б.8',
    'Пенополиуретан, фенольный поропласт ФП',
    200,
    300,
    0.7
),
(
    'Б.8',
    'Пенополиуретан, фенольный поропласт ФП',
    350,
    500,
    0.8
),
(
    'Б.8',
    'Пенополиуретан, фенольный поропласт ФП',
    500.000001,
    999999,
    1.0
),

(
    'Б.8',
    'Полимербетон',
    0,
    24.999999,
    0.7
),
(
    'Б.8',
    'Полимербетон',
    25,
    65,
    0.7
),
(
    'Б.8',
    'Полимербетон',
    80,
    150,
    0.8
),
(
    'Б.8',
    'Полимербетон',
    200,
    300,
    0.9
),
(
    'Б.8',
    'Полимербетон',
    350,
    500,
    1.0
),
(
    'Б.8',
    'Полимербетон',
    500.000001,
    999999,
    1.0
),


-- ============================================================
-- Б.10
-- ============================================================

(
    'Б.10',
    'Пенополиуретан, фенольный поропласт ФП',
    0,
    24.999999,
    0.5
),
(
    'Б.10',
    'Пенополиуретан, фенольный поропласт ФП',
    25,
    65,
    0.5
),
(
    'Б.10',
    'Пенополиуретан, фенольный поропласт ФП',
    80,
    150,
    0.6
),
(
    'Б.10',
    'Пенополиуретан, фенольный поропласт ФП',
    200,
    300,
    0.7
),
(
    'Б.10',
    'Пенополиуретан, фенольный поропласт ФП',
    350,
    500,
    0.8
),
(
    'Б.10',
    'Пенополиуретан, фенольный поропласт ФП',
    500.000001,
    999999,
    1.0
),

(
    'Б.10',
    'Полимербетон',
    0,
    24.999999,
    0.7
),
(
    'Б.10',
    'Полимербетон',
    25,
    65,
    0.7
),
(
    'Б.10',
    'Полимербетон',
    80,
    150,
    0.8
),
(
    'Б.10',
    'Полимербетон',
    200,
    300,
    0.9
),
(
    'Б.10',
    'Полимербетон',
    350,
    500,
    1.0
),
(
    'Б.10',
    'Полимербетон',
    500.000001,
    999999,
    1.0
);


COMMIT;