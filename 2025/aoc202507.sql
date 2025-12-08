/*  AoC 2025-07 (https://adventofcode.com/2025/day/7)  */
create or alter function beam_splitter (
    @spliters nvarchar(1000),
    @beams nvarchar(1000)
)
returns table as return (
    select beams = json_arrayagg(beam)
        ,splits = sum(iif(cs = '^' and c > 0, 1, 0))
        ,time_lines = sum(beam)
    from openjson(@beams)
    cross apply (
        select c = cast([value] as bigint)
            ,n = cast(json_value(@beams, concat('$[', cast([key] as int)+1,']')) as bigint)
            ,p = cast(json_value(@beams, concat('$[', cast([key] as int)-1,']')) as bigint)
            ,cs = substring(@spliters, cast([key] as int)+1, 1)
            ,ns = substring(@spliters, cast([key] as int)+2, 1)
            ,ps = substring(@spliters, cast([key] as int), 1)
    ) v
    cross apply (values(iif(cs = N'^', 0, c + iif(ns = '^', n, 0) + iif(ps = '^', p, 0)))) b(beam)
);
go

declare @input nvarchar(max) = replace((select BulkColumn from openrowset(bulk 'C:\repo\stonebr00k\aoc\input\2025\07', single_clob)_), nchar(13), N'');
declare @json varchar(max) = concat('["', replace(trim(nchar(10) from @input), char(10), '","'), '"]');
set @json = (select json_arrayagg([value]) from openjson(@json) where [key] = 0 or charindex(N'^', [value]) > 0);

with quantum_tachyon_manifold as (
    select r = 1
        ,beams = json_arrayagg(iif(substring(l, c.[value], 1) = 'S', 1, 0))
        ,splits = 0
        ,time_lines = cast(0 as bigint)
    from (values(json_value(@json, '$[0]'))) _(l)
    cross apply generate_series(1, cast(len(l) as int)) c
    union all
    select r = r + 1
        ,beams = b.beams
        ,splits = b.splits
        ,time_lines = b.time_lines
    from quantum_tachyon_manifold
    cross apply beam_splitter(json_value(@json, concat('$[', r, ']')), beams) b
    where json_value(@json, concat('$[', r, ']')) is not null
)

select part_1 = sum(splits)
    ,part_2 = max(time_lines)
from quantum_tachyon_manifold
option(maxrecursion 0);
