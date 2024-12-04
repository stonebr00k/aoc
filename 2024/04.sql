/*  AoC 2024-04 (https://adventofcode.com/2024/day/4)  */
declare @input varchar(max) = replace((select BulkColumn from openrowset(bulk 'C:/repo/stonebr00k/aoc/input/2024/04', single_clob)_), nchar(13), '');

with the_matrix as (
    select [row] = r.ordinal
        ,col = c.[value]
        ,chr = substring(r.[value], c.[value], 1)
        ,ci = cast(translate(substring(r.[value], c.[value], 1), 'XMAS', '1248') as tinyint)
    from string_split(@input, nchar(10), 1) r
    cross apply generate_series(1, cast(len(r.[value]) as int)) c
)

select part_1 = (
        select sum(len(line) * 2 - len(replace(line, 'XMAS', '---')) - len(replace(line, 'SAMX', '---')))
        from (
            select line = string_agg(m.chr, '') within group(order by choose(dir.id, m.col, m.[row], m.col, m.[row]))
            from the_matrix m
            cross join (values(1),(2),(3),(4)) dir(id)
            group by dir.id, choose(dir.id, m.[row], m.col, m.col - m.[row], m.col + m.[row])
        ) _
    )
    ,part_2 = (
        select sum(is_x_mas)
        from (
            select is_x_mas = iif(ci = 4 and lead(ci) over a + lag(ci) over a = 10 and lead(ci) over b + lag(ci) over b = 10, 1, 0)
            from the_matrix
            window a as (partition by [row] - col order by [row])
                ,b as (partition by [row] + col order by [row])
        ) _
    );
go
