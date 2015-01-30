/*
  create IO table for specified table

  CREATE_IO_TABLE - create io table for specified table in specified schema
  io_all_tables - create IO tables for all tables in schema, tables selected by table name pattern
*/

DROP PROCEDURE IF EXISTS CREATE_IO_TABLE;
DELIMITER ;;

CREATE PROCEDURE CREATE_IO_TABLE(IN schemaName VARCHAR(50), IN tableName VARCHAR(300))
BEGIN
DECLARE truncatedName VARCHAR(300) DEFAULT tableName;
SET truncatedName = IF(length(truncatedName) > 50, CONCAT(substring(truncatedName FROM 1 FOR 47), '___'), truncatedName);

SET @t1=CONCAT('CREATE TABLE `', schemaName,'`.`IO_', truncatedName,'` 
 select  
 tin.node,
 tin.tstamp as req_tstamp,
 tin.tstamp_ms as req_tstamp_ms,
 tout.tstamp as resp_tstamp,
 tout.tstamp_ms as resp_tstamp_ms,
  1000*(UNIX_TIMESTAMP(TIMESTAMP(tout.tstamp)) - UNIX_TIMESTAMP(TIMESTAMP(tin.tstamp))) + (tout.tstamp_ms - tin.tstamp_ms) as duration,
 tin.someID,
 tin.object,
 tin.object_id,
 tin.request_id,
 tin.message_len,
 tin.message,
 tin.req,
 tout.result
from 
`', schemaName,'`.`', tableName,'` tin join
`', schemaName,'`.`', tableName,'` tout on tin.request_id = tout.request_id and tin.direction=\'In\' and tout.direction<>\'In\' and  tin.req = tout.req
');
PREPARE stmt FROM @t1;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

End;
;;

DELIMITER ;



/* Loop through all tables */
delimiter ;;

drop procedure if exists io_all_tables ;;
create procedure io_all_tables(In schemaName VARCHAR(50), IN pattern VARCHAR(255))
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


		/* temp fix */
/*SET @t1=CONCAT('UPDATE `', schemaName,'`.`', tableName,'` 
SET req=\'ReleaseInstance\'
where req = \'ReleaseInstance();\'');
PREPARE stmt FROM @t1;
EXECUTE stmt;
DEALLOCATE PREPARE stmt; */

        call create_io_table(schemaName, tableName);
    end loop;

    close cur1;
end ;;

delimiter ;

call io_all_tables('8396_load1', '162_%');

/*CALL CREATE_IO_TABLE('8396_load1', '162_227_ro_22091_swapitrace_9f74ffd2_98c2_4f1b_bbd7_e1a051c912fc');*/




