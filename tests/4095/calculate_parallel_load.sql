SELECT distinct(t1.tstamp) as req_time,
       avg(t1.duration+1) as avg_duration, 
       max(t1.duration+1) as max_duration, 
       (select count(*) from test.22_ro1_20017_all_io t2
       where UNIX_TIMESTAMP(t2.tstamp) <= UNIX_TIMESTAMP(req_time) 
       and UNIX_TIMESTAMP(t2.tstamp_out) >= UNIX_TIMESTAMP(req_time))
       as parallel
from test.22_ro1_20017_all_io t1
where UNIX_TIMESTAMP(t1.tstamp) > UNIX_TIMESTAMP('2014-01-22 18:55:00')
group by req_time
order by req_time