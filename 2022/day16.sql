/*  AoC 2022-16 (https://adventofcode.com/2022/day/16)  */
drop table if exists valve, leads_to, graph, #part2;
drop function if exists pressure_releaser;
create table valve (id int not null, code char(2) not null, flow_rate int not null, leads_to nvarchar(max) not null, primary key (id)) as node;
create table leads_to as edge;
create table graph (valve_from int not null, valve_to int not null, distance int not null, flow_rate int not null, primary key (valve_from, valve_to));
go
create or alter function pressure_releaser (@minutes int)
returns table as return (
    with rcte as (
        select valve = 0, mins = @minutes, pressure = 0, open_valves = 0
        union all
        select valve = g.valve_to
            ,mins = m.mins
            ,pressure = r.pressure + (g.flow_rate * m.mins)
            ,open_valves = set_bit(r.open_valves, g.valve_to)
        from rcte r
        join graph g 
            on r.valve = g.valve_from
            and r.mins - 1 > g.distance
            and get_bit(r.open_valves, g.valve_to) = 0
        cross apply (values(r.mins - g.distance - 1)) m(mins)
    )
    select valve, mins, pressure, open_valves from rcte
);
go

declare @ varchar(max) = '[['+trim(char(10) from (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/16.input', single_clob) d)) + '"]]]';
select @ = replace(@, tr, rw) from (values
    (' has flow rate=', '",'),('; tunnel leads to valve ', ',["'),('; Tunnels lead to valves ', ',["'),
    ('Valve ', '"'),(', ', '","'),(char(10), '"]],[')
) r(tr, rw);

insert into valve (id, code, flow_rate, leads_to)
    select id = row_number() over(order by iif(code = 'AA' or flow_rate > 0, 0, 1), code) - 1, code, flow_rate, leads_to
    from openjson(@) with (code char(2) '$[0]', flow_rate int '$[1]', leads_to nvarchar(max) '$[2]' as json);

insert into leads_to
    select f.$node_id, tv.$node_id
    from valve f
    cross apply openjson(leads_to) with(code char(2) '$') t
    join valve tv on t.code = tv.code;

insert into graph(valve_from, valve_to, distance, flow_rate)  
    select valve_from, valve_to, distance, flow_rate
    from (
        select valve_from = vf.id
            ,valve_to = last_value(vt.id) within group (graph path) 
            ,distance = count(vt.id) within group (graph path)
            ,flow_rate = last_value(vt.flow_rate) within group (graph path)
        from valve vf, leads_to for path l, valve for path vt
        where (vf.id = 0 or vf.flow_rate > 0) and match(shortest_path(vf(-(l)->vt)+))
    ) graph
    where flow_rate > 0
    option(maxdop 1);

select part1 = max(pressure) 
from pressure_releaser(30);

select valve, pressure, open_valves into #part2 from pressure_releaser(26);
create nonclustered index ncix_#part2 on #part2 (valve, open_valves) include (pressure);

select part2 = max(me.pressure + el.pressure)
from #part2 me
join #part2 el
    on me.valve > el.valve
    and me.open_valves & el.open_valves = 0;
