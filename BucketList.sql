-- ====================================================================
--  BucketList Database Schema (Corrected and Improved Version)
-- ====================================================================

-- Create the user table
CREATE TABLE `tbl_user` (
  `user_id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_name` VARCHAR(45) NULL,
  `user_username` VARCHAR(45) NULL,
  `user_password` VARCHAR(45) NULL,
  PRIMARY KEY (`user_id`));

-- Insert a default user for initial setup
INSERT INTO tbl_user (user_id, user_name, user_username, user_password)
VALUES (10, 'ahmed', 'ahmed', 'ahmed');

-- Stored Procedure to create a user
DROP PROCEDURE IF EXISTS `sp_createUser`;
DELIMITER $$
CREATE PROCEDURE `sp_createUser`(
    IN p_name VARCHAR(45),       -- FIX: Matched column size
    IN p_username VARCHAR(100),  -- Increased for safety
    IN p_password VARCHAR(45)    -- FIX: Matched column size
)
BEGIN
    if ( select exists (select 1 from tbl_user where user_username = p_username) ) THEN
        select 'Username Exists !!';
    ELSE
        insert into tbl_user
        (
            user_name,
            user_username,
            user_password
        )
        values
        (
            p_name,
            p_username,
            p_password
        );
    END IF;
END$$
DELIMITER ;

-- Stored Procedure to validate a login
DROP PROCEDURE IF EXISTS `sp_validateLogin`;
DELIMITER $$
CREATE PROCEDURE `sp_validateLogin`(
    IN p_username VARCHAR(100)  -- CRITICAL FIX: Increased size from 20 to 100
)
BEGIN
    select * from tbl_user where user_username = p_username;
END$$
DELIMITER ;

-- Create the wish table
CREATE TABLE `tbl_wish` (
  `wish_id` int(11) NOT NULL AUTO_INCREMENT,
  `wish_title` varchar(45) DEFAULT NULL,
  `wish_description` varchar(5000) DEFAULT NULL,
  `wish_user_id` int(11) DEFAULT NULL,
  `wish_date` datetime DEFAULT NULL,
  PRIMARY KEY (`wish_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;

-- Stored Procedure to add a wish
DROP PROCEDURE IF EXISTS `sp_addWish`;
DELIMITER $$
CREATE PROCEDURE `sp_addWish`(
    IN p_title varchar(45),
    IN p_description varchar(1000),
    IN p_user_id bigint
)
BEGIN
    insert into tbl_wish(
        wish_title,
        wish_description,
        wish_user_id,
        wish_date
    )
    values
    (
        p_title,
        p_description,
        p_user_id,
        NOW()
    );
END$$
DELIMITER ;

-- Stored Procedure to get wishes by user
DROP PROCEDURE IF EXISTS `sp_GetWishByUser`;
DELIMITER $$
CREATE PROCEDURE `sp_GetWishByUser` (
    IN p_user_id bigint
)
BEGIN
    select * from tbl_wish where wish_user_id = p_user_id;
END$$
DELIMITER ;