create or alter function dbo.get_integer_range (
    @start int,
    @end int
)
returns table
as return (
    with 
        e1(n) as (select 1 union all select 1),      --2
        e2(n) as (select 1 from e1 cross join e1 x), --4
        e3(n) as (select 1 from e2 cross join e2 x), --16
        e4(n) as (select 1 from e3 cross join e3 x), --256
        e5(n) as (select 1 from e4 cross join e4 x), --65 536
        ex(n) as (select top (abs(@end - (@start - 1))) cast(row_number() over (order by (select null)) as int) from e5)

    select [value] = n + (@start - 1)
    from ex
);
go

declare @input nvarchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2021/05.input', single_clob) d);
declare @json nvarchar(max) = N'[[' + replace(replace(@input, N' -> ', N','), nchar(10), N'],[') + N']]';

select top 1 part_1 = count(*) over()
from openjson(@json) with (x1 smallint N'$[0]', y1 smallint N'$[1]', x2 smallint N'$[2]', y2 smallint N'$[3]') l
cross apply dbo.get_integer_range(0, abs(iif(x1 = x2, y1 - y2, x1 - x2))) i
where x1 = x2 or y1 = y2
group by x1 + iif(x1 = x2, 0, iif(x1 < x2, 1, -1)) * i.[value]
    ,y1 + iif(y1 = y2, 0, iif(y1 < y2, 1, -1)) * i.[value]
having count(*) > 1;

select top 1 part_2 = count(*) over()
from openjson(@json) with (x1 smallint N'$[0]', y1 smallint N'$[1]', x2 smallint N'$[2]', y2 smallint N'$[3]') l
cross apply dbo.get_integer_range(0, abs(iif(x1 = x2, y1 - y2, x1 - x2))) i
where x1 is not null
group by x1 + iif(x1 = x2, 0, iif(x1 < x2, 1, -1)) * i.[value]
    ,y1 + iif(y1 = y2, 0, iif(y1 < y2, 1, -1)) * i.[value]
having count(*) > 1;
go
