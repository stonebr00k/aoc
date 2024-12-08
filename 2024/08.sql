/*  aoc 2024-08 (https://adventofcode.com/2024/day/8)  */
declare @input varchar(max) = replace((select bulkcolumn from openrowset(bulk 'c:/repo/stonebr00k/aoc/input/2024/08', single_clob)_), nchar(13), '');

with antenna as (
    select id = row_number() over(order by c.[value], r.ordinal) 
        ,x = cast(c.[value] as smallint)
        ,y = cast(r.ordinal as smallint)
        ,frequency = cast(ascii(substring(r.[value], c.[value], 1)) as tinyint)
        ,boundary = cast(len(r.[value]) as int)
    from string_split(@input, char(10), 1) r
    cross apply generate_series(1, cast(len(r.[value]) as int)) c
    where cast(ascii(substring(r.[value], c.[value], 1)) as tinyint) != 46
)

select part_1 = count(distinct p1.antinode)
    ,part_2 = count(distinct p2.antinode)
from antenna a1
join antenna a2 
    on a1.frequency = a2.frequency
    and a1.id < a2.id
outer apply (
    select antinode = concat(x, ',', y)
    from (values (a1.x+(a1.x-a2.x), a1.y+(a1.y-a2.y)), (a2.x-(a1.x-a2.x), a2.y-(a1.y-a2.y))) _(x, y)
    where x between 1 and a1.boundary and y between 1 and a1.boundary
) p1
outer apply (
    select antinode = concat(x.[value], ',', y.[value])
    from (values((1.0 * a2.y - a1.y) / (a2.x - a1.x))) m(val)
    cross apply (values(cast(a1.y - m.val*a1.x as decimal(10,2)))) b(val)
    cross apply generate_series(1, a1.boundary) x
    cross apply generate_series(1, a1.boundary) y
    where b.[val] = cast(y.[value] - m.val*x.[value] as decimal(10, 2))
) p2
go
