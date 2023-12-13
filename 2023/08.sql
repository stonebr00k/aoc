/*  AoC 2023-08 (https://adventofcode.com/2023/day/8)  */
-- Create function to find greatest common divisor
create or alter function gcd (
    @a bigint,
    @b bigint
)
returns table
as return (
    with gdc as (
        select a = greatest(abs(@a), abs(@b))
            ,b = least(abs(@a), abs(@b))
            ,c = greatest(abs(@a), abs(@b)) % least(abs(@a), abs(@b))
        where @a is not null and @b is not null
        union all
        select a = b
            ,b = c
            ,c = b % c
        from gdc
        where c > 0
    )

    select [value] = iif(
        @a = 0 or @b = 0,
        abs(@a) + abs(@b),
        isnull((select b from gdc where c = 0), null)
    )
);
go

-- Create function to find least common multiplier
create or alter function lcm (
    @a bigint,
    @b bigint
)
returns table
as return (
    select [value] = iif(abs(@a) + abs(@b) = 0, 0, (select abs(@a) * (abs(@b) / [value]) from gcd(@a, @b)))
);
go

declare @ nvarchar(max) = replace((select BulkColumn from openrowset(bulk 'C:/repo/stonebr00k/aoc/input/2023/08', single_clob)_), char(13), '');

set @ = concat(
    N'{"instr":"',
    replace(replace(replace(replace(@, 
        replicate(nchar(10), 2), N'","network":[["'),
        N')' + nchar(10), N'"],["'),
        N' = (', N'","'),
        N', ', N'","'),
    N'"]]}');

declare @istr nvarchar(1000) = json_value(@, N'$.instr');
declare @icount smallint = len(@istr);
declare @instructions nvarchar(1000) = N'[' + substring(replace(replace(@istr, N'L', N'1,'), N'R', N'2,'), 1, @icount * 2 - 1) + N']';

drop table if exists #network, #distance;
create table #network(
    [node] char(3) not null primary key,
    l char(3) not null,
    r char(3) not null
);
create table #distance(
    id tinyint not null identity(1, 1) primary key,
    start_node char(3) not null,
    [value] bigint not null
);

insert into #network([node], l, r)
    select [node], l, r
    from openjson(@, N'$.network') with ([node] char(3) N'$[0]', l char(3) N'$[1]', r char(3) N'$[2]');

-- Part 1
with network_navigator as (
    select i = 0
        ,n = cast('AAA' as char(3))
    union all
    select i = i + iif(i = @icount - 1, -i, 1)
        ,n = choose(dir.lr, n.l, n.r)
    from network_navigator nn
    join #network n on nn.n = n.[node]
    cross apply (values(json_value(@instructions, concat(N'$[', i, N']')))) dir(lr)
    where nn.n < 'ZZZ'
)

select part1 = count(*) - 1
from network_navigator
option (maxrecursion 0);

-- Part 2
with network_navigator as (
    select start_node = [node]
        ,i = 0
        ,[node] = [node]
    from #network
    where [node] like '__A'
    union all
    select start_node = nn.start_node
        ,i = nn.i + iif(nn.i = @icount - 1, -nn.i, 1)
        ,[node] = choose(dir.lr, n.l, n.r)
    from network_navigator nn
    join #network n on nn.[node] = n.[node]
    cross apply (values(json_value(@instructions, concat(N'$[', nn.i, N']')))) dir(lr)
    where nn.[node] not like '__Z'
)

insert into #distance (start_node, [value])
    select start_node, count(*) -1
    from network_navigator
    group by start_node
    option (maxrecursion 0);

with lcm_computer as (
    select i = 1, [value] = [value]
    from #distance
    where id = 1
    union all
    select i = i + 1, [value] = lcm.[value]
    from lcm_computer c
    join #distance d on c.i = d.id - 1
    cross apply lcm(c.[value], d.[value]) lcm
)

select top 1 part2 = [value]
from lcm_computer
order by i desc;

-- Cleanup
drop function if exists lcd, gcd;
go