declare @input nvarchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2021/12.input', single_clob) d);
declare @json nvarchar(max) = N'["' + replace(trim(nchar(10) from @input), nchar(10), N'","') + N'"]';
declare @connections table (
    a varchar(5),
    b varchar(5),
    primary key (a, b)
);

insert into @connections(a, b)
    select a = substring(i.[value], 1, charindex('-', i.[value]) - 1)
        ,b = substring(i.[value], charindex('-', i.[value]) + 1, len(i.[value]))
    from openjson(@json) i;

with path_finder as (
    select cave_a = cast(null as varchar(5))
        ,cave_b = cast('start' as varchar(5))
        ,[path] = cast('start' as varchar(max))
        ,is_any_cave_visited_twice = cast(0 as bit)
    union all
    select cave_a = x.cave_a
        ,cave_b = x.cave_b
        ,[path] = cast(pf.[path] + N'/' + x.cave_b as varchar(max))
        ,is_any_cave_visited_twice = isnull(nullif(pf.is_any_cave_visited_twice, 0), ~x.is_big & cast(charindex('/' + x.cave_b, pf.[path]) as bit))
    from path_finder pf
    join @connections c
        on pf.cave_b in (c.a, c.b)
    cross apply (
        select cave_a = iif(c.a = pf.cave_b, c.a, c.b)
            ,cave_b = iif(c.a = pf.cave_b, c.b, c.a)
            ,is_big = cast(iif(iif(a = pf.cave_b, c.b, c.a) = upper(iif(a = pf.cave_b, c.b, c.a)) collate Latin1_General_CS_AI, 1, 0) as bit)
            ,is_visited = cast(charindex('/' + iif(a = pf.cave_b, c.b, c.a), pf.[path]) as bit)
    ) x
    where pf.cave_b != 'end'
        and x.cave_b != 'start'
        and x.is_big | ~x.is_visited | ~pf.is_any_cave_visited_twice = 1
)

select part_1 = count(nullif(is_any_cave_visited_twice, 1))
    ,part_2 = count(*)
from path_finder
where cave_b = 'end';
