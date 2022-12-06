declare @ varchar(max) = trim(nchar(10) from (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2015/13.input', single_clob) d));
drop table if exists #list;
set @ = '[["' + replace(replace(replace(replace(replace(@, 
    ' would ', '",'),
    'lose ', '-'),
    'gain ', ''),
    ' happiness units by sitting next to ', ',"'),
    '.' + char(10), '"],["') +'"]]';

select p1 = cast(p1 as char(1)), p2 = cast(p2 as char(1)), hu = hu, prt = cast(1 as tinyint)
into #list
from openjson(@) with (p1 varchar(16) '$[0]', p2 varchar(16) '$[2]', hu int '$[1]');

create unique clustered index ucix_#list on #list (p1, p2);

-- PART 1
with seat_optimizer as (
    select top 1 with ties i = 1
        ,p = a.p2
        ,hu = a.hu + b.hu
        ,pth = cast(a.p1 + a.p2 as varchar(max))
    from #list a 
    join #list b on a.p1 = b.p2 and a.p2 = b.p1
    order by a.p1
    union all
    select i = so.i + 1
        ,p = a.p2
        ,hu = so.hu + a.hu + b.hu
        ,pth = so.pth + a.p2
    from seat_optimizer so
    join #list a on so.p = a.p1
    join #list b on a.p1 = b.p2 and a.p2 = b.p1
    where (so.i < 7 and so.pth not like '%' + a.p2 + '%')
        or (so.i = 7 and so.pth like a.p2 + '%')
)   

select top 1 hu
from seat_optimizer
where i = 8
order by hu desc;

-- PART 2
insert into #list (p1, p2, hu, prt)
    select distinct p1, 'Z', 0, 2 from #list union all
    select distinct 'Z', p1, 0, 2 from #list;

with seat_optimizer as (
    select top 1 with ties i = 1
        ,p = a.p2
        ,hu = a.hu + b.hu
        ,pth = cast(a.p1 + a.p2 as varchar(max))
    from #list a 
    join #list b on a.p1 = b.p2 and a.p2 = b.p1
    order by a.p1
    union all
    select i = so.i + 1
        ,p = a.p2
        ,hu = so.hu + a.hu + b.hu
        ,pth = so.pth + a.p2
    from seat_optimizer so
    join #list a on so.p = a.p1
    join #list b on a.p1 = b.p2 and a.p2 = b.p1
    where (so.i < 8 and so.pth not like '%' + a.p2 + '%')
        or (so.i = 8 and so.pth like a.p2 + '%')
)   

select top 1 hu
from seat_optimizer
where i = 9
order by hu desc;