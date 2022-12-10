/*  AoC 2022-06 (https://adventofcode.com/2022/day/6)  */
declare @ varchar(max) = trim(nchar(10) from (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/06.input', single_clob) d));

select part = p.n
    ,answer = x.answer
from (values(1, 3),(2, 13)) p(n, c)
cross apply (
    select top 1 answer = a.[value] + p.c
    from generate_series(1, cast(len(@) as int)) a
    cross join generate_series(0, p.c) b
    order by dense_rank() over(partition by a.[value] order by substring(@, a.[value] + b.[value], 1)) desc
        ,a.[value]
) x;
