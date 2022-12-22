drop procedure if exists blueprint_evaluator;
drop type if exists blueprint;
drop type if exists evaluating;

create type blueprint as table (
    id tinyint not null,
    or_ore_cost decimal(4,1) not null,
    cl_ore_cost decimal(4,1) not null,
    ob_ore_cost decimal(4,1) not null,
    ob_clay_cost decimal(4,1) not null,
    ge_ore_cost decimal(4,1) not null,
    ge_obsidian_cost decimal(4,1) not null,
    max_ore_cost decimal(4,1) not null,
    max_geode smallint not null,
    index ix unique nonclustered (id)
) with(memory_optimized = on);

create type evaluating as table (
    iteration tinyint not null,
    blueprint tinyint not null,
    mins smallint not null,
    orebots tinyint not null,
    clybots tinyint not null,
    obsbots tinyint not null,
    geobots tinyint not null,
    ore smallint not null,
    clay smallint not null,
    obsidian smallint not null,
    geode smallint not null,
    is_orebots_maxed bit not null,
    is_clybots_maxed bit not null,
    is_obsbots_maxed bit not null,
    index ix nonclustered (iteration, blueprint)
) with(memory_optimized = on);
go

create or alter procedure blueprint_evaluator (@bluprints nvarchar(max), @part tinyint)
with native_compilation, schemabinding
as begin atomic with (transaction isolation level = snapshot, language = N'us_english');
    declare @blueprint dbo.blueprint;
    declare @eval dbo.evaluating;
    declare @minutes tinyint = iif(@part = 1, 24, 32);

    insert into @blueprint (id, or_ore_cost, cl_ore_cost, ob_ore_cost, ob_clay_cost, ge_ore_cost, ge_obsidian_cost,max_ore_cost,max_geode)
        select id, or_ore_cost, cl_ore_cost, ob_ore_cost, ob_clay_cost, ge_ore_cost, ge_obsidian_cost
            ,max_ore_cost = max(x.oc)
            ,max_geode = 0
        from openjson(@bluprints) with (
            id tinyint '$[0]',
            or_ore_cost decimal(4,1) '$[1]',
            cl_ore_cost decimal(4,1) '$[2]',
            ob_ore_cost decimal(4,1) '$[3]',
            ob_clay_cost decimal(4,1) '$[4]',
            ge_ore_cost decimal(4,1) '$[5]',
            ge_obsidian_cost decimal(4,1) '$[6]'
        ) 
        cross apply (
            select or_ore_cost union all
            select cl_ore_cost union all
            select ob_ore_cost union all
            select ge_ore_cost
        )x(oc)
        where @part = 1 or id <= 3
        group by id, or_ore_cost, cl_ore_cost, ob_ore_cost, ob_clay_cost, ge_ore_cost, ge_obsidian_cost;

    insert into @eval (iteration,blueprint,mins,orebots,clybots,obsbots,geobots,ore,clay,obsidian,geode,is_orebots_maxed,is_clybots_maxed,is_obsbots_maxed)
        select iteration = 0
            ,blueprint = id
            ,mins = @minutes
            ,orebots = 1, clybots = 0, obsbots = 0, geobots = 0
            ,ore = 0, clay = 0, obsidian = 0, geode = 0
            ,is_orebots_maxed = 0
            ,is_clybots_maxed = 0
            ,is_obsbots_maxed = 0
        from @blueprint;
            
    declare @itno tinyint = 1;
    declare @rowcount bigint = 1;
    declare @max_geode smallint;
    declare @bpid tinyint = 1;
    declare @max_bpid tinyint;

    select @max_bpid = max(id) from @blueprint;

    while @rowcount > 0 begin;
        insert into @eval (iteration,blueprint,mins,orebots,clybots,obsbots,geobots,ore,clay,obsidian,geode,is_orebots_maxed,is_clybots_maxed,is_obsbots_maxed)
            select iteration = @itno
                ,blueprint = e.blueprint
                ,mins = p.mins
                ,orebots = p.orebots, clybots = p.clybots, obsbots = p.obsbots, geobots = p.geobots
                ,ore = p.ore, clay = p.clay, obsidian = p.obsidian, geode = p.geode
                ,is_orebots_maxed = is_orebots_maxed | cast(iif(p.orebots = max_ore_cost, 1, 0) as bit)
                ,is_clybots_maxed = is_clybots_maxed | cast(iif(p.clybots = ob_clay_cost, 1, 0) as bit)
                ,is_obsbots_maxed = is_obsbots_maxed | cast(iif(p.obsbots = ge_obsidian_cost, 1, 0) as bit)
            from @eval e
            join @blueprint bp on e.blueprint = bp.id
            cross apply (
                select mins = e.mins - iif(x.mins > 0, x.mins, 1)
                    ,orebots = e.orebots + iif([value] = 1, 1, 0)
                    ,clybots = e.clybots + iif([value] = 2, 1, 0)
                    ,obsbots = e.obsbots + iif([value] = 3, 1, 0)
                    ,geobots = e.geobots + iif([value] = 4, 1, 0)
                    ,ore = e.ore + (x.mins * e.orebots) - choose([value], or_ore_cost, cl_ore_cost, ob_ore_cost, ge_ore_cost)
                    ,clay = e.clay + (x.mins * e.clybots) - choose([value], 0, 0, ob_clay_cost, 0)
                    ,obsidian = e.obsidian + (x.mins * e.obsbots) - choose([value], 0, 0, 0, ge_obsidian_cost)
                    ,geode = e.geode + (x.mins * e.geobots)
                from (select 1 union all select 2 union all select 3 union all select 4) s([value])
                cross apply (values(
                    choose([value],
                        ceiling((or_ore_cost - e.ore) / nullif(e.orebots, 0)),
                        ceiling((cl_ore_cost - e.ore) / nullif(e.orebots, 0)),
                        iif(isnull(ceiling((ob_ore_cost - e.ore) / nullif(e.orebots, 0)), 99) > isnull(ceiling((ob_clay_cost - e.clay) / nullif(e.clybots, 0)), 99),
                            isnull(ceiling((ob_ore_cost - e.ore) / nullif(e.orebots, 0)), 99),
                            isnull(ceiling((ob_clay_cost - e.clay) / nullif(e.clybots, 0)), 99)
                        ),
                        iif(isnull(ceiling((ge_ore_cost - e.ore) / nullif(e.orebots, 0)), 99) > isnull(ceiling((ge_obsidian_cost - e.obsidian) / nullif(e.obsbots, 0)), 99),
                            isnull(ceiling((ge_ore_cost - e.ore) / nullif(e.orebots, 0)), 99),
                            isnull(ceiling((ge_obsidian_cost - e.obsidian) / nullif(e.obsbots, 0)), 99)
                        )
                    ) + 1)
                ) x(mins)
                where x.mins <= e.mins
                    and choose([value], is_orebots_maxed, is_clybots_maxed, is_obsbots_maxed, cast(0 as bit)) = cast(0 as bit)
            ) p
            where e.mins >= 0
                and p.geode + p.geobots * p.mins + ((p.mins - 1) * p.mins / 2) > bp.max_geode

        set @rowcount = @@rowcount;

        delete from @eval 
        where iteration = @itno - 1;

        set @bpid = 1;
        while @bpid <= @max_bpid begin;
            set @max_geode = 0;

            select @max_geode = max(geode) 
            from @eval 
            where iteration = @itno and blueprint = @bpid;

            update @blueprint set 
                max_geode = iif(@max_geode > max_geode, @max_geode, max_geode) 
            where id = @bpid;

            set @bpid += 1;
        end;

        set @itno +=1
    end;

    if @part = 1 begin;
        select part1 = sum(id * max_geode)
        from @blueprint;
    end;
    else begin;
        --select part2 = exp(sum(log(max_geode)))
        select id, max_geode
        from @blueprint;
    end;
end;
go

declare @ varchar(max) = '['+trim(char(10) from (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/19.input', single_clob) d))+']';
select @ = replace(@, tr, rw) from (values
    ('Blueprint ', '['),(': Each ore robot costs ', ','),(' ore. Each clay robot costs ', ','),
    (' ore. Each obsidian robot costs ', ','),(' ore and ', ','),(' clay. Each geode robot costs ', ','),
    (' obsidian.', ']'),(char(10), ',')
) r(tr, rw);

-- part 1
exec blueprint_evaluator @, 1;
-- part 2
exec blueprint_evaluator @, 2;