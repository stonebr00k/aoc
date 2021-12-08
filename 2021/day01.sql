declare @input nvarchar(max) = (
    select BulkColumn
    from openrowset(bulk 'c:/temp/aoc/2021/input01.dat', single_clob) d --<< Enter path to your input file here
);

with depth as (
    select [current] = d.[value]
        ,previous = lag(d.[value]) over(order by (select null))
        ,current_window = sum(d.[value]) over(order by (select null) rows between current row and 2 following)
        ,previous_window = sum(d.[value]) over(order by (select null) rows between 1 preceding and 1 following)
        ,use_window = cast(iif(count(d.[value]) over(order by (select null) rows between 1 preceding and 2 following) = 4, 1, 0) as bit)
    from string_split(@input, nchar(10)) input
    cross apply (
        select [value] = cast(trim(nchar(13) from input.[value]) as int)
    ) d
)

select part_1 = sum(iif([current] > previous, 1, 0))
    ,part_2 = sum(iif(use_window = 1 and current_window > previous_window, 1, 0))
from depth;
go
