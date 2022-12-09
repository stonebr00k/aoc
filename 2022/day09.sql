declare @ varchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/09.input', single_clob) d);
set @ = '[["' + replace(replace(trim(char(10) from @), char(10), '],["'), ' ', '",') + ']]';
drop table if exists #pos;

select k = isnull(cast(0 as tinyint), 0)
    ,i = isnull(cast(row_number() over(order by m.i, s.[value]) as int) ,0)
    ,x = isnull(sum(p.x) over(order by m.i, s.[value]), 0)
    ,y = isnull(sum(p.y) over(order by m.i, s.[value]), 0)
into #pos
from openjson(@) i
cross apply (values(
    cast(i.[key] as int),
    cast(json_value(i.[value], '$[0]') as char(1)), 
    cast(json_value(i.[value], '$[1]') as tinyint)
)) m(i, d, s)
cross apply generate_series(cast(1 as tinyint), s) s
join (values('U',0,1),('D',0,-1),('L',-1,0),('R',1,0)) p(d, x, y)
    on m.d = p.d;

create unique clustered index ucix_#pos on #pos (k, i);

declare @knot tinyint = 1;

while @knot <= 9 begin;
    with tail as (
        select i = cast(0 as int), x = 0, y = 0, chng = cast(1 as bit)
        union all
        select i = p.i
            ,x = iif(m.x = 0, iif(m.y = 0, t.x, p.x), t.x + m.x)
            ,y = iif(m.y = 0, iif(m.x = 0, t.y, p.y), t.y + m.y)
            ,chng = cast(m.x | m.y as bit)
        from tail t
        join #pos p on t.i + 1 = p.i and p.k = @knot - 1
        cross apply (values(
            iif(abs(p.x - t.x) = 2, 1 + least(p.x - t.x, 0), 0),
            iif(abs(p.y - t.y) = 2, 1 + least(p.y - t.y, 0), 0)
        )) m(x, y)
    )

    insert into #pos (k, i, x, y)
        select @knot, row_number() over(order by i), x, y
        from tail
        where chng = 1
        option (maxrecursion 0)

    set @knot += 1;
end;

select part1 = sum(iif(k = 1, 1, 0))
    ,part2 = sum(iif(k = 9, 1, 0))
from (select distinct k, x, y from #pos where k in (1, 9)) p1;

/* Visualization of part 2 - run this query in SSMS and go to "Spatial results" tab:
    select point = geometry::Point(x, y, 0).STBuffer(0.4)
    from (select distinct k, x, y, i = min(i) from #pos group by k, x, y) x
    where k = 2
    order by k, i;
*/