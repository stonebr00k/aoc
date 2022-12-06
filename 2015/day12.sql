declare @ nvarchar(max) = trim(nchar(10) from (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2015/12.input', single_clob) d));

with parser as (
    select v = @
        ,t = cast(iif(left(@, 1) = N'[', 4, 5) as tinyint)
        ,i = cast(0 as bit)
    union all
    select x.[value]
        ,x.[type]
        ,p.i | cast(iif(x.[type] = 5 and exists(select * from openjson(x.[value]) where [value] = N'red'), 1, 0) as bit)
    from parser p
    cross apply openjson(p.v) x
    where p.t in (4, 5)
)

select part1 = sum(cast(v as int))
    ,part2 = sum(iif(i = 1, 0, cast(v as int)))
from parser
where t = 2;