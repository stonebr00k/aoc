/*  AoC 2022-12 (https://adventofcode.com/2022/day/12)  */
drop table if exists #connection; drop table if exists #point;
create table #point (
    id int not null,
    x smallint not null,
    y smallint not null,
    height tinyint not null,
    steps smallint not null,
    predecessor int null,
    is_done bit not null default 0,
    is_end bit not null
    constraint pk_#point primary key clustered (id),
    index ix1 nonclustered (is_done, steps)
);
create table #connection (
    from_id int not null,
    to_id int not null,
    constraint pk_#connection primary key clustered (from_id, to_id)
);

declare @ varchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/12.input', single_clob) d);
set @ = '["' + replace(replace(trim(char(10) from @), char(10), '","'), ' ', '",') + '"]';

insert into #point (id, x, y, height, steps, is_end)
    select id = row_number() over(order by cast(x.[value] as tinyint), cast(y.[key] as tinyint))
        ,x = cast(x.[value] as tinyint)
        ,y = cast(y.[key] as tinyint) + 1
        ,height = case ascii(substring(y.[value], x.[value], 1))
            when 83 then 1 when 69 then 26 else ascii(substring(y.[value], x.[value], 1)) -96 end
        ,steps = iif(ascii(substring(y.[value], x.[value], 1)) = 69, 0, count(*) over() + 1)
        ,is_end = cast(iif(ascii(substring(y.[value], x.[value], 1)) = 83, 1, 0) as bit)
    from openjson(@) y
    cross apply generate_series(cast(1 as tinyint), cast(len(y.[value]) as tinyint)) x;

with cnct as (
    select from_id = id
        ,from_height = height
        ,to_id = choose(d.idx,
            lag (id, 1) over(partition by y, d.idx order by x),
            lead(id, 1) over(partition by y, d.idx order by x),
            lag (id, 1) over(partition by x, d.idx order by y),
            lead(id, 1) over(partition by x, d.idx order by y)
        )
        ,to_height = choose(d.idx,
            lag (height, 1) over(partition by y, d.idx order by x),
            lead(height, 1) over(partition by y, d.idx order by x),
            lag (height, 1) over(partition by x, d.idx order by y),
            lead(height, 1) over(partition by x, d.idx order by y)
        )
    from #point p
    cross join (values(1),(2),(3),(4)) d(idx)
)

insert into #connection(from_id, to_id)
    select from_id, to_id 
    from cnct 
    where to_height >= from_height - 1;

declare @max_steps int = (select count(*) from #point) + 1;
declare @part1_end_point int = (select id from #point where is_end = 1);
declare @from_point int, @steps int, @height tinyint, @part1 int, @part2 int;

while 1 = 1 begin;
    set @from_point = null;

    select top 1 @from_point = id, @steps = steps, @height = height
    from #point
    where is_done = 0 and steps < @max_steps
    order by steps;

    if @height = 1 set @part2 = isnull(@part2, @steps);
    if @from_point = @part1_end_point set @part1 = @steps;

    if nullif(@from_point, @part1_end_point) is null break;

    update #point set is_done = 1 where id = @from_point;

    update p set steps = @steps + 1, predecessor = @from_point
    from #connection c
    join #point p
        on c.to_id = p.id
        and p.is_done = 0
        and p.steps > @steps + 1
    where c.from_id = @from_point;
end;

select part1 = @part1, part2 = @part2;
go
