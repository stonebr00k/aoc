declare @input varchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2015/03.input', single_clob) d);
set @input = replace(replace(@input, replicate(char(13) + char(10), 2), char(16)), char(13) + char(10), char(17));

with visits as (
    select visit_no = i.[value]
        ,x1 = sum(pc.x) over(order by i.[value])
        ,y1 = sum(pc.y) over(order by i.[value])
        ,x2 = sum(pc.x) over(partition by abs(i.[value] % 2) order by i.[value])
        ,y2 = sum(pc.y) over(partition by abs(i.[value] % 2) order by i.[value])
    from generate_series(0, cast(len(@input) as int)) i
    join (values('', 0, 0),('^', 0, 1),('v', 0, -1),('>', 1, 0),('<', -1, 0)) pc(chr, x, y)
        on substring(@input, i.[value], 1) = pc.chr
)

select part1 = count(distinct cast(x1 as binary(8)) + cast(y1 as binary(8)))
    ,part2 = count(distinct cast(x2 as binary(8)) + cast(y2 as binary(8)))
from visits;
go
