declare @input nvarchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2021/06.input', single_clob) d);
declare @json nvarchar(max) = N'[' + @input + ']';

with fish_simulator as (
    select [day] = 0 
        ,t0 = cast(sum(iif([value] = 0, 1, 0)) as bigint)
        ,t1 = cast(sum(iif([value] = 1, 1, 0)) as bigint)
        ,t2 = cast(sum(iif([value] = 2, 1, 0)) as bigint)
        ,t3 = cast(sum(iif([value] = 3, 1, 0)) as bigint)
        ,t4 = cast(sum(iif([value] = 4, 1, 0)) as bigint)
        ,t5 = cast(sum(iif([value] = 5, 1, 0)) as bigint)
        ,t6 = cast(sum(iif([value] = 6, 1, 0)) as bigint)
        ,t7 = cast(sum(iif([value] = 7, 1, 0)) as bigint)
        ,t8 = cast(sum(iif([value] = 8, 1, 0)) as bigint)
    from openjson(@json)
    union all
    select [day] = [day] + 1 
        ,t0 = t1
        ,t1 = t2
        ,t2 = t3
        ,t3 = t4
        ,t4 = t5
        ,t5 = t6 
        ,t6 = t7 + t0
        ,t7 = t8
        ,t8 = t0
    from fish_simulator
    where [day] < 256
)

select part_1 = sum(iif([day] = 80, t0 + t1 + t2 + t3 + t4 + t5 + t6 + t7 + t8, 0))
    ,part_2 = sum(iif([day] = 256, t0 + t1 + t2 + t3 + t4 + t5 + t6 + t7 + t8, 0))
from fish_simulator
option(maxrecursion 0)