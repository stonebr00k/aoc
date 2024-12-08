/*  aoc 2024-09 (https://adventofcode.com/2024/day/9)  */
declare @input varchar(max) = replace((select bulkcolumn from openrowset(bulk 'c:/repo/stonebr00k/aoc/input/2024/09t', single_clob)_), nchar(13), '');

with disk_map as (
    select id = row_number() over(order by [value]) - 1
        ,file_size = cast(substring(@input, [value], 1) as tinyint)
        ,free_space = cast(substring(@input, [value]+1, 1) as tinyint)
        ,total_file_size = sum(cast(substring(@input, [value], 1) as tinyint)) over(order by (select null))
    from generate_series(1, cast(len(@input) as int), 2)
)
,blocks as (
    select i = row_number() over(order by id, i.[value])
        ,ix = row_number() over(partition by iif(i.[value] <= file_size, 1, 0) order by id * iif(i.[value] <= file_size, -1, 1), i.[value]*iif(i.[value] <= file_size, -1, 1))
        ,[block] = iif(i.[value] <= file_size, id, null)
        ,total_file_size
    from disk_map dm
    cross apply generate_series(cast(1 as tinyint), file_size + free_space) i
)

select part_1 = sum((b1.i-1) * isnull(b1.[block], b2.[block]))
from blocks b1
left join blocks b2
    on b1.ix = b2.ix
    and b1.[block] is null
where b1.i <= b1.total_file_size 
