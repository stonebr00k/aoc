/*  AoC 2022-13 (https://adventofcode.com/2022/day/13)  */
create or alter function is_correct_array_order (@1 nvarchar(max), @2 nvarchar(max))
returns table as return (
    with compare as (
        select hid = cast('/' as nvarchar(max))
            ,l = cast(@1 as nvarchar(max)) 
            ,r = cast(@2 as nvarchar(max))
            ,t = cast(4 as tinyint)
            ,x = null
        union all
        select hid = cast(hid + cast(s.[value] as nvarchar(13)) + '/' as nvarchar(max))
            ,l = iif(r.[type] = 4 and l.[type] = 2, quotename(l.[value]), l.[value])
            ,r = iif(l.[type] = 4 and r.[type] = 2, quotename(r.[value]), r.[value])
            ,t = greatest(l.[type], r.[type])
            ,x = case
                    when l.[type] = 2 and r.[type] = 2 then nullif(cast(r.[value] as int) - cast(l.[value] as int), 0)
                    when l.[type] = 4 and r.[type] = 4 then null
                    when l.[type] is null then 1
                    when r.[type] is null then -1
                end
        from compare c
        cross apply generate_series(0, 99) s
        outer apply (select * from openjson(c.l) where cast([key] as int) = s.[value]) l
        outer apply (select * from openjson(c.r) where cast([key] as int) = s.[value]) r
        where c.t = 4 and isnull(l.[key], r.[key]) is not null
    )

    select [value] = cast(cast(max(x) as bit) as int)
    from (
        select x = greatest(0, first_value(x) ignore nulls over (order by hierarchyid::Parse(hid)))
        from compare
    ) x
);
go

declare @ varchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/13.input', single_clob) d);
declare @1 varchar(max) = '[[' + replace(replace(trim(char(10) from @), char(10) + char(10), '],['), char(10), ',') + ']]';
declare @2 varchar(max) = '[' + replace(replace(trim(char(10) from @), char(10) + char(10), ','), char(10), ',') + ']';

select part1 = sum(cast(p.[key] as int) + 1)
from openjson(@1) p
cross apply is_correct_array_order(json_query(p.[value], '$[0]'), json_query(p.[value], '$[1]')) c
where c.[value] = 1;

select part2 = (sum(c1.[value]) + 1) * (sum(c2.[value]) + 2)
from openjson(@2) p
cross apply is_correct_array_order(p.[value], N'[[2]]') c1
cross apply is_correct_array_order(p.[value], N'[[6]]') c2;
