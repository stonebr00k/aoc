set nocount on;
drop table if exists #connection;
drop table if exists #point;
go

create table #point (
    id int not null,
    x smallint not null,
    y smallint not null,
    risk tinyint not null,
    current_risk int not null,
    predecessor int null,
    is_done bit not null default 0,
    constraint pk_#point primary key clustered (id),
    index ix1 nonclustered (is_done, current_risk)
)
go

create table #connection (
    from_id int not null,
    to_id int not null,
    constraint pk_#connection primary key clustered (from_id, to_id)
)
go

declare @input nvarchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2021/15.input', single_clob) d);
declare @json nvarchar(max) = N'["' + replace(trim(nchar(10) from @input), nchar(10), N'","') + N'"]';
declare @square_size tinyint = 100;

insert into #point (id, x, y, risk, current_risk)
    select id = row_number() over(order by inp.x + (ex.x * @square_size), inp.y + (ey.y * @square_size)) - 1
        ,x = inp.x + (ex.x * @square_size) 
        ,y = inp.y + (ey.y * @square_size) 
        ,risk = iif(inp.risk + ex.x + ey.y > 9, inp.risk + ex.x + ey.y -9, inp.risk + ex.x + ey.y)
        ,current_risk = iif(row_number() over(order by inp.x + (ex.x * @square_size), inp.y + (ey.y * @square_size)) = 1, 0, sum(iif(inp.risk + ex.x + ey.y > 9, inp.risk + ex.x + ey.y -9, inp.risk + ex.x + ey.y)) over() + 1)
    from openjson(@json)
    cross join (values(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) i10(i)
    cross join (values(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) i1(i)
    cross apply (
        select x = cast(i10.i * 10 + i1.i as tinyint)
            ,y = cast([key] as tinyint)
            ,risk = cast(substring([value], i10.i * 10 + i1.i + 1, 1) as tinyint)
    ) inp
    cross join (values(0),(1),(2),(3),(4)) ex(x)
    cross join (values(0),(1),(2),(3),(4)) ey(y)
    where inp.x < len(json_value(@json, N'$[0]'));

with cnct as (
    select from_id = id
        ,to_id = choose(d.idx,
            lag (id, 1) over(partition by y, d.idx order by x),
            lead(id, 1) over(partition by y, d.idx order by x),
            lag (id, 1) over(partition by x, d.idx order by y),
            lead(id, 1) over(partition by x, d.idx order by y)
        )
    from #point p
    cross join (values(1),(2),(3),(4)) d(idx)
)

insert into #connection(from_id, to_id)
    select from_id, to_id 
    from cnct 
    where to_id is not null;

declare @max_risk int = (select sum(risk) from #point) + 1;
declare @part1_end_point int = (select id from #point where x = 99 and y = 99);
declare @part2_end_point int = (select top 1 id from #point order by id desc);
declare @from_point int;
declare @current_risk int;

while 1 = 1 begin;
    set @from_point = null;

    select top 1 @from_point = id, @current_risk = current_risk
    from #point
    where is_done = 0
        and current_risk < @max_risk
    order by current_risk;

    if @from_point = @part1_end_point select part_1 = @current_risk;
    else if @from_point = @part2_end_point select part_2 = @current_risk;

    if nullif(@from_point, @part2_end_point) is null break;

    update #point set is_done = 1 where id = @from_point;

    update p set 
        current_risk = @current_risk + p.risk, 
        predecessor = @from_point
    from #connection c
    join #point p
        on c.to_id = p.id
        and p.is_done = 0
        and p.current_risk > @current_risk + p.risk
    where c.from_id = @from_point;
end;
go
