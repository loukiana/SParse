SELECT 
tstamp_out, 
avail_size,
duration
FROM 
22_ro1_20017_io
where 
UNIX_TIMESTAMP(tstamp) > UNIX_TIMESTAMP('2014-01-22 17:15:00')
and
UNIX_TIMESTAMP(tstamp) < UNIX_TIMESTAMP('2014-01-22 21:10:00')
/*and duration > 30*/
/*order by avail_size*/
order by tstamp_out
