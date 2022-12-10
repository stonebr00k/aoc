/*  AoC 2022-03 (https://adventofcode.com/2022/day/3)  */
declare @input varchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/03.input', single_clob) d);
set @input = replace(replace(trim(char(10) from @input), replicate(char(13) + char(10), 2), char(16)), char(13) + char(10), char(17));

with rucksack as (
    select id, rid, s, ln, gid = sum(iif(rid = 1, 1, 0)) over(order by id)
    from openjson(N'["' + replace(@input, char(10), '","') + '"]')
    cross apply(values(cast([key] as int), cast([key] as int) % 3 + 1, [value], cast(len([value]) as int))) x(id, rid, s, ln)
)
,p1 as (
    select id, c = ascii(substring(s, [value], 1)) from rucksack cross apply generate_series(1, ln / 2) intersect
    select id, c = ascii(substring(s, [value], 1)) from rucksack cross apply generate_series(ln / 2 + 1, ln)
)
,p2 as (
    select gid, c = ascii(substring(s, [value], 1)) from rucksack cross apply generate_series(1, ln) where rid = 1 intersect
    select gid, c = ascii(substring(s, [value], 1)) from rucksack cross apply generate_series(1, ln) where rid = 2 intersect
    select gid, c = ascii(substring(s, [value], 1)) from rucksack cross apply generate_series(1, ln) where rid = 3
)

select part1 = (select sum(c - iif(c > 90, 96, 38)) from p1)
    ,part2 = (select sum(c - iif(c > 90, 96, 38)) from p2)
