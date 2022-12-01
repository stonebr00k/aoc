declare @input varchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2015/01.input', single_clob) d);
set @input = replace(replace(@input, replicate(nchar(13) + nchar(10), 2), nchar(16)), nchar(13) + nchar(10), nchar(17));

with elevator as (
    select char_pos = s.[value]
        ,[floor] = sum(e.v) over(order by s.[value])
    from generate_series(1, cast(len(@input) as int)) s
    join (values(N'(', 1),(N')', -1)) e(p, v)
        on substring(@input, s.[value], 1) = e.p
)

select part1 = sum(iif(char_pos = len(@input), [floor], null))
    ,part2 = min(iif([floor] = -1, char_pos, null))
from elevator;
go
