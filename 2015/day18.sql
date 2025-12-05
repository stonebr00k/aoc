/*  AoC 2015-18 (https://adventofcode.com/2015/day/18)  */
declare @input nvarchar(max); exec aoc.[get] N'input', 2015, 18, @input out, 0;
declare @iterations tinyint = 0;

drop table if exists #light_grid;
create table #light_grid (
    [row] smallint not null,
    col smallint not null,
    state1 bit not null,
    state2 bit not null,
    primary key ([row], col)
);

insert into #light_grid ([row], col, state1, state2)
    select r.ordinal
        ,c.[value]
        ,iif(substring(r.[value], c.[value], 1) = N'#', 1, 0)
        ,iif(substring(r.[value], c.[value], 1) = N'#' or x.is_corner = 1, 1, 0)
    from string_split(trim(nchar(10) from @input), nchar(10), 1) r
    cross apply generate_series(1, cast(len(r.[value]) as int)) c
    cross apply (values(iif(r.[ordinal] in (1, 100) and c.[value] in (1, 100), 1, 0))) x(is_corner);

while @iterations < 100 begin;
    update r set state1 = iif([change].state1 = 1, ~r.state1, r.state1)
        ,state2 = iif([change].state2 = 1, ~r.state2, r.state2)
    from #light_grid r
    cross apply (
        select c1 = sum(cast(state1 as smallint))
            ,c2 = sum(cast(state2 as smallint))
        from #light_grid
        cross join (values(-1, 0),(-1, 1),(0, 1),(1, 1),(1, 0),(1, -1),(0, -1),(-1, -1)) [mod](r, c)
        where [row] = r.[row] + [mod].r
            and col = r.col + [mod].c
    ) n
    cross apply (
        select state1 = cast(iif((r.state1 = 1 and n.c1 not in (2, 3)) or (r.state1 = 0 and n.c1 = 3), 1, 0) as bit)
            ,state2 = cast(iif(((r.state2 = 1 and n.c2 not in (2, 3)) or (r.state2 = 0 and n.c2 = 3)) and not (r.[row] in (1, 100) and r.col in (1, 100)), 1, 0) as bit)
    ) [change]
    where [change].state1 | [change].state2 = 1;

    set @iterations += 1;
end;

select part_1 = sum(cast(state1 as tinyint))
    ,part_2 = sum(cast(state2 as tinyint))
from #light_grid;
