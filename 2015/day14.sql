declare @ varchar(max) = trim(nchar(10) from (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2015/14.input', single_clob) d));
drop table if exists #race;

set @ = '[["' + replace(replace(replace(replace(replace(@,
    ' can fly ', '",'),
    ' km/s for ', ','),
    ' seconds, but then must rest for ', ','),
    ' seconds.', ''),
    char(10), N'],["') + ']]';

select deer
    ,sec = [value]
    ,sec_dist = iif(isnull(nullif([value] % (fly + rest), 0), fly + rest) <= fly, speed, 0)
    ,tot_dist = cast(null as int)
    ,pt = cast(null as tinyint)
into #race
from openjson(@) with (deer varchar(8) '$[0]', speed int '$[1]', fly int '$[2]', rest int '$[3]')
cross join generate_series(1, 2503);

update r set tot_dist = r2.tot_dist
from #race r
join (select deer, sec, tot_dist = sum(sec_dist) over(partition by deer order by sec) from #race) r2
    on r.deer = r2.deer and r.sec = r2.sec;

update r set pt = 1
from #race r
join (select sec, tot_dist = max(tot_dist) from #race group by sec) r2
    on r.sec = r2.sec and r.tot_dist = r2.tot_dist;

select part1 = (select top 1 sum(sec_dist) from #race group by deer order by 1 desc)
    ,part2 = (select top 1 sum(pt) from #race group by deer order by 1 desc);