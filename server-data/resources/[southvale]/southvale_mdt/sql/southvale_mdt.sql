CREATE TABLE IF NOT EXISTS `southvale_mdt_incidents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(150) NOT NULL,
  `details` text NOT NULL,
  `citizens` text DEFAULT NULL COMMENT 'JSON array of {citizenid, name}',
  `officer_citizenid` varchar(50) NOT NULL,
  `officer_name` varchar(150) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `officer_citizenid` (`officer_citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
