CREATE TABLE `vehicles` (
	`owner` INT(11) NULL DEFAULT NULL,
	`plate` VARCHAR(255) NULL DEFAULT NULL,
	`glovebox` LONGTEXT NULL DEFAULT '[]',
	`trunk` LONGTEXT NULL DEFAULT '[]',
	`properties` LONGTEXT NULL DEFAULT '[]',
	`stored` INT(11) NULL DEFAULT NULL,
	INDEX `owner` (`owner`) USING BTREE,
	CONSTRAINT `vehowner` FOREIGN KEY (`owner`) REFERENCES `andy`.`characters` (`character_id`) ON UPDATE CASCADE ON DELETE CASCADE
);