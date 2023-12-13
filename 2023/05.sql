/*  AoC 2023-05 (https://adventofcode.com/2023/day/5)  */
declare @ nvarchar(max) = replace((select BulkColumn from openrowset(bulk 'C:/repo/stonebr00k/aoc/input/2023/05', single_clob)_), nchar(13), N'');
declare @json nvarchar(max) = concat(N'[', (
    select string_agg(concat(N'{"name":"', [name], N'"', N',', N'"values":[', lb, [values], rb, N']}'), N',')
    from string_split(replace(@, replicate(nchar(10), 2), nchar(17)), nchar(17), 1)
    cross apply (
        select [name] = substring([value], 1, charindex(N' ', [value]) - 1)
            ,lb = iif(charindex(N' map', [value]) > 0, N'[', N'')
            ,rb = iif(charindex(N' map', [value]) > 0, N']', N'')
            ,[values] = replace(replace(substring([value], patindex(N'%[1-9]%', [value]), len([value])), nchar(10), N'],['), N' ', N',')
    ) _
), N']');

-- Part 1
with almanac as (
    select map = x.map
        ,dst_start = x.dst_start
        ,src_start = x.src_start
        ,src_end = x.src_start + x.ln - 1
        ,ln = iif(v.[type] = 2, 1, json_value(v.[value], N'$[2]'))
    from openjson(@json) m
    cross apply openjson(m.[value], N'$.values') v
    cross apply (
        select map = cast(m.[key] as tinyint)
            ,dst_start = cast(iif(v.[type] = 2, v.[value], json_value(v.[value], N'$[0]')) as bigint)
            ,src_start = cast(iif(v.[type] = 2, v.[value], json_value(v.[value], N'$[1]')) as bigint)
            ,ln = cast(iif(v.[type] = 2, 1, json_value(v.[value], N'$[2]')) as bigint)
    ) x
)
,location_finder as (
    select map = map
        ,mapped = src_start
    from almanac
    where map = 0
    union all
    select map = cast(lf.map + 1 as tinyint)
        ,mapped = isnull(x.mapped, lf.mapped)
    from location_finder lf
    outer apply (
        select mapped = lf.mapped - src_start + dst_start
        from almanac
        where map = lf.map + 1
            and lf.mapped between src_start and src_end
    ) x
    where lf.map < 7
)

select top 1 part1 = mapped
from location_finder
order by map desc
    ,mapped asc;

-- Part 2
with almanac as (
    select map = cast(0 as tinyint)
        ,dst_start = max(x.range_start)
        ,dst_end = max(x.range_start) + max(x.ln)
        ,src_start = cast(-1 as bigint)
        ,src_end = cast(-1 as bigint)
    from openjson(@json, N'$[0].values')
    cross apply (
        select range_start = iif(cast([key] as tinyint) % 2 = 0, cast([value] as bigint), null)
            ,ln = iif(cast([key] as tinyint) % 2 = 1, cast([value] as bigint), null)
            ,pair_id = cast([key] as tinyint) + ~cast((cast([key] as tinyint) % 2) as bit)
    ) x
    group by pair_id
    union all
    select map = x.map
        ,dst_start = x.dst_start
        ,dst_end = x.dst_start + x.ln - 1
        ,src_start = x.src_start
        ,src_end = x.src_start + x.ln - 1
    from openjson(@json) m
    cross apply openjson(m.[value], N'$.values') v
    cross apply (
        select map = cast(m.[key] as tinyint)
            ,dst_start = cast(iif(v.[type] = 2, v.[value], json_value(v.[value], N'$[0]')) as bigint)
            ,src_start = cast(iif(v.[type] = 2, v.[value], json_value(v.[value], N'$[1]')) as bigint)
            ,ln = cast(iif(v.[type] = 2, 1, json_value(v.[value], N'$[2]')) as bigint)
    ) x
    where cast(m.[key] as tinyint) > 0
)
,location_finder as (
    select map = map
        ,mapped_start = dst_start
        ,mapped_end = dst_end
    from almanac
    where map = 0
    union all
    select map = cast(lf.map + 1 as tinyint)
        ,mapped_start = isnull(x.mapped_start, lf.mapped_start)
        ,mapped_end = isnull(x.mapped_end, lf.mapped_end)
    from location_finder lf
    outer apply (
        select mapped_start = greatest(lf.mapped_start, src_start) + (dst_start - src_start)
            ,mapped_end = least(lf.mapped_end, src_end) + (dst_start - src_start)
        from almanac
        where map = lf.map + 1
            and src_end >= lf.mapped_start
            and src_start <= lf.mapped_end
    ) x
    where lf.map < 7
)

select top 1 part2 = mapped_start 
from location_finder 
order by map desc
    ,mapped_start asc;
go
