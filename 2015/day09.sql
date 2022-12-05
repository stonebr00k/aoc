declare @input varchar(max) = trim(nchar(10) from (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2015/09.input', single_clob) d));
set @input = '[["' + replace(replace(replace(@input, nchar(10), '],["'), ' = ', '",'), N' to ', '","') + ']]';

with dist as (
    select f = iif(i = 1, f, t), t = iif(i = 1, t, f), d
    from openjson(@input) with (f varchar(32) '$[0]', t varchar(32) '$[1]', d int '$[2]')
    cross join (values(1),(2)) x(i)
)
,calc as (
    select l = 1, p = cast(f + '->' + t as nvarchar(max)), t, d
    from dist
    union all
    select l = c.l + 1, p = p + '->' + d.t, d.t, d = c.d + d.d
    from calc c
    join dist d on (c.t = d.f and c.p not like '%' + d.t + '%')
)

select part1 = (select top 1 d from calc where l = 7 order by d)
    ,part2 = (select top 1 d from calc where l = 7 order by d desc);
