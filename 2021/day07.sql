declare @input nvarchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2021/07.input', single_clob) d);
declare @json nvarchar(max) = N'[' + @input + ']';

with input as (
    select position = cast([value] as smallint)
        ,mean = cast(avg(cast([value] as decimal(5,1))) over() as smallint)
    from openjson(@json)
)
,median as (
    select position = cast(avg(1.0 * position) as smallint)
    from (
        select position 
        from input
        order by position offset ((select count(*) from input) - 1) / 2 rows 
        fetch next 1 + (1 - (select count(*) from input) % 2) rows only
    ) as x
)

select part_1 = sum(abs(i.position - m.position))
    ,part_2 = sum(abs(i.mean - i.position) * (abs(i.mean - i.position) + 1) / 2)
from input i
cross join median m;
go