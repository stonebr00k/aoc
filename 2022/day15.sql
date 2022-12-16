/*  AoC 2022-15 (https://adventofcode.com/2022/day/15)  */
declare @ varchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/15.input', single_clob) d);
set @ = '[[' + replace(replace(replace(replace(@, 'Sensor at x=', ''), ': closest beacon is at x=', ','), ', y=', ','), char(10), '],[') + ']]'
declare @row int = 2000000, @max int = 4000000;

-- Part 1
select part1 = count(distinct x.[value])
from openjson(@) with (xs int '$[0]', ys int '$[1]', xb int '$[2]', yb int '$[3]')
cross apply (values(abs(xs-xb) + abs(ys-yb))) d(r)
cross apply generate_series(xs-r, xs+r) x
where abs(xs-x.[value]) + abs(ys-@row) <= r
    and iif(xb = x.[value] and yb = @row, 0, 1) = 1;

-- Part 2
with snb as (
    select xs, ys, r = r+1
    from openjson(@) with (xs int '$[0]', ys int '$[1]', xb int '$[2]', yb int '$[3]')
    cross apply (values(abs(xs-xb) + abs(ys-yb))) d(r)
)
select top 1 part2 = cast(c.x as bigint) * 4000000 + c.y
from snb
cross apply generate_series(0, r) s
cross apply (values(1),(2),(3),(4)) z(m)
cross apply (values(
    choose(z.[value], xs + s.[value] - r, xs + s.[value], xs + s.[value] - r, xs + s.[value]),
    choose(z.[value], ys - s.[value], ys + s.[value] - r, ys + s.[value], ys - s.[value] + r)
)) c(x, y)
where c.x between 0 and @max 
    and c.y between 0 and @max
    and not exists (select * from snb where abs(xs-c.x) + abs(ys-c.y) <= r-1);

/* Part 2  - faster but not inline:
    declare @ varchar(max) = '[[' + trim(char(10) from (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/15.input', single_clob) d)) + ']]';
    select @ = replace(trim(char(10) from @), tr, rw) from (values
        ('Sensor at x=', ''),(': closest beacon is at x=', ','),(', y=', ','),(char(10), '],[')
    ) r(tr, rw);

    drop table if exists #snb;
    create table #snb (xs int not null, ys int not null, r int not null, primary key (xs, ys));

    insert into #snb
        select xs, ys, r = r+1
        from openjson(@) with (xs int '$[0]', ys int '$[1]', xb int '$[2]', yb int '$[3]')
        cross apply (values(abs(xs-xb) + abs(ys-yb))) d(r);
        
    declare @max int = 4000000;

    select top 1 part2 = cast(c.x as bigint) * 4000000 + c.y
    from #snb
    cross apply generate_series(0, r) s
    cross apply (values(1),(2),(3),(4)) z(m)
    cross apply (values(
        choose(z.m, xs + s.[value] - r, xs + s.[value], xs + s.[value] - r, xs + s.[value]),
        choose(z.m, ys - s.[value], ys + s.[value] - r, ys + s.[value], ys + s.[value] - r)
    )) c(x, y)
    where c.x between 0 and @max 
        and c.y between 0 and @max
        and not exists (select * from #snb where abs(xs-c.x) + abs(ys-c.y) <= r-1);
*/
