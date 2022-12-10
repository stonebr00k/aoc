/*  AoC 2022-10 (https://adventofcode.com/2022/day/10)  */
declare @ varchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/10.input', single_clob) d);
set @ = '[["' + replace(replace(replace(trim(char(10) from @), 'p', 'p 0'), ' ', '",'), char(10), '],["') + ']]';

with execution as (
    select c = row_number() over(order by ni, cm)
        ,pp = isnull(nullif(row_number() over(order by ni, cm) % 40, 0), 40) - 1
        ,sp = 1 + isnull(sum(cm*v) over(order by ni, cm rows between unbounded preceding and 1 preceding), 0)
    from openjson(@) j
    cross apply (values(
        cast(j.[key] as int),
        json_value(j.[value], '$[0]'),
        json_value(j.[value], '$[1]')
    )) p(ni, i, v)
    join (values('noop', 0),('addx', 0),('addx', 1)) c(i, cm)
        on p.i = c.i
)

select part1 = sum(iif(c in (20,60,100,140,180,220), c*sp, 0))
    ,part2 = string_agg(iif(pp between sp-1 and sp+1, '#', '.') + iif(pp = 39, char(10), ''), '') within group(order by c)
from execution;

/* Visualisation of part 2 - Run in SSMS and go to "Spatial results" tab.
    select geometry::Point(pp, -sum(iif(pp = 0, 1, 0)) over(order by c), 0).STBuffer(0.5)
    from execution
    where pp between sp-1 and sp+1;
*/
