/*  AoC 2022-08 (https://adventofcode.com/2022/day/8)  */
declare @ varchar(max) = trim(nchar(10) from (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/08.input', single_clob) d));
set @ = '["' + replace(replace(@, ' ', '","'), char(10), '","') + N'"]';

drop table if exists #woods;

select x = isnull(cast(x.[value] as tinyint), 0)
    ,y = isnull(cast(y.[key] as tinyint) + 1, 0)
    ,h = isnull(cast(substring(y.[value], x.[value], 1) as smallint), 0)
into #woods
from openjson(@) y
cross apply generate_series(1, cast(len([value]) as int)) x;

create unique clustered index ucix_#woods on #woods (x, y, h);

select part1 = sum(cast(is_visible as int))
from (
    select is_visible = 
        cast(iif(h > isnull(max(h) over (partition by y order by x  asc rows between unbounded preceding and 1 preceding), -1), 1, 0) as bit) |
        cast(iif(h > isnull(max(h) over (partition by y order by x desc rows between unbounded preceding and 1 preceding), -1), 1, 0) as bit) |
        cast(iif(h > isnull(max(h) over (partition by x order by y  asc rows between unbounded preceding and 1 preceding), -1), 1, 0) as bit) |
        cast(iif(h > isnull(max(h) over (partition by x order by y desc rows between unbounded preceding and 1 preceding), -1), 1, 0) as bit)
    from #woods w
) x;

select part2 = max(u*r*d*l)
from #woods w
outer apply(select top 1 y from #woods where x = w.x and y < w.y and h >= w.h order by y desc) u
outer apply(select top 1 x from #woods where y = w.y and x > w.x and h >= w.h order by x asc) r
outer apply(select top 1 y from #woods where x = w.x and y > w.y and h >= w.h order by y asc) d
outer apply(select top 1 x from #woods where y = w.y and x < w.x and h >= w.h order by x desc) l
cross apply (
    select u = w.y - isnull(u.y, 1)
        ,r = isnull(r.x, (select max(x) from #woods where y = 1)) - w.x
        ,d = isnull(d.y, (select max(y) from #woods where x = 1)) - w.y
        ,l = w.x - isnull(l.x, 1)
) x;
