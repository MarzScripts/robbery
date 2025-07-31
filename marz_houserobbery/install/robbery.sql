-- House Robbery Database Tables
-- Import this SQL file into your database

-- Create the main house robberies table
CREATE TABLE IF NOT EXISTS `marz_house_robberies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `house` varchar(100) NOT NULL,
  `robbed` longtext DEFAULT '[]',
  `players` longtext DEFAULT '[]',
  `locked` tinyint(1) DEFAULT 1,
  `lastreset` int(11) DEFAULT 0,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `house` (`house`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default house entries
INSERT IGNORE INTO `marz_house_robberies` (`house`, `robbed`, `players`, `locked`, `lastreset`) VALUES
('Low Tier 1', '[]', '[]', 1, UNIX_TIMESTAMP()),
('Low Tier 2', '[]', '[]', 1, UNIX_TIMESTAMP()),
('Low Tier 3', '[]', '[]', 1, UNIX_TIMESTAMP()),
('Low Tier 4', '[]', '[]', 1, UNIX_TIMESTAMP()),
('Low Tier 5', '[]', '[]', 1, UNIX_TIMESTAMP()),
('Low Tier 6', '[]', '[]', 1, UNIX_TIMESTAMP());

-- Create house robbery logs table (optional for tracking)
CREATE TABLE IF NOT EXISTS `marz_house_robbery_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `player_id` varchar(50) NOT NULL,
  `house` varchar(100) NOT NULL,
  `action` varchar(50) NOT NULL,
  `data` longtext DEFAULT NULL,
  `timestamp` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `player_id` (`player_id`),
  KEY `house` (`house`),
  KEY `timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;