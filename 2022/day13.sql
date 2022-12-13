/*  AoC 2022-13 (https://adventofcode.com/2022/day/13)  */
create or alter function comparable_string (@array nvarchar(max))
returns table
as return (
    with parser as (
        select lvl = sum(iif(chr = N'[', 1, iif(chr = N']', -1, 0))) over(order by [value])
            ,chr
        from generate_series(1, cast(len(@array) as int)) s
        cross apply (values(substring(replace(@array, '10', 'A'), s.[value], 1))) x(chr)
    )

    select [value] = isnull(string_agg(iif(chr = ',', char(33 + lvl), iif(chr in ('[',']'), '', chr)), ''), '')
    from parser
    where chr not in ('[',']')
);
go

declare @ varchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/13.input', single_clob) d);
declare @i1 varchar(max) = '[[' + replace(replace(trim(char(10) from @), char(10) + char(10), '],['), char(10), ',') + ']]';
declare @i2 varchar(max) = '[' + replace(replace(trim(char(10) from @), char(10) + char(10), ','), char(10), ',') + ',[[2]],[[6]]]';

select part1 = sum(i.[key] + 1)
from openjson(@i1) i
cross apply comparable_string(json_query(i.[value], '$[0]')) l
cross apply comparable_string(json_query(i.[value], '$[1]')) r
where l.[value] <= r.[value];

select part2 = exp(sum(log(i)))
from (
    select i = row_number() over(order by a.[value]), i.[value]
    from openjson(@i2) i
    cross apply comparable_string([value]) a
) x
where [value] in ('[[2]]','[[6]]');
