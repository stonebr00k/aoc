/*  AoC 2025-05 (https://adventofcode.com/2015/day/17)  */
declare @input nvarchar(max); exec aoc.[get] N'input', 2015, 17, @input out, 0;

drop table if exists #container;
create table #container (id tinyint not null primary key, volume tinyint not null);

insert into #container (id, volume)
    select id = row_number() over(order by cast([value] as tinyint) desc)
        ,volume = cast([value] as tinyint)
    from string_split(trim(nchar(10) from replace(@input, nchar(13), N'')), nchar(10));

with container_filler as (
    select id, volume, containers = 1
    from #container
    union all
    select c.id, f.volume + c.volume, f.containers + 1
    from container_filler f
    join #container c on f.id < c.id
    where f.volume < 150
)
,filled_containers as (
    select containers
        ,min_containers = min(containers) over(order by (select null))
    from container_filler
    where volume = 150
)

select part_1 = count(*)
    ,part_2 = sum(iif(containers = min_containers, 1, 0))
from filled_containers;
