/*  AoC 2023-09 (https://adventofcode.com/2023/day/9)  */
declare @report nvarchar(max) = replace((select BulkColumn from openrowset(bulk 'C:/repo/stonebr00k/aoc/input/2023/09', single_clob)_), char(13), '');
set @report = concat(N'[[', replace(replace(@report, nchar(10), N'],['), N' ', N','), N']]');

with predictor as (
    select id = cast([key] as tinyint)
        ,iteration = 0
        ,[sequence] = (select v = cast([value] as int) from openjson([value]) v order by cast([key] as int) for json path)
        ,last_index = last_index - 1
        ,p1_value = cast(json_value([value], concat(N'$[', last_index, N']')) as int)
        ,p2_value = cast(json_value([value], N'$[0]') as int)
    from openjson(@report)
    cross apply (values(len([value]) - len(replace([value], N',', N'')))) _(last_index)
    union all
    select id = c.id
        ,iteration = c.iteration + 1
        ,[sequence] = diff.[sequence]
        ,last_index = c.last_index - 1
        ,p1_value = cast(json_value(diff.[sequence], concat(N'$[', c.last_index, N'].v')) as int)
        ,p2_value = cast(json_value(diff.[sequence], N'$[0].v') as int)
    from predictor c
    cross apply (
        select v
        from (
            select v = v - lag(v) over(order by cast([key] as tinyint))
            from openjson(c.[sequence])
            cross apply (values(cast(json_value([value], N'$.v') as int))) _(v)
        ) x
        where v is not null
        for json path
    ) diff([sequence])
    where diff.[sequence] like N'%[1-9]%'
)

select part1 = sum(p1_value)
    ,part2 = sum(iif(iteration % 2 = 1, -1, 1) * p2_value)
from predictor;
go
