create or alter function dbo.find_neighbours (
    @map nvarchar(max),
    @check nvarchar(max),
    @visited nvarchar(max)
)
returns table
as return (
    with coordinates as (
        select x = json_value([value], N'$[0]')
            ,y = json_value([value], N'$[1]')
        from openjson(@check)
    )
    ,neighbours as (
        select distinct p.[val]
            ,x = iif(p.dir in ('e','w'), x, x + iif(p.dir = 's', 1, -1))
            ,y = iif(p.dir in ('n','s'), y, y + iif(p.dir = 'e', 1, -1)) 
        from coordinates c
        cross apply (values
            ('n', nullif(json_value(@map, N'$' + quotename(isnull(nullif(x - 1, -1), 1000)) + quotename(y)), 9)),
            ('e', nullif(json_value(@map, N'$' + quotename(x) + quotename(y + 1)), 9)),
            ('s', nullif(json_value(@map, N'$' + quotename(x + 1) + quotename(y)), 9)),
            ('w', nullif(json_value(@map, N'$' + quotename(x) + quotename(isnull(nullif(y - 1, -1), 1000))), 9))
        ) p(dir, val)
        where p.val is not null
    )
    ,found as (
        select array = N'[[' + string_agg(cast(x as nvarchar(2)) + N',' + cast(y as nvarchar(2)),N'],[') + N']]'
            ,found = count(*)
        from neighbours n
        where not exists (
            select 1 
            from openjson(@visited) with (x tinyint N'$[0]', y tinyint N'$[1]')
            where x = n.x 
                and y = n.y
        )
    )

    select found = cast(array as nvarchar(max))
        ,visited = cast(replace(replace(json_modify(@visited, N'append $', json_query(array)), N',[[', N',['), N']]]', N']]') as nvarchar(max))
        ,no_found = cast(found as int)
    from found
);
go

declare @input nvarchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2021/09.input', single_clob) d);
declare @json nvarchar(max) = N'["' + replace(trim(nchar(10) from @input), nchar(10), N'","') + N'"]';
declare @json_map nvarchar(max);

with row_json_array as (
    select rid = cast([key] as tinyint)
        ,arr = N'[' + string_agg(right(left([value], i), 1), N',') within group(order by i) + N']'
    from openjson(@json) r
    cross join (
        select top (len(json_value(@json, N'$[0]'))) i = row_number() over(order by (select null))
        from (values(1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) a(i)
        cross join (values(1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) b(i)
    ) i
    group by [key]
)

select @json_map = N'[' + string_agg(arr,N',') within group(order by rid) + N']'
from row_json_array;

with heightmap as (
    select r = x.r
        ,c = x.c
        ,val = x.val
        ,nnv = isnull(lag (x.val) over(partition by x.c order by x.r), 10)
        ,env = isnull(lead(x.val) over(partition by x.r order by x.c), 10)
        ,snv = isnull(lead(x.val) over(partition by x.c order by x.r), 10)
        ,wnv = isnull(lag (x.val) over(partition by x.r order by x.c), 10)
    from openjson(@json_map) r
    cross apply openjson(r.[value]) c
    cross apply (
        select r = cast(r.[key] as tinyint)
            ,c = cast(c.[key] as tinyint)
            ,val = cast(c.[value] as tinyint)
    ) x
)
,low_point as (
    select id = row_number() over(order by r, c)
        ,r
        ,c
        ,risk_level = val + 1
    from heightmap
    where iif(val < wnv, 1, 0) & iif(val < env, 1, 0) & iif(val < nnv, 1, 0) & iif(val < snv, 1, 0) = 1
)
,basin_mapper as (
    select i = 1 
        ,basin = id 
        ,[check] = x.array
        ,visited = x.array
        ,found = cast(1 as int)
    from low_point 
    cross apply (values(cast(N'[[' + cast(r as nvarchar(2)) + N',' + cast(c as nvarchar(2)) + N']]' as nvarchar(max)))) x(array)
    union all
    select i = bm.i + 1
        ,basin = bm.basin
        ,[check] = n.found
        ,visited = n.visited
        ,found = bm.found + n.no_found
    from basin_mapper bm
    cross apply dbo.find_neighbours(@json_map, bm.[check], bm.visited) n
    where n.found is not null
)
,big_basins as (
    select top 3 is_last = ~cast(row_number() over(partition by basin order by i desc) - 1 as bit)
        ,found
    from basin_mapper bm
    order by 1 desc, 2 desc
)

select part_1 = (select sum(risk_level) from low_point)
    ,part_2 = (select exp(sum(log(found))) from big_basins);
