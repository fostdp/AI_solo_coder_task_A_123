-- 古代兵营士兵膳食营养监测与疫病预警系统 - 数据库初始化脚本

-- 启用PostGIS扩展
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- 创建数据库
-- CREATE DATABASE barracks_monitor;

-- 兵营表
CREATE TABLE IF NOT EXISTS barracks (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    location GEOMETRY(Point, 4326) NOT NULL,
    description TEXT,
    capacity INTEGER NOT NULL DEFAULT 100,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_barracks_location ON barracks USING GIST(location);

-- 士兵表
CREATE TABLE IF NOT EXISTS soldier (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    soldier_code VARCHAR(50) NOT NULL UNIQUE,
    barracks_id BIGINT NOT NULL REFERENCES barracks(id),
    age INTEGER NOT NULL,
    rank VARCHAR(50),
    position GEOMETRY(Point, 4326) NOT NULL,
    position_x INTEGER NOT NULL,
    position_y INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'HEALTHY',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_soldier_barracks ON soldier(barracks_id);
CREATE INDEX IF NOT EXISTS idx_soldier_position ON soldier USING GIST(position);

-- 膳食记录表
CREATE TABLE IF NOT EXISTS meal_record (
    id BIGSERIAL PRIMARY KEY,
    soldier_id BIGINT NOT NULL REFERENCES soldier(id),
    meal_type VARCHAR(20) NOT NULL,
    meal_time TIMESTAMP NOT NULL,
    protein_g DECIMAL(10,2) NOT NULL DEFAULT 0,
    fat_g DECIMAL(10,2) NOT NULL DEFAULT 0,
    vitamin_c_mg DECIMAL(10,2) NOT NULL DEFAULT 0,
    calorie_kcal DECIMAL(10,2) NOT NULL DEFAULT 0,
    food_items TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_meal_record_soldier ON meal_record(soldier_id);
CREATE INDEX IF NOT EXISTS idx_meal_record_time ON meal_record(meal_time);

-- 体能消耗记录表
CREATE TABLE IF NOT EXISTS physical_activity (
    id BIGSERIAL PRIMARY KEY,
    soldier_id BIGINT NOT NULL REFERENCES soldier(id),
    activity_date DATE NOT NULL,
    activity_type VARCHAR(50) NOT NULL,
    duration_minutes INTEGER NOT NULL DEFAULT 0,
    calorie_burned DECIMAL(10,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_physical_activity_soldier ON physical_activity(soldier_id);
CREATE INDEX IF NOT EXISTS idx_physical_activity_date ON physical_activity(activity_date);

-- 营养分析仪数据表
CREATE TABLE IF NOT EXISTS nutrition_sensor_data (
    id BIGSERIAL PRIMARY KEY,
    sensor_id VARCHAR(50) NOT NULL,
    barracks_id BIGINT NOT NULL REFERENCES barracks(id),
    soldier_id BIGINT REFERENCES soldier(id),
    protein_g DECIMAL(10,2) NOT NULL DEFAULT 0,
    fat_g DECIMAL(10,2) NOT NULL DEFAULT 0,
    vitamin_c_mg DECIMAL(10,2) NOT NULL DEFAULT 0,
    sample_time TIMESTAMP NOT NULL,
    received_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_nutrition_sensor_barracks ON nutrition_sensor_data(barracks_id);
CREATE INDEX IF NOT EXISTS idx_nutrition_sensor_time ON nutrition_sensor_data(sample_time);
CREATE INDEX IF NOT EXISTS idx_nutrition_sensor_soldier ON nutrition_sensor_data(soldier_id);

-- 粪便隐血传感器数据表
CREATE TABLE IF NOT EXISTS fecal_sensor_data (
    id BIGSERIAL PRIMARY KEY,
    sensor_id VARCHAR(50) NOT NULL,
    barracks_id BIGINT NOT NULL REFERENCES barracks(id),
    soldier_id BIGINT REFERENCES soldier(id),
    is_positive BOOLEAN NOT NULL DEFAULT FALSE,
    sample_time TIMESTAMP NOT NULL,
    received_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_fecal_sensor_barracks ON fecal_sensor_data(barracks_id);
CREATE INDEX IF NOT EXISTS idx_fecal_sensor_time ON fecal_sensor_data(sample_time);
CREATE INDEX IF NOT EXISTS idx_fecal_sensor_soldier ON fecal_sensor_data(soldier_id);

-- 营养风险预测表
CREATE TABLE IF NOT EXISTS nutrition_risk (
    id BIGSERIAL PRIMARY KEY,
    soldier_id BIGINT NOT NULL REFERENCES soldier(id),
    risk_level VARCHAR(20) NOT NULL DEFAULT 'LOW',
    protein_risk_score DECIMAL(5,4) NOT NULL DEFAULT 0,
    fat_risk_score DECIMAL(5,4) NOT NULL DEFAULT 0,
    vitamin_c_risk_score DECIMAL(5,4) NOT NULL DEFAULT 0,
    overall_risk_score DECIMAL(5,4) NOT NULL DEFAULT 0,
    dietary_suggestion TEXT,
    predicted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_current BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_nutrition_risk_soldier ON nutrition_risk(soldier_id);
CREATE INDEX IF NOT EXISTS idx_nutrition_risk_level ON nutrition_risk(risk_level);

-- 传染病预警表
CREATE TABLE IF NOT EXISTS epidemic_alert (
    id BIGSERIAL PRIMARY KEY,
    barracks_id BIGINT NOT NULL REFERENCES barracks(id),
    alert_type VARCHAR(50) NOT NULL,
    alert_level VARCHAR(20) NOT NULL,
    positive_rate DECIMAL(5,4) NOT NULL DEFAULT 0,
    affected_count INTEGER NOT NULL DEFAULT 0,
    total_count INTEGER NOT NULL DEFAULT 0,
    cluster_center GEOMETRY(Point, 4326),
    cluster_radius DECIMAL(10,2),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_epidemic_alert_barracks ON epidemic_alert(barracks_id);
CREATE INDEX IF NOT EXISTS idx_epidemic_alert_status ON epidemic_alert(status);

-- 告警推送记录表
CREATE TABLE IF NOT EXISTS notification_log (
    id BIGSERIAL PRIMARY KEY,
    alert_id BIGINT REFERENCES epidemic_alert(id),
    nutrition_risk_id BIGINT REFERENCES nutrition_risk(id),
    notification_type VARCHAR(50) NOT NULL,
    channel VARCHAR(20) NOT NULL,
    recipient VARCHAR(100) NOT NULL,
    content TEXT NOT NULL,
    sent_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
);

CREATE INDEX IF NOT EXISTS idx_notification_log_type ON notification_log(notification_type);
CREATE INDEX IF NOT EXISTS idx_notification_log_status ON notification_log(status);

-- 初始化5座兵营数据
INSERT INTO barracks (name, code, location, description, capacity) VALUES
('第一兵营（南营）', 'BARRACKS_001', ST_SetSRID(ST_MakePoint(100.2700, 41.8500), 4326), '汉代居延遗址复原南营区', 120),
('第二兵营（北营）', 'BARRACKS_002', ST_SetSRID(ST_MakePoint(100.2710, 41.8520), 4326), '汉代居延遗址复原北营区', 100),
('第三兵营（东营）', 'BARRACKS_003', ST_SetSRID(ST_MakePoint(100.2730, 41.8510), 4326), '汉代居延遗址复原东营区', 110),
('第四兵营（西营）', 'BARRACKS_004', ST_SetSRID(ST_MakePoint(100.2680, 41.8510), 4326), '汉代居延遗址复原西营区', 90),
('第五兵营（中营）', 'BARRACKS_005', ST_SetSRID(ST_MakePoint(100.2710, 41.8510), 4326), '汉代居延遗址复原中营指挥区', 80)
ON CONFLICT (code) DO NOTHING;

-- 初始化士兵数据（每个兵营若干士兵）
-- 第一兵营
INSERT INTO soldier (name, soldier_code, barracks_id, age, rank, position, position_x, position_y, status)
SELECT 
    '士兵张' || g,
    'S001_' || LPAD(g::TEXT, 3, '0'),
    1,
    20 + (g % 25),
    CASE WHEN g % 10 = 0 THEN '什长' WHEN g % 50 = 0 THEN '屯长' ELSE '士卒' END,
    ST_SetSRID(ST_MakePoint(100.2700 + (g % 10) * 0.00005, 41.8500 + (g / 10) * 0.00005), 4326),
    50 + (g % 10) * 15,
    50 + (g / 10) * 15,
    'HEALTHY'
FROM generate_series(1, 50) g
ON CONFLICT (soldier_code) DO NOTHING;

-- 第二兵营
INSERT INTO soldier (name, soldier_code, barracks_id, age, rank, position, position_x, position_y, status)
SELECT 
    '士兵李' || g,
    'S002_' || LPAD(g::TEXT, 3, '0'),
    2,
    20 + (g % 25),
    CASE WHEN g % 10 = 0 THEN '什长' WHEN g % 50 = 0 THEN '屯长' ELSE '士卒' END,
    ST_SetSRID(ST_MakePoint(100.2710 + (g % 10) * 0.00005, 41.8520 + (g / 10) * 0.00005), 4326),
    50 + (g % 10) * 15,
    50 + (g / 10) * 15,
    'HEALTHY'
FROM generate_series(1, 40) g
ON CONFLICT (soldier_code) DO NOTHING;

-- 第三兵营
INSERT INTO soldier (name, soldier_code, barracks_id, age, rank, position, position_x, position_y, status)
SELECT 
    '士兵王' || g,
    'S003_' || LPAD(g::TEXT, 3, '0'),
    3,
    20 + (g % 25),
    CASE WHEN g % 10 = 0 THEN '什长' WHEN g % 50 = 0 THEN '屯长' ELSE '士卒' END,
    ST_SetSRID(ST_MakePoint(100.2730 + (g % 10) * 0.00005, 41.8510 + (g / 10) * 0.00005), 4326),
    50 + (g % 10) * 15,
    50 + (g / 10) * 15,
    'HEALTHY'
FROM generate_series(1, 45) g
ON CONFLICT (soldier_code) DO NOTHING;

-- 第四兵营
INSERT INTO soldier (name, soldier_code, barracks_id, age, rank, position, position_x, position_y, status)
SELECT 
    '士兵赵' || g,
    'S004_' || LPAD(g::TEXT, 3, '0'),
    4,
    20 + (g % 25),
    CASE WHEN g % 10 = 0 THEN '什长' WHEN g % 50 = 0 THEN '屯长' ELSE '士卒' END,
    ST_SetSRID(ST_MakePoint(100.2680 + (g % 9) * 0.00005, 41.8510 + (g / 9) * 0.00005), 4326),
    50 + (g % 9) * 15,
    50 + (g / 9) * 15,
    'HEALTHY'
FROM generate_series(1, 35) g
ON CONFLICT (soldier_code) DO NOTHING;

-- 第五兵营
INSERT INTO soldier (name, soldier_code, barracks_id, age, rank, position, position_x, position_y, status)
SELECT 
    '士兵刘' || g,
    'S005_' || LPAD(g::TEXT, 3, '0'),
    5,
    20 + (g % 25),
    CASE WHEN g % 10 = 0 THEN '什长' WHEN g % 50 = 0 THEN '屯长' ELSE '士卒' END,
    ST_SetSRID(ST_MakePoint(100.2710 + (g % 8) * 0.00005, 41.8510 + (g / 8) * 0.00005), 4326),
    50 + (g % 8) * 15,
    50 + (g / 8) * 15,
    'HEALTHY'
FROM generate_series(1, 30) g
ON CONFLICT (soldier_code) DO NOTHING;

-- 插入示例膳食记录（最近7天）
INSERT INTO meal_record (soldier_id, meal_type, meal_time, protein_g, fat_g, vitamin_c_mg, calorie_kcal, food_items)
SELECT 
    s.id,
    CASE h % 3
        WHEN 0 THEN 'BREAKFAST'
        WHEN 1 THEN 'LUNCH'
        ELSE 'DINNER'
    END,
    NOW() - (d || ' days')::INTERVAL + (h || ' hours')::INTERVAL,
    15 + (random() * 25),
    10 + (random() * 20),
    30 + (random() * 60),
    400 + (random() * 600),
    '粟米饭,烤肉,蔬菜汤'
FROM soldier s
CROSS JOIN generate_series(0, 6) d
CROSS JOIN generate_series(0, 2) h
ON CONFLICT DO NOTHING;

-- 插入示例体能消耗记录
INSERT INTO physical_activity (soldier_id, activity_date, activity_type, duration_minutes, calorie_burned)
SELECT 
    s.id,
    CURRENT_DATE - d,
    CASE 
        WHEN d % 4 = 0 THEN '军事训练'
        WHEN d % 4 = 1 THEN '巡逻执勤'
        WHEN d % 4 = 2 THEN '体力劳动'
        ELSE '日常操练'
    END,
    60 + (random() * 180),
    200 + (random() * 500)
FROM soldier s
CROSS JOIN generate_series(0, 6) d
ON CONFLICT DO NOTHING;

-- 创建视图：每日营养摄入汇总
CREATE OR REPLACE VIEW v_daily_nutrition AS
SELECT 
    s.id AS soldier_id,
    s.name AS soldier_name,
    s.barracks_id,
    DATE(m.meal_time) AS meal_date,
    SUM(m.protein_g) AS total_protein_g,
    SUM(m.fat_g) AS total_fat_g,
    SUM(m.vitamin_c_mg) AS total_vitamin_c_mg,
    SUM(m.calorie_kcal) AS total_calorie_kcal
FROM soldier s
JOIN meal_record m ON s.id = m.soldier_id
GROUP BY s.id, s.name, s.barracks_id, DATE(m.meal_time);

-- 创建视图：兵营肠道感染统计
CREATE OR REPLACE VIEW v_barracks_infection_stats AS
SELECT 
    b.id AS barracks_id,
    b.name AS barracks_name,
    DATE(f.sample_time) AS sample_date,
    COUNT(*) AS total_samples,
    SUM(CASE WHEN f.is_positive THEN 1 ELSE 0 END) AS positive_count,
    ROUND(
        SUM(CASE WHEN f.is_positive THEN 1 ELSE 0 END)::DECIMAL / 
        NULLIF(COUNT(*), 0) * 100, 
        2
    ) AS positive_rate_percent
FROM barracks b
JOIN fecal_sensor_data f ON b.id = f.barracks_id
GROUP BY b.id, b.name, DATE(f.sample_time);
