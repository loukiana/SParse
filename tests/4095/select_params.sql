SELECT 
/*CAST(((UNIX_TIMESTAMP(t.search_to) - UNIX_TIMESTAMP(t.search_from)) / 86400) AS UNSIGNED INTEGER) as search_dateRange,
t.**/
count(*) as cnt,
avg(t1.duration) as avg_duration, 
max(t1.duration) as max_duration, 
SEC_TO_TIME(FLOOR((TIME_TO_SEC(t1.tstamp)+300)/600)*600) as timeminute
FROM 
22_ro1_20017_io t1
where 
1
and t1.search_ships = 0
and t1.search_priceMin is null
and t1.search_priceMax is null
and t1.search_pkgTypeAttr is null
and t1.search_pkgLenMax is null
and t1.search_pkgLenMin is null
and t1.search_referral is null
and UNIX_TIMESTAMP(t1.tstamp) > UNIX_TIMESTAMP('2014-01-22 00:00:00')
and UNIX_TIMESTAMP(t1.tstamp) < UNIX_TIMESTAMP('2014-01-22 23:59:59')
/*and duration > 10*/
/*order by avail_size*/
/*order by duration desc*/
group by timeminute
order by timeminute