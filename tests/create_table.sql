use test;
create table trace02 (
 node varchar(5),
 tstamp datetime,
 tstamp_ms int,
 someID bigint,
 object varchar(25),
 object_id bigint,
 direction varchar(3),
 request_id bigint,
 message_len bigint,
 message longtext,
 req varchar(30),
 result longtext
);


