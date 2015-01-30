/*
  create table with
  all rows from all tables by table name pattern
  sorted by time
*/


/* Loop thourg all tables */
delimiter ;;

drop procedure if exists select_all_tables ;;
create procedure select_all_tables
				(In schemaName VARCHAR(255), 
				IN pattern VARCHAR(255), 
				IN resultTableName VARCHAR(255), 
				IN sortOrder VARCHAR(255))
begin
    DECLARE done int default false;
    DECLARE tableName CHAR(255);
    DECLARE tableCreated BOOL DEFAULT FALSE;

    DECLARE cur1 cursor for SELECT distinct(TABLE_NAME) FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = schemaName and TABLE_NAME LIKE pattern;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    open cur1;

    myloop: loop
        fetch cur1 into tableName;
        if done then
            leave myloop;
        end if;
        
		IF tableCreated = false then
			/* create table */
			DROP TABLE IF EXISTS TMP;
			SET @t1=CONCAT('CREATE TABLE TMP SELECT \'12345678901234567890123456789012345678901234567890123456789012345678901234567890\' log, t.* FROM `', schemaName,'`.`', tableName,'` t LIMIT 0,0');
			PREPARE stmt FROM @t1;
			EXECUTE stmt;
			DEALLOCATE PREPARE stmt;
			SET tableCreated = true;
		END IF;

		/* append */
		SET @t1=CONCAT('INSERT INTO TMP SELECT \'',tableName,'\' log, t.* FROM `', schemaName,'`.`', tableName,'` t');
		PREPARE stmt FROM @t1;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;

    end loop;

    close cur1;

	IF tableCreated = true THEN
		SET @t1=CONCAT('DROP TABLE IF EXISTS `', schemaName,'`.`', resultTableName,'`');
		PREPARE stmt FROM @t1;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;    
		SET @t1=CONCAT('CREATE TABLE `', schemaName,'`.`', resultTableName,'` SELECT * FROM TMP ORDER BY ', sortOrder);
		PREPARE stmt FROM @t1;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
		DROP TABLE IF EXISTS TMP;
	END IF;

end ;;

delimiter ;

/* call to merge logs that ar not IO */

/* call select_all_tables('8396_load1', 'res_27679357_162_%', 'res_27679357', 'tstamp, tstamp_ms, log'); */

/* call to merge IO logs */

call select_all_tables('8396_load1', 'res_27679357_io_%', 'res_io_27679357', 'req_tstamp, req_tstamp_ms, duration, log'); 