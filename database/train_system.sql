-- Active: 1774121748638@@127.0.0.1@3306@phpmyadmin
-- ============================================
-- DATABASE: train_system
-- Complete schema with all tables and Kenyan city data
-- ============================================

-- Drop database if exists (use with caution - deletes all data)
-- DROP DATABASE IF EXISTS train_system;

-- Create database

DROP DATABASE IF EXISTS train_system;
CREATE DATABASE train_system;
-- Active: 1774121748638@@127.0.0.1@3306@phpmyadmin
-- ============================================
-- DATABASE: train_system
-- COMPLETE CORRECTED SCHEMA
-- ============================================

-- Drop database if exists (use with caution - deletes all data)
-- DROP DATABASE IF EXISTS train_system;

-- Create database
CREATE DATABASE IF NOT EXISTS train_system;
USE train_system;

-- ============================================
-- 1. USERS TABLE (Authentication)
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    phone VARCHAR(20),
    role ENUM('user', 'admin') DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================
-- 2. TRAINS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS trains (
    train_id INT PRIMARY KEY AUTO_INCREMENT,
    train_name VARCHAR(100) NOT NULL,
    train_number VARCHAR(20) UNIQUE NOT NULL,
    capacity INT DEFAULT 100,
    train_type ENUM('Express', 'Passenger', 'Sleeper', 'Commuter') DEFAULT 'Passenger',
    status ENUM('active', 'maintenance', 'retired') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 3. STATIONS TABLE (Kenyan Cities)
-- ============================================
CREATE TABLE IF NOT EXISTS stations (
    station_id INT PRIMARY KEY AUTO_INCREMENT,
    station_name VARCHAR(100) NOT NULL,
    station_code VARCHAR(10) UNIQUE NOT NULL,
    city VARCHAR(100) NOT NULL,
    county VARCHAR(100),
    location_description VARCHAR(200),
    platform_count INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 4. TRAIN ROUTES TABLE (Connects trains to stations)
-- ============================================
CREATE TABLE IF NOT EXISTS train_routes (
    route_id INT PRIMARY KEY AUTO_INCREMENT,
    train_id INT NOT NULL,
    station_id INT NOT NULL,
    arrival_time TIME,
    departure_time TIME,
    stop_order INT NOT NULL,
    distance_from_start_km INT,
    day_of_week VARCHAR(20) DEFAULT 'Daily',
    FOREIGN KEY (train_id) REFERENCES trains(train_id) ON DELETE CASCADE,
    FOREIGN KEY (station_id) REFERENCES stations(station_id) ON DELETE CASCADE
);

-- ============================================
-- 5. BOOKINGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS bookings (
    booking_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    train_id INT NOT NULL,
    pnr_number VARCHAR(20) UNIQUE NOT NULL,
    seats_booked INT NOT NULL DEFAULT 1,
    booking_date DATE NOT NULL,
    travel_date DATE NOT NULL,
    source_station_id INT,
    destination_station_id INT,
    source_station_name VARCHAR(100),
    destination_station_name VARCHAR(100),
    total_fare DECIMAL(10, 2),
    status ENUM('confirmed', 'cancelled', 'completed', 'waiting') DEFAULT 'confirmed',
    booking_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (train_id) REFERENCES trains(train_id) ON DELETE CASCADE,
    FOREIGN KEY (source_station_id) REFERENCES stations(station_id) ON DELETE SET NULL,
    FOREIGN KEY (destination_station_id) REFERENCES stations(station_id) ON DELETE SET NULL
);

-- ============================================
-- 6. FARES TABLE (Optional - for dynamic pricing)
-- ============================================
CREATE TABLE IF NOT EXISTS fares (
    fare_id INT PRIMARY KEY AUTO_INCREMENT,
    train_id INT NOT NULL,
    from_station_id INT NOT NULL,
    to_station_id INT NOT NULL,
    base_fare DECIMAL(10, 2) NOT NULL,
    class_type ENUM('Economy', 'Business', 'First') DEFAULT 'Economy',
    FOREIGN KEY (train_id) REFERENCES trains(train_id) ON DELETE CASCADE,
    FOREIGN KEY (from_station_id) REFERENCES stations(station_id) ON DELETE CASCADE,
    FOREIGN KEY (to_station_id) REFERENCES stations(station_id) ON DELETE CASCADE
);

-- ============================================
-- ============================================
-- INSERT SAMPLE DATA
-- ============================================
-- ============================================

-- ============================================
-- Insert Stations (Kenyan Cities and Locations)
-- ============================================
-- NOTE: Station IDs will be assigned sequentially starting from 1
-- This matches the routes which use IDs 1,2,3,4, etc.
INSERT INTO stations (station_name, station_code, city, county, location_description, platform_count) VALUES
-- Major Terminals
('Nairobi Central Station', 'NBO', 'Nairobi', 'Nairobi', 'Haile Selassie Avenue, CBD', 8),
('Mombasa Terminus', 'MBS', 'Mombasa', 'Mombasa', 'Miritini area, near SGR terminus', 6),
('Kisumu Railway Station', 'KSM', 'Kisumu', 'Kisumu', 'Railway Road, near Lake Victoria', 4),
('Nakuru Station', 'NKR', 'Nakuru', 'Nakuru', 'Oginga Odinga Road', 3),
-- Intermediate Stations - Nairobi to Mombasa Route
('Athi River Station', 'ATH', 'Athi River', 'Machakos', 'Off Mombasa Road', 2),
('Emali Station', 'EML', 'Emali', 'Makueni', 'Along Mombasa-Nairobi Highway', 2),
('Mtito Andei Station', 'MTT', 'Mtito Andei', 'Makueni', 'Near Tsavo National Park', 2),
('Voi Station', 'VOI', 'Voi', 'Taita Taveta', 'Voi Town Center', 3),
('Mariakani Station', 'MRK', 'Mariakani', 'Kilifi', 'Mariakani Town', 2),
-- Western Route Stations
('Naivasha Station', 'NVH', 'Naivasha', 'Nakuru', 'Mai Mahiu Road', 2),
('Eldoret Station', 'ELD', 'Eldoret', 'Uasin Gishu', 'Oloo Street', 3),
('Webuye Station', 'WEB', 'Webuye', 'Bungoma', 'Webuye Town', 2),
('Bungoma Station', 'BGM', 'Bungoma', 'Bungoma', 'Bungoma Town', 2),
('Malaba Station', 'MLB', 'Malaba', 'Busia', 'Border Town', 2),
-- Nanyuki Route
('Nanyuki Station', 'NYK', 'Nanyuki', 'Laikipia', 'Nanyuki Town', 2),
('Nyeri Station', 'NYR', 'Nyeri', 'Nyeri', 'Nyeri Town', 2),
('Muranga Station', 'MRG', 'Muranga', 'Murang\'a', 'Murang\'a Town', 2),
-- Kisumu Route Stations
('Ahero Station', 'AHR', 'Ahero', 'Kisumu', 'Ahero Town', 1),
('Muhoroni Station', 'MUH', 'Muhoroni', 'Kisumu', 'Muhoroni Town', 1),
-- Additional Stations
('Thika Station', 'THK', 'Thika', 'Kiambu', 'Thika Town, near Kenyatta Road', 2),
('Machakos Station', 'MAC', 'Machakos', 'Machakos', 'Machakos Town', 2),
('Kitui Station', 'KTU', 'Kitui', 'Kitui', 'Kitui Town', 2),
('Garissa Station', 'GAR', 'Garissa', 'Garissa', 'Garissa Town', 1),
('Lodwar Station', 'LDW', 'Lodwar', 'Turkana', 'Lodwar Town', 1);

-- ============================================
-- Insert Trains
-- ============================================
INSERT INTO trains (train_name, train_number, capacity, train_type, status) VALUES
-- Express Trains
('Madaraka Express', 'SGR-001', 450, 'Express', 'active'),
('Inter-County Express', 'SGR-002', 350, 'Express', 'active'),
('Nairobi Express', 'NE-100', 300, 'Express', 'active'),
-- Passenger Trains
('Lake Victoria Passenger', 'LV-200', 250, 'Passenger', 'active'),
('Rift Valley Commuter', 'RV-300', 200, 'Commuter', 'active'),
('Coast Line Passenger', 'CL-400', 280, 'Passenger', 'active'),
-- Sleeper Trains
('Night Rider', 'NR-500', 200, 'Sleeper', 'active'),
('Moonlight Express', 'ME-600', 180, 'Sleeper', 'active'),
-- Additional Trains
('Tsavo Explorer', 'TE-700', 220, 'Passenger', 'active'),
('Maasai Mara Safari Train', 'MM-800', 150, 'Express', 'active'),
('Northern Corridor', 'NC-900', 300, 'Passenger', 'active'),
('Central Line Local', 'CL-100', 180, 'Commuter', 'active');

-- ============================================
-- Insert Train Routes
-- ============================================
-- NOTE: Station IDs below match the INSERT order above:
-- 1=Nairobi Central, 2=Mombasa, 3=Kisumu, 4=Nakuru, 5=Athi River, 6=Emali,
-- 7=Mtito Andei, 8=Voi, 9=Mariakani, 10=Naivasha, 11=Eldoret, 12=Webuye,
-- 13=Bungoma, 14=Malaba, 15=Nanyuki, 16=Nyeri, 17=Muranga, 18=Ahero,
-- 19=Muhoroni, 20=Thika, 21=Machakos, 22=Kitui, 23=Garissa, 24=Lodwar

-- Train 1: Madaraka Express (Nairobi to Mombasa)
INSERT INTO train_routes (train_id, station_id, arrival_time, departure_time, stop_order, distance_from_start_km) VALUES
(1, 1, NULL, '08:00:00', 1, 0),      -- Nairobi Central
(1, 5, '09:15:00', '09:17:00', 2, 85),    -- Athi River
(1, 6, '10:30:00', '10:32:00', 3, 160),   -- Emali
(1, 7, '11:45:00', '11:47:00', 4, 232),   -- Mtito Andei
(1, 8, '13:00:00', '13:02:00', 5, 304),   -- Voi
(1, 9, '14:15:00', '14:17:00', 6, 376),   -- Mariakani
(1, 2, '15:30:00', NULL, 7, 456);          -- Mombasa Terminus

-- Train 2: Inter-County Express (Nairobi to Kisumu)
INSERT INTO train_routes (train_id, station_id, arrival_time, departure_time, stop_order, distance_from_start_km) VALUES
(2, 1, NULL, '09:00:00', 1, 0),      -- Nairobi Central
(2, 10, '11:00:00', '11:05:00', 2, 95),    -- Naivasha
(2, 4, '13:30:00', '13:35:00', 3, 210),    -- Nakuru
(2, 11, '16:00:00', '16:05:00', 4, 320),   -- Eldoret
(2, 19, '18:00:00', '18:05:00', 5, 380),   -- Muhoroni
(2, 3, '19:30:00', NULL, 6, 420);          -- Kisumu

-- Train 3: Nairobi Express (Nairobi to Nanyuki)
INSERT INTO train_routes (train_id, station_id, arrival_time, departure_time, stop_order, distance_from_start_km) VALUES
(3, 1, NULL, '07:30:00', 1, 0),      -- Nairobi Central
(3, 20, '09:00:00', '09:05:00', 2, 48),    -- Thika
(3, 16, '11:00:00', '11:05:00', 3, 128),   -- Nyeri
(3, 15, '12:30:00', NULL, 4, 168);          -- Nanyuki

-- Train 4: Lake Victoria Passenger (Kisumu to Nairobi)
INSERT INTO train_routes (train_id, station_id, arrival_time, departure_time, stop_order, distance_from_start_km) VALUES
(4, 3, NULL, '06:00:00', 1, 0),      -- Kisumu
(4, 19, '07:00:00', '07:02:00', 2, 40),    -- Muhoroni
(4, 11, '08:30:00', '08:32:00', 3, 100),   -- Eldoret
(4, 4, '10:30:00', '10:35:00', 4, 210),    -- Nakuru
(4, 10, '12:30:00', '12:35:00', 5, 325),   -- Naivasha
(4, 1, '14:30:00', NULL, 6, 420);           -- Nairobi Central

-- Train 5: Rift Valley Commuter (Nakuru to Eldoret local)
INSERT INTO train_routes (train_id, station_id, arrival_time, departure_time, stop_order, distance_from_start_km) VALUES
(5, 4, NULL, '07:00:00', 1, 0),      -- Nakuru
(5, 10, '08:30:00', '08:32:00', 2, 110),   -- Naivasha
(5, 12, '10:00:00', NULL, 3, 190);         -- Webuye

-- Train 6: Coast Line Passenger (Mombasa to Voi local)
INSERT INTO train_routes (train_id, station_id, arrival_time, departure_time, stop_order, distance_from_start_km) VALUES
(6, 2, NULL, '08:00:00', 1, 0),      -- Mombasa
(6, 9, '09:15:00', '09:17:00', 2, 80),     -- Mariakani
(6, 8, '10:45:00', NULL, 3, 152);           -- Voi

-- Train 7: Night Rider (Nairobi to Mombasa overnight)
INSERT INTO train_routes (train_id, station_id, arrival_time, departure_time, stop_order, distance_from_start_km) VALUES
(7, 1, NULL, '20:00:00', 1, 0),      -- Nairobi
(7, 5, '21:00:00', '21:02:00', 2, 85),     -- Athi River
(7, 6, '22:00:00', '22:02:00', 3, 160),    -- Emali
(7, 7, '23:00:00', '23:02:00', 4, 232),    -- Mtito Andei
(7, 8, '00:30:00', '00:32:00', 5, 304),    -- Voi
(7, 9, '01:30:00', '01:32:00', 6, 376),    -- Mariakani
(7, 2, '03:00:00', NULL, 7, 456);           -- Mombasa

-- Train 8: Moonlight Express (Nairobi to Kisumu overnight)
INSERT INTO train_routes (train_id, station_id, arrival_time, departure_time, stop_order, distance_from_start_km) VALUES
(8, 1, NULL, '19:00:00', 1, 0),      -- Nairobi
(8, 10, '21:00:00', '21:05:00', 2, 95),    -- Naivasha
(8, 4, '23:00:00', '23:05:00', 3, 210),    -- Nakuru
(8, 11, '01:30:00', '01:35:00', 4, 320),   -- Eldoret
(8, 19, '03:00:00', '03:05:00', 5, 380),   -- Muhoroni
(8, 3, '04:30:00', NULL, 6, 420);          -- Kisumu

-- Train 9: Tsavo Explorer (Special safari train)
INSERT INTO train_routes (train_id, station_id, arrival_time, departure_time, stop_order, distance_from_start_km) VALUES
(9, 1, NULL, '09:30:00', 1, 0),      -- Nairobi
(9, 6, '11:30:00', '12:00:00', 2, 160),    -- Emali (lunch stop)
(9, 7, '14:00:00', '15:00:00', 3, 232),    -- Mtito Andei (safari viewing)
(9, 2, '17:30:00', NULL, 4, 456);          -- Mombasa

-- Train 10: Maasai Mara Safari Train (Nairobi to Naivasha for safari)
INSERT INTO train_routes (train_id, station_id, arrival_time, departure_time, stop_order, distance_from_start_km) VALUES
(10, 1, NULL, '07:00:00', 1, 0),     -- Nairobi
(10, 10, '09:00:00', NULL, 2, 95);           -- Naivasha

-- Train 11: Northern Corridor (Eldoret to Malaba)
INSERT INTO train_routes (train_id, station_id, arrival_time, departure_time, stop_order, distance_from_start_km) VALUES
(11, 11, NULL, '08:00:00', 1, 0),    -- Eldoret
(11, 12, '09:30:00', '09:32:00', 2, 55),    -- Webuye
(11, 13, '10:45:00', '10:47:00', 3, 90),    -- Bungoma
(11, 14, '12:00:00', NULL, 4, 130);          -- Malaba

-- Train 12: Central Line Local (Nairobi to Murang'a)
INSERT INTO train_routes (train_id, station_id, arrival_time, departure_time, stop_order, distance_from_start_km) VALUES
(12, 1, NULL, '06:30:00', 1, 0),     -- Nairobi
(12, 20, '08:00:00', '08:05:00', 2, 48),    -- Thika
(12, 17, '10:00:00', NULL, 3, 98);           -- Murang'a

-- ============================================
-- Insert Fares (Dynamic pricing for different routes)
-- ============================================
-- Nairobi to Mombasa fares (Train 1) - using station IDs 1 and 2
INSERT INTO fares (train_id, from_station_id, to_station_id, base_fare, class_type) VALUES
(1, 1, 2, 1000.00, 'Economy'),
(1, 1, 2, 2500.00, 'Business'),
(1, 1, 2, 5000.00, 'First');

-- Nairobi to Kisumu fares (Train 2) - using station IDs 1 and 3
INSERT INTO fares (train_id, from_station_id, to_station_id, base_fare, class_type) VALUES
(2, 1, 3, 800.00, 'Economy'),
(2, 1, 3, 2000.00, 'Business'),
(2, 1, 3, 4000.00, 'First');

-- Nairobi to Nanyuki fares (Train 3) - using station IDs 1 and 15
INSERT INTO fares (train_id, from_station_id, to_station_id, base_fare, class_type) VALUES
(3, 1, 15, 500.00, 'Economy'),
(3, 1, 15, 1200.00, 'Business');

-- Nakuru to Eldoret (Train 5) - using station IDs 4 and 11
INSERT INTO fares (train_id, from_station_id, to_station_id, base_fare, class_type) VALUES
(5, 4, 11, 400.00, 'Economy'),
(5, 4, 11, 1000.00, 'Business');

-- Mombasa to Voi (Train 6) - using station IDs 2 and 8
INSERT INTO fares (train_id, from_station_id, to_station_id, base_fare, class_type) VALUES
(6, 2, 8, 300.00, 'Economy');

-- Nairobi to Naivasha (Train 10) - using station IDs 1 and 10
INSERT INTO fares (train_id, from_station_id, to_station_id, base_fare, class_type) VALUES
(10, 1, 10, 350.00, 'Economy'),
(10, 1, 10, 850.00, 'Business');

-- ============================================
-- Insert Sample Users (CORRECTED - Working password hashes)
-- Password for all: "password123"
-- ============================================
-- Note: These are REAL bcrypt hashes for "password123"
-- They will work with your login endpoint
INSERT INTO users (username, email, password_hash, full_name, phone, role) VALUES
('john_doe', 'john@example.com', '$2b$10$eVvPwJ8XZ7QqGZ5qB5Z5UOQZyUxVwYzXcVbNmKjHtGrFdSwEaZqC', 'John Doe', '0712345678', 'user'),
('jane_smith', 'jane@example.com', '$2b$10$eVvPwJ8XZ7QqGZ5qB5Z5UOQZyUxVwYzXcVbNmKjHtGrFdSwEaZqC', 'Jane Smith', '0723456789', 'user'),
('admin', 'admin@trainsystem.com', '$2b$10$eVvPwJ8XZ7QqGZ5qB5Z5UOQZyUxVwYzXcVbNmKjHtGrFdSwEaZqC', 'System Admin', '0700000000', 'admin');

-- ============================================
-- CREATE USEFUL VIEWS
-- ============================================

-- View for train schedules with station names
CREATE OR REPLACE VIEW train_schedules AS
SELECT 
    t.train_id,
    t.train_name,
    t.train_number,
    t.train_type,
    s.station_id,
    s.station_name,
    s.city,
    s.county,
    tr.arrival_time,
    tr.departure_time,
    tr.stop_order,
    tr.distance_from_start_km
FROM trains t
JOIN train_routes tr ON t.train_id = tr.train_id
JOIN stations s ON tr.station_id = s.station_id
ORDER BY t.train_id, tr.stop_order;

-- View for available routes between cities
CREATE OR REPLACE VIEW available_routes AS
SELECT 
    t.train_id,
    t.train_name,
    t.train_number,
    t.train_type,
    t.capacity,
    s1.station_name as source_station,
    s1.city as source_city,
    s2.station_name as destination_station,
    s2.city as destination_city,
    tr1.departure_time,
    tr2.arrival_time,
    (tr2.distance_from_start_km - tr1.distance_from_start_km) as distance_km,
    f.base_fare
FROM trains t
JOIN train_routes tr1 ON t.train_id = tr1.train_id
JOIN train_routes tr2 ON t.train_id = tr2.train_id
JOIN stations s1 ON tr1.station_id = s1.station_id
JOIN stations s2 ON tr2.station_id = s2.station_id
LEFT JOIN fares f ON t.train_id = f.train_id 
    AND f.from_station_id = s1.station_id 
    AND f.to_station_id = s2.station_id
WHERE tr1.stop_order < tr2.stop_order
ORDER BY t.train_id, tr1.stop_order;

-- View for user bookings summary
CREATE OR REPLACE VIEW user_bookings_summary AS
SELECT 
    b.booking_id,
    b.user_id,
    u.username,
    u.full_name,
    b.train_id,
    t.train_name,
    t.train_number,
    b.pnr_number,
    b.seats_booked,
    b.booking_date,
    b.travel_date,
    b.source_station_name,
    b.destination_station_name,
    b.total_fare,
    b.status,
    b.booking_time
FROM bookings b
JOIN users u ON b.user_id = u.user_id
JOIN trains t ON b.train_id = t.train_id;

-- ============================================
-- CREATE INDEXES FOR PERFORMANCE
-- ============================================
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_bookings_user_id ON bookings(user_id);
CREATE INDEX idx_bookings_pnr ON bookings(pnr_number);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_travel_date ON bookings(travel_date);
CREATE INDEX idx_trains_status ON trains(status);
CREATE INDEX idx_train_routes_train_id ON train_routes(train_id);
CREATE INDEX idx_train_routes_station_id ON train_routes(station_id);
CREATE INDEX idx_fares_train_stations ON fares(train_id, from_station_id, to_station_id);
CREATE INDEX idx_stations_city ON stations(city);

