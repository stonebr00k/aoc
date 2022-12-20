/*  AoC 2022-18 (https://adventofcode.com/2022/day/18)  */
drop table if exists air, connected_to, #box, #outside_air;
create table air (x int not null, y int not null, z int not null, primary key (x, y, z)) as node;
create table connected_to as edge;

declare @ varchar(max) = trim(char(10) from (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/18.input', single_clob) d));
set @ = '[[' + replace(@, char(10), '],[') + ']]';

select x = x.[value], y = y.[value], z = z.[value]
into #box
from (
    select mn = cast(min(i)-1 as smallint), mx = cast(max(i) as smallint)
    from openjson(@) cross apply openjson([value]) with(i smallint '$')
) minmax(mn,mx)
cross apply generate_series(mn, mx) x
cross apply generate_series(mn, mx) y
cross apply generate_series(mn, mx) z;

insert into air (x, y, z)
    select x, y, z from #box except
    select x, y, z from openjson(@) with (x int '$[0]', y int '$[1]', z int '$[2]');

insert into connected_to
    select a1.$node_id, a2.$node_id
    from air a1
    cross join (values(-1,0,0),(1,0,0),(0,-1,0),(0,1,0),(0,0,-1),(0,0,1)) d(x, y, z)
    join air a2  on a1.x+d.x = a2.x and a1.y+d.y = a2.y and a1.z+d.z = a2.z;

select x = last_value(air2.x) within group (graph path)
    ,y = last_value(air2.y) within group (graph path)
    ,z = last_value(air2.z) within group (graph path)
into #outside_air
from air air1, connected_to for path, air for path air2
where match(shortest_path(air1(-(connected_to)->air2)+))
    and air1.x = -1 and air1.y = -1 and air1.z = -1;

select part1 = (
        select sum(exposed_sides)
        from (
            select exposed_sides = 6 - (
                iif(lag (x) over(partition by y, z order by x) = x-1, 1, 0) +
                iif(lead(x) over(partition by y, z order by x) = x+1, 1, 0) +
                iif(lag (y) over(partition by x, z order by y) = y-1, 1, 0) +
                iif(lead(y) over(partition by x, z order by y) = y+1, 1, 0) +
                iif(lag (z) over(partition by x, y order by z) = z-1, 1, 0) +
                iif(lead(z) over(partition by x, y order by z) = z+1, 1, 0)
            ) from openjson(@) with (x int '$[0]', y int '$[1]', z int '$[2]')
        ) _
    )
    ,part2 = (
        select sum(exposed_sides)
        from (
            select exposed_sides = 6 - (
                iif(lag (x) over(partition by y, z order by x) = x-1, 1, 0) +
                iif(lead(x) over(partition by y, z order by x) = x+1, 1, 0) +
                iif(lag (y) over(partition by x, z order by y) = y-1, 1, 0) +
                iif(lead(y) over(partition by x, z order by y) = y+1, 1, 0) +
                iif(lag (z) over(partition by x, y order by z) = z-1, 1, 0) +
                iif(lead(z) over(partition by x, y order by z) = z+1, 1, 0)
            ) from (
                select x, y, z from #box except
                select x, y, z from #outside_air
            ) solid_lava_droplet
        ) _
    );
