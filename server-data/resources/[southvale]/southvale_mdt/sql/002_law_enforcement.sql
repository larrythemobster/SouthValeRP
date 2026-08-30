-- Run after southvale_mdt.sql. This migration retains every existing incident.
ALTER TABLE `southvale_mdt_incidents`
  ADD COLUMN `report_number` varchar(24) NULL AFTER `id`,
  ADD COLUMN `evidence` text NULL AFTER `citizens`,
  ADD COLUMN `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() AFTER `created_at`,
  ADD UNIQUE KEY `southvale_mdt_incidents_report_number_uq` (`report_number`);

UPDATE `southvale_mdt_incidents`
SET `report_number` = CONCAT('SV-', DATE_FORMAT(`created_at`, '%Y%m%d'), '-', LPAD(`id`, 5, '0'))
WHERE `report_number` IS NULL;

CREATE TABLE IF NOT EXISTS `southvale_mdt_notes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `body` text NOT NULL,
  `author_citizenid` varchar(50) NOT NULL,
  `author_name` varchar(150) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`), KEY `citizenid_created_at` (`citizenid`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `southvale_mdt_warrants` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `warrant_number` varchar(24) NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `type` enum('arrest','search') NOT NULL DEFAULT 'arrest',
  `reason` varchar(500) NOT NULL,
  `notes` text NULL,
  `incident_id` int NULL,
  `issued_by_citizenid` varchar(50) NOT NULL,
  `issued_by_name` varchar(150) NOT NULL,
  `approved_by_citizenid` varchar(50) NULL,
  `status` enum('active','served','expired','cancelled') NOT NULL DEFAULT 'active',
  `expires_at` datetime NULL,
  `served_at` datetime NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`), UNIQUE KEY `warrant_number` (`warrant_number`),
  KEY `citizen_status` (`citizenid`, `status`), KEY `status_expiry` (`status`, `expires_at`),
  CONSTRAINT `southvale_mdt_warrants_incident_fk` FOREIGN KEY (`incident_id`) REFERENCES `southvale_mdt_incidents` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `southvale_mdt_bolos` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `bolo_number` varchar(24) NOT NULL,
  `subject_type` enum('person','vehicle') NOT NULL,
  `citizenid` varchar(50) NULL,
  `plate` varchar(15) NULL,
  `title` varchar(150) NOT NULL,
  `description` text NOT NULL,
  `reason` varchar(500) NOT NULL,
  `incident_id` int NULL,
  `issued_by_citizenid` varchar(50) NOT NULL,
  `issued_by_name` varchar(150) NOT NULL,
  `status` enum('active','inactive','expired') NOT NULL DEFAULT 'active',
  `expires_at` datetime NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`), UNIQUE KEY `bolo_number` (`bolo_number`),
  KEY `citizen_status` (`citizenid`, `status`), KEY `plate_status` (`plate`, `status`), KEY `status_expiry` (`status`, `expires_at`),
  CONSTRAINT `southvale_mdt_bolos_incident_fk` FOREIGN KEY (`incident_id`) REFERENCES `southvale_mdt_incidents` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `southvale_mdt_citations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `citation_number` varchar(24) NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `incident_id` int NULL,
  `charges` json NOT NULL,
  `fine` int unsigned NOT NULL,
  `notes` text NULL,
  `status` enum('paid','unpaid','void') NOT NULL DEFAULT 'unpaid',
  `paid_at` datetime NULL,
  `issued_by_citizenid` varchar(50) NOT NULL,
  `issued_by_name` varchar(150) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`), UNIQUE KEY `citation_number` (`citation_number`), KEY `citizen_created_at` (`citizenid`, `created_at`),
  CONSTRAINT `southvale_mdt_citations_incident_fk` FOREIGN KEY (`incident_id`) REFERENCES `southvale_mdt_incidents` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `southvale_mdt_arrests` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `arrest_number` varchar(24) NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `incident_id` int NULL,
  `charges` json NOT NULL,
  `fine` int unsigned NOT NULL DEFAULT 0,
  `sentence_minutes` smallint unsigned NOT NULL,
  `status` enum('booked','released','void') NOT NULL DEFAULT 'booked',
  `notes` text NULL,
  `arrested_by_citizenid` varchar(50) NOT NULL,
  `arrested_by_name` varchar(150) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `released_at` datetime NULL,
  PRIMARY KEY (`id`), UNIQUE KEY `arrest_number` (`arrest_number`), KEY `citizen_created_at` (`citizenid`, `created_at`), KEY `status` (`status`),
  CONSTRAINT `southvale_mdt_arrests_incident_fk` FOREIGN KEY (`incident_id`) REFERENCES `southvale_mdt_incidents` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `southvale_mdt_vehicle_flags` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `plate` varchar(15) NOT NULL,
  `reason` varchar(500) NOT NULL,
  `notes` text NULL,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `created_by_citizenid` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `cleared_at` datetime NULL,
  PRIMARY KEY (`id`), KEY `plate_active` (`plate`, `active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
