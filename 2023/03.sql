/*  AoC 2023-03 (https://adventofcode.com/2023/day/3)  */
declare @ varchar(max) = replace((select BulkColumn from openrowset(bulk 'C:/repo/stonebr00k/aoc/input/2023/03', single_clob)_), char(13), '');

with a as (
    select line = l.ordinal
        ,idx = s.[value]
        ,d = s.[value] - lag(s.[value], 1, 0) over(partition by l.ordinal order by s.[value]) - 1
        ,c.chr
    from string_split(@, char(10), 1) l
    cross apply generate_series(cast(1 as int), cast(len(l.[value]) as int)) s
    cross apply (values(substring(l.[value], s.[value], 1))) c(chr)
)
, b as (
    select line, idx, chr, d = idx - lag(idx, 1, 0) over(partition by line order by idx) - 1
    from a
    where chr like '[0-9]'
)
, c as (
    select line, idx, chr, grp_id = sum(d) over(partition by line order by idx)
    from b
)
, d as (
    select line
        ,grp_id = row_number() over(order by line, grp_id)
        ,idx_start = min(idx)
        ,idx_end = max(idx)
        ,part_no = cast(string_agg(chr, '') within group (order by idx) as int)
    from c
    group by line, grp_id
)
, e as (
    select distinct d.line, d.grp_id, d.part_no
    from d 
    cross apply generate_series(d.line - 1, d.line + 1) y
    cross apply generate_series(d.idx_start - 1, d.idx_end + 1) x
    join a on y.[value] = a.line and x.[value] = a.idx
    where a.chr like '[^0-9.]'
)
, f as (
    select distinct a.line, a.idx, d.grp_id, d.part_no
    from a
    cross apply generate_series(line - 1, line + 1) x
    cross apply generate_series(idx - 1, idx + 1) y
    join d on x.[value] = d.line and y.[value] between d.idx_start and d.idx_end
    where a.chr = '*'
)
, g as (
    select line, idx, gear_ratio = min(part_no) * max(part_no)
    from f
    group by line, idx
    having count(grp_id) = 2
)

select part1 = sum(part_no) from e union all
select part2 = sum(gear_ratio) from g;
go
