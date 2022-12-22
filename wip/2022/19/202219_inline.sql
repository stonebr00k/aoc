drop table if exists #blueprint, #eval;

declare @ varchar(max) = '['+trim(char(10) from (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/19.tst.input', single_clob) d)) + ']';
select @ = replace(@, tr, rw) from (values
    ('Blueprint ', '['),(': Each ore robot costs ', ','),(' ore. Each clay robot costs ', ','),
    (' ore. Each obsidian robot costs ', ','),(' ore and ', ','),(' clay. Each geode robot costs ', ','),
    (' obsidian.', ']'),(char(10), ',')
) r(tr, rw);

select *, max_ore_cost = greatest(or_ore_cost, cl_ore_cost, ob_ore_cost, ge_ore_cost)
into #blueprint
from openjson(@) with (
    id tinyint '$[0]',
    or_ore_cost decimal(4,1) '$[1]',
    cl_ore_cost decimal(4,1) '$[2]',
    ob_ore_cost decimal(4,1) '$[3]',
    ob_clay_cost decimal(4,1) '$[4]',
    ge_ore_cost decimal(4,1) '$[5]',
    ge_obsidian_cost decimal(4,1) '$[6]'
);

create unique clustered index ix on #blueprint (id);

with blueprint_evaluator as (
    select id = id
        ,mins = cast(24 as smallint)
        ,orebots = cast(1 as tinyint), clybots = cast(0 as tinyint), obsbots = cast(0 as tinyint), geobots = cast(0 as tinyint)
        ,ore = cast(0 as smallint), clay = cast(0 as smallint), obsidian = cast(0 as smallint), geode = cast(0 as smallint)
        ,is_orebots_maxed = cast(0 as bit)
        ,is_clybots_maxed = cast(0 as bit)
        ,is_obsbots_maxed = cast(0 as bit)
        ,maxgeode = cast(0 as smallint)
    from #blueprint
    union all
    select id = e.id
        ,mins = p.mins
        ,orebots = p.orebots, clybots = p.clybots, obsbots = p.obsbots, geobots = p.geobots
        ,ore = p.ore, clay = p.clay, obsidian = p.obsidian, geode = p.geode
        ,is_orebots_maxed = is_orebots_maxed | cast(iif(p.orebots = max_ore_cost, 1, 0) as bit)
        ,is_clybots_maxed = is_clybots_maxed | cast(iif(p.clybots = ob_clay_cost, 1, 0) as bit)
        ,is_obsbots_maxed = is_obsbots_maxed | cast(iif(p.obsbots = ge_obsidian_cost, 1, 0) as bit)
        ,maxgeode = max(p.geode) over(partition by e.id)
    from blueprint_evaluator e
    join #blueprint bp on e.id = bp.id
    cross apply (
        select bot = [value]
            ,mins = cast(e.mins - x.mins as smallint)
            ,orebots = e.orebots + cast(iif([value] = 1, 1, 0) as tinyint)
            ,clybots = e.clybots + cast(iif([value] = 2, 1, 0) as tinyint)
            ,obsbots = e.obsbots + cast(iif([value] = 3, 1, 0) as tinyint)
            ,geobots = e.geobots + cast(iif([value] = 4, 1, 0) as tinyint)
            ,ore = cast(e.ore + (x.mins * e.orebots) - choose([value], or_ore_cost, cl_ore_cost, ob_ore_cost, ge_ore_cost) as smallint)
            ,clay = cast(e.clay + (x.mins * e.clybots) - choose([value], 0, 0, ob_clay_cost, 0) as smallint)
            ,obsidian = cast(e.obsidian + (x.mins * e.obsbots) - choose([value], 0, 0, 0, ge_obsidian_cost) as smallint)
            ,geode = cast(e.geode + (x.mins * e.geobots) as smallint)
        from generate_series(1, 4)
        cross apply (values(
            greatest(0, choose([value],
                ceiling((or_ore_cost - e.ore) / nullif(e.orebots, 0)),
                ceiling((cl_ore_cost - e.ore) / nullif(e.orebots, 0)),
                greatest(
                    isnull(ceiling((ob_ore_cost - e.ore) / nullif(e.orebots, 0)), 99),
                    isnull(ceiling((ob_clay_cost - e.clay) / nullif(e.clybots, 0)), 99)
                ),
                greatest(
                    isnull(ceiling((ge_ore_cost - e.ore) / nullif(e.orebots, 0)), 99),
                    isnull(ceiling((ge_obsidian_cost - e.obsidian) / nullif(e.obsbots, 0)), 99)
                )
            )) + 1)
        ) x(mins)
        where x.mins <= e.mins
            and choose([value], is_orebots_maxed, is_clybots_maxed, is_obsbots_maxed, cast(0 as bit)) = cast(0 as bit)
    ) p
    where e.mins >= 0
        and p.geode + p.geobots * p.mins + ((p.mins - 1) * p.mins / 2) > e.maxgeode
)
,quality_levels as (
    select id, max_geodes = max(geode), quality_level = id * max(geode), cnt = count(*)
    from blueprint_evaluator
    where mins = 0
    group by id
)

select part1 = sum(quality_level)
from quality_levels;
