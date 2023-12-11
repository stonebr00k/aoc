/*  AoC 2023-02 (https://adventofcode.com/2023/day/2)  */
declare @ varchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2023/02', single_clob)_);
set @ = concat('[{', replace(replace(replace(replace(@,'; ', N'","'),char(13) + char(10), '"]},{'),': ', ', "cubes":["'),'Game', '"game":'), '"]}]');

with max_cubes as (
    select a.game
        ,r = max(iif(c.[value] like N'%red', cast(substring(ltrim(c.[value]), 1, charindex(N' ', ltrim(c.[value])) - 1) as int), null))
        ,g = max(iif(c.[value] like N'%green', cast(substring(ltrim(c.[value]), 1, charindex(N' ', ltrim(c.[value])) - 1) as int), null))
        ,b = max(iif(c.[value] like N'%blue', cast(substring(ltrim(c.[value]), 1, charindex(N' ', ltrim(c.[value])) - 1) as int), null))
    from openjson(@) with (game int, cubes nvarchar(max) as json) a
    cross apply openjson(a.cubes) b
    cross apply string_split(b.[value], ',') c
    group by a.game
)

select part1 = sum(iif(r <= 12 and g <= 13 and b <= 14, game, 0))
    ,part2 = sum(r * g * b)
from max_cubes;
go
