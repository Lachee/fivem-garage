-- ----------------------------------------------------
-- Applies a migration to make this extension work
-- Author: Lachee
-- ----------------------------------------------------

ALTER TABLE owned_vehicles ADD `garage` VARCHAR(200) DEFAULT 'OUT';
ALTER TABLE owned_vehicles ADD `state` int(11) DEFAULT NULL;