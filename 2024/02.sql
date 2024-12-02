/*  AoC 2024-01 (https://adventofcode.com/2024/day/2)  */
declare @input nvarchar(max) = replace((select BulkColumn from openrowset(bulk 'C:/repo/stonebr00k/aoc/input/2024/02', single_clob)_), nchar(13), '');
declare @reports_json nvarchar(max) = concat(N'[[', replace(replace(@input, N' ', N','), nchar(10), N'],[') ,N']]');

with report as (
    select id = cast([key] as smallint)
        ,levels = [value]
        ,[length] = cast(len([value]) - len(replace([value], N',', N'')) as int)
    from openjson(@reports_json)
)

select part_1 = count(iif(pop_level = -1, 1, null))
    ,part_2 = count(*)
from report r
cross apply (
    select top 1 pop_level
    from (
        select pop_level = pop.[value]
            ,level_diff = cast(l.[value] as int) - lag(cast(l.[value] as int)) over(partition by r.id, pop.[value] order by cast(l.[key] as tinyint))
        from openjson(r.[levels]) l
        cross apply generate_series(-1, r.[length]) pop
        where [key] != pop.[value]
    ) _
    group by pop_level
    having max(abs(level_diff)) in (1,2,3) and max(sign(level_diff)) = min(sign(level_diff))
    order by pop_level
) _;
go