/*  AoC 2025-09 (https://adventofcode.com/2025/day/9)  */
declare @input nvarchar(max) = replace((select BulkColumn from openrowset(bulk 'C:\repo\stonebr00k\aoc\input\2025\09', single_clob)_), nchar(13), N'');
declare @json json = concat('[[', replace(trim(char(10) from @input), char(10), N'],['), ']]');

drop table if exists #red_tiles, #squares;
create table #red_tiles (
    id smallint not null primary key,
    x bigint not null,
    y bigint not null,
    p varchar(32) not null
);
create table #squares (
    [size] bigint not null,
    geo geometry,
    index ix_square ([size] desc)
);

insert into #red_tiles
    select id = cast([key] as int)
        ,x = cast(json_value([value], '$[0]') as bigint)
        ,y = cast(json_value([value], '$[1]') as bigint)
        ,p = cast(concat(json_value([value], '$[0]'), N' ', json_value([value], '$[1]')) as nvarchar(max))
    from openjson(@json);

insert into #squares ([size], geo)
    select [size] = (abs(a.x - b.x) + 1) * (abs(a.y - b.y) + 1)
        ,geo = geometry::STGeomFromText(iif(a.x = b.x or a.y = b.y,
            concat('linestring (', a.p, ',', b.p, ')'),
            concat('polygon ((', a.p, ',', a.x, ' ', b.y, ',', b.p, ',', b.x, ' ', a.y, ',', a.p,'))')
        ), 0)
    from #red_tiles a
    join #red_tiles b on a.id < b.id

declare @green_tiles geometry = geometry::STGeomFromText((
    select concat('polygon ((', string_agg(p, ',') within group(order by id), ',', max(iif(id = 0, p, null)), '))')
    from #red_tiles
), 0);

select part_1 = (
        select top 1 [size]
        from #squares
        order by [size] desc
    ),
    part_2 = (
        select top 1 [size]
        from #squares
        where @green_tiles.STContains(geo) = 1
        order by [size] desc
    );
