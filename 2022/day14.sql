/*  AoC 2022-14 (https://adventofcode.com/2022/day/14)  */
set nocount on;
declare @ nvarchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/14.input', single_clob) d);
set @ = '[[[' + replace(replace(trim(char(10) from @), N' -> ', N'],['), char(10), ']],[[') + N']]]';

drop table if exists #cave;
create table #cave (x int not null, y int not null, is_sand tinyint not null, primary key (x, y));

with rocks as (
    select l, p, x1 = x, y1 = y
        ,x2 = lead(x) over(partition by l order by p)
        ,y2 = lead(y) over(partition by l order by p)
    from openjson(@) line
    cross apply openjson(line.[value]) point
    cross apply (values(
        cast(line.[key] as int),
        cast(point.[key] as int),
        cast(json_value(point.[value], '$[0]') as int),
        cast(json_value(point.[value], '$[1]') as int)
    )) d(l, p, x, y)
)

insert into #cave (x, y, is_sand)
    select distinct x = iif(is_x = 1, s.[value], x1)
        ,y = iif(is_x = 0, s.[value], y1)
        ,is_sand = 0
    from rocks
    cross apply (values(cast(iif(x1 = x2, 0, 1) as bit))) d(is_x)
    cross apply generate_series(iif(is_x = 1, x1, y1), iif(is_x = 1, x2, y2)) s
    where x2 is not null and y2 is not null;

declare @floor int = (select max(y) + 2 from #cave);
declare @x int = 500, @y int = 0, @part1 int;

while 1 = 1 begin;
    set @y = isnull((select min(y) from #cave where x = @x and y > @y), @floor);

    if @part1 is null and @y = @floor set @part1 = (select sum(is_sand) from #cave);

    if exists(select * from #cave where x = @x - 1 and y = @y) or @y = @floor begin;
        if exists(select * from #cave where x = @x + 1 and y = @y) or @y = @floor begin;
            insert into #cave (x, y, is_sand) values(@x, @y-1, 1);
            if @y = 1 break;
            set @x = 500; set @y = 0;
        end;
        else set @x = @x + 1;
    end;
    else set @x = @x - 1;
end;

select part1 = @part1, part2 = sum(is_sand) 
from #cave;
