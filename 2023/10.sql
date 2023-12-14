/*  AoC 2023-10 (https://adventofcode.com/2023/day/10)  */
declare @pipe_sketch nvarchar(max) = replace((select BulkColumn from openrowset(bulk 'C:/repo/stonebr00k/aoc/input/2023/10', single_clob)_), char(13), '');
-- Convert input to JSON, and also translate the symbols to numbers to enable use of the choose()-function instead of case/iif
set @pipe_sketch = concat(N'["', replace(translate(@pipe_sketch, N'S-|7FJL.', N'01234569'), nchar(10), N'","'), N'"]');

drop table if exists #tile, #connection;
create table #tile (
    id varchar(7) not null primary key,
    x tinyint not null,
    y tinyint not null,
    symbol tinyint not null,
    point as geometry::STGeomFromText(concat('point(', id, ')'), 0) persisted
);
create table #connection (
    id varchar(7) not null primary key,
    c1 varchar(7) not null,
    c2 varchar(7) not null,
);

insert into #tile (id, x, y, symbol)
    select id = concat(s.[value], ' ', cast(l.[key] as int) + 1)
        ,x = cast(s.[value] as tinyint) 
        ,y = cast(l.[key] as tinyint) + cast(1 as tinyint)
        ,symbol
    from openjson(@pipe_sketch) l
    cross apply generate_series(1, cast(len(l.[value]) as int)) s
    cross apply (values(cast(substring(l.[value], s.[value], 1) as tinyint))) _(symbol);

insert into #connection (id, c1, c2)
    select id
        ,c1 = concat(c1.x, ' ', c1.y)
        ,c2 = concat(c2.x, ' ', c2.y)
    from #tile t
    -- Find the directions of the two connection points for each tile (S/9 and ./0 not handled) (1 = N, 2 = E, 3 = S, 4 = W)
    cross apply (values(choose(symbol, 2, 1, 3, 2, 1, 1), choose(symbol, 4, 3, 4, 3, 4, 2))) d(d1, d2)
    -- From the directions, calculate xy-coordinates for the connected tiles
    cross apply (values(t.x + choose(d.d1, 0, 1, 0, -1), t.y + choose(d.d1, -1, 0, 1, 0))) c1(x, y)
    cross apply (values(t.x + choose(d.d2, 0, 1, 0, -1), t.y + choose(d.d2, -1, 0, 1, 0))) c2(x, y)
    where c1.x > 0 and c1.y > 0 and c2.x > 0 and c2.y > 0;

declare @the_loop geometry;

with pipe_crawler as (
    select src = t.id, c = c.id, i = 1
    from #tile t
    join #connection c on t.id = c.c1
    where t.symbol = 0
    union all
    select src = pc.c
        ,c = iif(c.c1 = pc.src, c.c2, c.c1)
        ,i = i + 1
    from pipe_crawler pc
    join #connection c on pc.c = c.id
    where pc.src != c.id
)

select @the_loop = geometry::STGeomFromText(concat(
    'polygon((', 
    string_agg(cast(concat(iif(i = 1, src + N',', ''), c) as varchar(max)), ','), 
    '))'
), 0)
from pipe_crawler
option(maxrecursion 0);

select part1 = @the_loop.STLength() / 2
    ,part2 = count(*)
    ,visualization = N'See "Spatial results"-tab in SSMS ->'
    ,the_loop = @the_loop
from #tile t
where point.STWithin(@the_loop) = 1;
go
