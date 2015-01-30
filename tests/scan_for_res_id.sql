/*
  TODO:
  first - find 'StoreBooking Finished Result=27679357' message
  then trace back to negative res id
  then scan for both positive and negative res id
  then bug - iterate over objects

  SCAN_FOR_RES - scan single table for two res ids (positive and negative, but can actually be any two IDs.
  Pass same value to scan for single res id).

  scan_all_tables - scan sevelar tables in a schema selected by table name pattern  

  note: all temporary tables will be created in current schema!
  note: not thread-safe, cannot be called in parallel!
*/

use 8396_load1;

/* Loop thourg all tables */
delimiter ;;

drop procedure if exists TRACE ;;
create procedure TRACE(IN logLine VARCHAR(500))
begin
	CREATE TABLE IF NOT EXISTS TRACE (tstamp datetime, log_line VARCHAR(500));
	INSERT INTO TRACE VALUES (CURRENT_TIMESTAMP, logLine);
end ;;

delimiter ;



DROP PROCEDURE IF EXISTS SCAN_FOR_RES;
DELIMITER ;;

CREATE PROCEDURE SCAN_FOR_RES(IN resIdNegative LONG, 
								IN resIdPositive LONG, 
								IN schemaName VARCHAR(255), 
								IN tableName VARCHAR(300),
								IN tableType VARCHAR(5)) /* tableType in ('IO', 'nonIO') */
BEGIN
DECLARE n INT DEFAULT 0;
DECLARE i INT DEFAULT 0;
DECLARE o_n INT DEFAULT 0;
DECLARE o_i INT DEFAULT 0;
DECLARE obj_id BIGINT(20);
DECLARE msg LONGTEXT;
DECLARE rslt LONGTEXT;
DECLARE rq LONGTEXT;
DECLARE pieceUsesRes BOOL DEFAULT FALSE;
DECLARE truncatedName VARCHAR(300) DEFAULT tableName;

/* create target table */
DROP TABLE IF EXISTS TMP_RES;
SET @t1=CONCAT('CREATE TABLE TMP_RES SELECT * FROM `', schemaName,'`.`', tableName,'` LIMIT 0,0');
PREPARE stmt FROM @t1;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

/* create all temporary tables */

DROP TABLE IF EXISTS TMP_OBJ;
CREATE TABLE TMP_OBJ 
    SELECT * FROM TMP_RES LIMIT 0,0;

DROP TABLE IF EXISTS TMP_OBJ_IDS;
SET @t1=CONCAT(
'CREATE TABLE TMP_OBJ_IDS 
    select distinct(object_id) from `', schemaName,'`.`', tableName,'` 
            where 
                message = CONCAT(\'GetResID Finished Result=\', ',resIdNegative,')  
                OR message = CONCAT(\'GetResID Finished Result=\', ',resIdPositive,')
                OR result = \'',resIdNegative,'\' 
                OR result = \'',resIdPositive,'\''
);
PREPARE stmt FROM @t1;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

DROP TABLE IF EXISTS TMP;
CREATE TABLE TMP SELECT * FROM TMP_OBJ LIMIT 0,0;

DROP TABLE IF EXISTS TMP_ROW;
CREATE TABLE TMP_ROW SELECT * FROM TMP_OBJ LIMIT 0,0;

SET o_i = 0;
SELECT COUNT(*) FROM TMP_OBJ_IDS INTO o_n;

WHILE o_i<o_n DO 
    SELECT object_id INTO obj_id from TMP_OBJ_IDS LIMIT o_i, 1;
	
	CALL TRACE(CONCAT('loop iteration for object id ', obj_id));	
    
    DELETE FROM TMP_OBJ;
	SET @t1=CONCAT(
	'INSERT INTO TMP_OBJ 
        SELECT * FROM `', schemaName,'`.`', tableName,'`
            where object_id = ',obj_id
	);
	PREPARE stmt FROM @t1;
	EXECUTE stmt;
	DEALLOCATE PREPARE stmt;    

    SELECT COUNT(*) FROM TMP_OBJ INTO n;

    SET i=0;

    /* clean tempporary table */

    DELETE FROM 8396_load1.TMP;

    WHILE i<n DO 

        /* pick up next line from objects that we are interested in (that ever processed the resId) and get it's message */
        DELETE FROM TMP_ROW;
        INSERT INTO TMP_ROW SELECT * FROM TMP_OBJ LIMIT i,1;
        INSERT INTO TMP SELECT * FROM TMP_ROW;
        SELECT message, result, req INTO msg, rslt, rq from TMP_ROW;
        IF ((tableType = 'nonIO') AND (msg in (CONCAT('GetResID Finished Result=', resIdPositive), CONCAT('GetResID Finished Result=', resIdNegative)))) 
			OR ((tableType = 'IO' AND (rslt in (resIdPositive, resIdNegative)))) THEN
			/* this works for non-IO corba trace logs */
            SET pieceUsesRes = TRUE;
        END IF;        

        DELETE FROM 8396_load1.TMP_ROW;
    
        /* check if this line ends the swbooking processing with releaseinstance, and if so pass all collected piece to target table */
		IF ((tableType = 'nonIO') AND (msg = 'ReleaseInstance Finished')) OR 
			((tableType = 'IO') AND (rq = 'ReleaseInstance')) THEN
	    	IF pieceUsesRes THEN
                INSERT INTO TMP_RES SELECT * FROM TMP;
		    END IF;
            DELETE FROM TMP;
            SET pieceUsesRes = FALSE;
        END IF;

        SET i = i + 1;
    END WHILE;

    IF pieceUsesRes THEN
        INSERT INTO TMP_RES SELECT * FROM 8396_load1.TMP;
    END IF;

    SET o_i = o_i + 1;
END WHILE;


SET truncatedName = IF(length(truncatedName) > 50, CONCAT(substring(truncatedName FROM 1 FOR 47), '___'), truncatedName);
SET @t1=CONCAT('ALTER TABLE TMP_RES RENAME TO `', schemaName,'`.`RES_', resIdPositive, '_', truncatedName,'`');
PREPARE stmt FROM @t1;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

DROP TABLE IF EXISTS TMP_OBJ;
DROP TABLE IF EXISTS TMP_OBJ_IDS;
DROP TABLE IF EXISTS TMP_ROW;
DROP TABLE IF EXISTS TMP;

End;
;;

DELIMITER ;





/* Loop thourg all tables */
delimiter ;;

drop procedure if exists scan_all_tables ;;
create procedure scan_all_tables(IN resIdNegative LONG, IN resIdPositive LONG, In schemaName VARCHAR(255), IN pattern VARCHAR(255), IN tableType VARCHAR(5))
begin
    DECLARE done int default false;
    DECLARE tableName CHAR(255);

    DECLARE cur1 cursor for SELECT distinct(TABLE_NAME) FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = schemaName and TABLE_NAME LIKE pattern;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    open cur1;

    myloop: loop
        fetch cur1 into tableName;
        if done then
            leave myloop;
        end if;
        call SCAN_FOR_RES(resIdNegative, resIdPositive, schemaName, tableName, tableType);
    end loop;

    close cur1;
end ;;

delimiter ;

call scan_all_tables(27679357, 27679357, '8396_load1', 'io_162_%', 'IO');


/* CALL SCAN_FOR_RES(27613328, 27613328, '');*/