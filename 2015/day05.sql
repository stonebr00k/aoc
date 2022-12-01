declare @input varchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2015/05.input', single_clob) d);
set @input = replace(replace(trim(char(10) from @input), replicate(char(13) + char(10), 2), char(16)), char(13) + char(10), char(17));

select part1 = sum(cast(t11 & t12 & t13 as int))
    ,part2 = sum(cast(t21 & t22 as int))
from string_split(@input, char(10)) l
cross apply (
    select t11 = cast(iif(sum(iif(chr1 in ('a', 'e', 'i', 'o', 'u'), 1, 0)) >= 3, 1, 0) as bit)
        ,t12 = cast(max(iif(chr1 = chr2, 1, 0)) as bit)
        ,t13 = ~cast(max(iif(chr1 + chr2 in ('ab', 'cd', 'pq', 'xy'), 1, 0)) as bit)
        ,t21 = cast(sum(iif(len(st) - len(replace(st, chr1 + chr2, '')) >= 4, 1, 0)) as bit)
        ,t22 = cast(sum(iif(chr1 = chr3, 1, 0)) as bit)
    from generate_series(1, cast(len(l.[value]) as int)) s
    cross apply (
        select st = l.[value]
            ,chr1 = substring(l.[value], s.[value], 1)
            ,chr2 = nullif(substring(l.[value], s.[value] + 1, 1), '')
            ,chr3 = nullif(substring(l.[value], s.[value] + 2, 1), '')
    ) _
) x
go
