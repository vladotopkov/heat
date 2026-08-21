-- ============================================================
-- КОЭФФИЦИЕНТЫ Кн ИЗ Б.8
-- применяются к Б.7
-- ============================================================

INSERT INTO qh_material_coefficients (
    source_table_code,
    insulation_material,
    nominal_bore_from_mm,
    nominal_bore_to_mm,
    factor
)
VALUES

-- Пенополиуретан
('Б.8', 'POLYURETHANE_FOAM', NULL, 24,   0.5),
('Б.8', 'POLYURETHANE_FOAM', 25,   65,  0.5),
('Б.8', 'POLYURETHANE_FOAM', 80,   150, 0.6),
('Б.8', 'POLYURETHANE_FOAM', 200,  300, 0.7),
('Б.8', 'POLYURETHANE_FOAM', 350,  500, 0.8),
('Б.8', 'POLYURETHANE_FOAM', 501,  NULL, 1.0),

-- Фенольный поропласт ФЛ
('Б.8', 'PHENOLIC_FOAM_FL', NULL, 24,   0.5),
('Б.8', 'PHENOLIC_FOAM_FL', 25,   65,  0.5),
('Б.8', 'PHENOLIC_FOAM_FL', 80,   150, 0.6),
('Б.8', 'PHENOLIC_FOAM_FL', 200,  300, 0.7),
('Б.8', 'PHENOLIC_FOAM_FL', 350,  500, 0.8),
('Б.8', 'PHENOLIC_FOAM_FL', 501,  NULL, 1.0),

-- Полимербетон
('Б.8', 'POLYMER_CONCRETE', NULL, 24,   0.7),
('Б.8', 'POLYMER_CONCRETE', 25,   65,  0.7),
('Б.8', 'POLYMER_CONCRETE', 80,   150, 0.8),
('Б.8', 'POLYMER_CONCRETE', 200,  300, 0.9),
('Б.8', 'POLYMER_CONCRETE', 350,  500, 1.0),
('Б.8', 'POLYMER_CONCRETE', 501,  NULL, 1.0);




-- ============================================================
-- КОЭФФИЦИЕНТЫ Кн ИЗ Б.10
-- применяются к Б.9
-- ============================================================

INSERT INTO qh_material_coefficients (
    source_table_code,
    insulation_material,
    nominal_bore_from_mm,
    nominal_bore_to_mm,
    factor
)
VALUES

('Б.10', 'POLYURETHANE_FOAM', NULL, 24,   0.5),
('Б.10', 'POLYURETHANE_FOAM', 25,   65,  0.5),
('Б.10', 'POLYURETHANE_FOAM', 80,   150, 0.6),
('Б.10', 'POLYURETHANE_FOAM', 200,  300, 0.7),
('Б.10', 'POLYURETHANE_FOAM', 350,  500, 0.8),
('Б.10', 'POLYURETHANE_FOAM', 501,  NULL, 1.0),

('Б.10', 'PHENOLIC_FOAM_FL', NULL, 24,   0.5),
('Б.10', 'PHENOLIC_FOAM_FL', 25,   65,  0.5),
('Б.10', 'PHENOLIC_FOAM_FL', 80,   150, 0.6),
('Б.10', 'PHENOLIC_FOAM_FL', 200,  300, 0.7),
('Б.10', 'PHENOLIC_FOAM_FL', 350,  500, 0.8),
('Б.10', 'PHENOLIC_FOAM_FL', 501,  NULL, 1.0),

('Б.10', 'POLYMER_CONCRETE', NULL, 24,   0.7),
('Б.10', 'POLYMER_CONCRETE', 25,   65,  0.7),
('Б.10', 'POLYMER_CONCRETE', 80,   150, 0.8),
('Б.10', 'POLYMER_CONCRETE', 200,  300, 0.9),
('Б.10', 'POLYMER_CONCRETE', 350,  500, 1.0),
('Б.10', 'POLYMER_CONCRETE', 501,  NULL, 1.0);