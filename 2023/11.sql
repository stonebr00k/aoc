/*  AoC 2023-11 (https://adventofcode.com/2023/day/11)  */
declare @image nvarchar(max) = replace((select BulkColumn from openrowset(bulk 'C:/repo/stonebr00k/aoc/input/2023/11', single_clob)_), char(13), '');
set @image = concat(N'["', replace(translate(@image, '.#', '01'), nchar(10), N'","'), N'"]');

with the_universe as (
    select part
        ,location_id = row_number() over(order by cast(i.[key] as tinyint), cast(s.[value] as tinyint))
        ,is_galaxy = cast(is_galaxy as bit)
        ,x
        ,y
        ,exp_x = iif(sum(is_galaxy) over(partition by part, x) = 0, expansion, 0)
        ,exp_y = iif(sum(is_galaxy) over(partition by part, y) = 0, expansion, 0)
    from openjson(@image) i
    cross apply generate_series(1, cast(len(i.[value]) as int)) s
    cross apply (
        select is_galaxy = cast(substring(i.[value], s.[value], 1) as tinyint)
            ,x = cast(s.[value] as tinyint)
            ,y = cast(i.[key] as tinyint) + cast(1 as tinyint)
    ) _
    cross apply (values(1, 1), (2, cast(999999 as bigint))) __(part, expansion)
)
,expanded_universe as (
    select part
        ,location_id
        ,is_galaxy
        ,x = x + sum(exp_x) over(partition by part, y order by x rows unbounded preceding)
        ,y = y + sum(exp_y) over(partition by part, x order by y rows unbounded preceding)
    from the_universe
)

select part = a.part
    ,answer = sum(abs(a.x - b.x) + abs(a.y - b.y))
from expanded_universe a
join expanded_universe b
    on a.part = b.part 
    and a.location_id < b.location_id
where a.is_galaxy = 1 and b.is_galaxy = 1
group by a.part;
go
