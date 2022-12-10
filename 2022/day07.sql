/*  AoC 2022-07 (https://adventofcode.com/2022/day/7)  */
declare @ varchar(max) = trim(nchar(10) from (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/07.input', single_clob) d));
set @ = '[["' + replace(replace(@, ' ', '","'), char(10), '"],["') + N'"]]';

declare @fs_json nvarchar(max); 
declare @space_needed bigint;

select @fs_json = string_agg(s + cma + cls,'') within group (order by i)
    ,@space_needed = sum(try_cast(s as int))
from (
    select i
        ,s = isnull(cast(j.s as varchar(9)), l.a)
        ,cma = iif(j.c = 1 or lead(j.c) over(order by i) = 2 , '', iif(row_number() over(order by i desc) = 1, '', ','))
        ,cls = iif(row_number() over(order by i desc) = 1, replicate(']', sum(iif(j.c = 1, 1, iif(j.c = 2, -1, 0))) over(order by i)), '')
    from (
        select i, a, b, c, l = cast(iif(row_number() over(order by cast([key] as smallint) desc) = 1, 1, 0) as bit)
        from openjson(@)
        cross apply(values(cast([key] as smallint), json_value([value], '$[0]'), json_value([value], '$[1]'), json_value([value], '$[2]'))) x(i, a, b, c)
    ) l
    left join (values('$cd', 1, '['),('$cd',2,']')) j(ab, c, s)
        on l.a + l.b = j.ab 
        and iif(l.c = '..', 2, 1) = j.c
    where a != 'dir' and a+b != '$ls'
) x;

with tree as (
    select [value] = cast(@fs_json as nvarchar(max))
        ,[type] = cast(4 as tinyint)
    union all
    select [value] = j.[value]
        ,[type] = j.[type]
    from tree t cross apply openjson(t.[value]) j
    where t.[type] = 4
)
,dirs as (
    select size = sum(cast(j.[value] as int))
    from tree t
    cross apply openjson('[' + translate(t.[value], '][','  ') + ']') j
    where t.[type] = 4
    group by t.[value]
)

select part1 = sum(iif(size <= 100000, size, 0))
    ,part2 = min(iif(size >= @space_needed, size, 70000000))
from dirs;
