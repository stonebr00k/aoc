declare @input varchar(max) = trim(char(10) from (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2015/08.input', single_clob) d));

select part1 = sum(len([value])) - (sum(len([value]) - (isnull(x.c, 0) + 2)))
    ,part2 = sum(len(string_escape([value], 'json')) + 2) - sum(len([value]))
from string_split(@input, char(10)) s
outer apply (
    select c = sum(e.v)
    from generate_series(1, cast(len(s.[value]) as int), 1) c
    left join (values('¨~', 1),('\"', 1),('\x', 3)) e(seq, v)
        on substring(replace(s.[value], '\\', '¨~'), c.[value], 2) = e.seq
) x;
