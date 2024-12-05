/*  AoC 2024-05 (https://adventofcode.com/2024/day/5)  */
go
create or alter function reorder_pages (
    @pages nvarchar(max),
    @rules varchar(max)
)
returns table
as return (
    with page_reorderer as (
        select i = 0, pages = @pages
        union all
        select i = po.i + 1, pages = iif(idx.x < idx.y, po.pages, stuff(replace(po.pages, N',' + _.x, N''), idx.y, 0, _.x + N','))
        from page_reorderer po
        cross apply (values(json_value(@rules, concat('$[', po.i,'][0]')), json_value(@rules, concat('$[', po.i,'][1]')))) _(x, y)
        cross apply (values(charindex(_.x, po.pages), charindex(_.y, po.pages))) idx(x, y)
        where _.x is not null
    )
    select top 1 pages from page_reorderer order by i desc
);
go

declare @input varchar(max) = replace((select BulkColumn from openrowset(bulk 'C:/repo/stonebr00k/aoc/input/2024/05', single_clob)_), nchar(13), '');
declare @rules_list varchar(max) = substring(@input, 1, charindex(char(10)+char(10), @input) - 1);
declare @updates_list varchar(max) = substring(@input, charindex(char(10)+char(10), @input) + 2, len(@input));

select part_1 = sum(iif(rules.is_valid = 1, cast(m.[value] as int), 0))
    ,part_2 = sum(iif(rules.is_valid = 0, cast(m.[value] as int), 0))
from string_split(@updates_list, char(10), 1) s
outer apply (
    select [value] = nullif(concat('[', string_agg(concat('[', r.x, ',', r.y, ']'), ',') within group (order by r.x, r.y), ']'), N'[]')
        ,is_valid = cast(max(iif(idx.x < idx.y, 0, 1)) as bit)
    from (
        select x = left([value], 2), y = right([value], 2)
        from string_split(@rules_list, char(10), 1)
    ) r
    cross apply (values(charindex(r.x, s.[value]), charindex(r.y, s.[value]))) idx(x, y)
    where idx.x > 0 and idx.y > 0
) rules
cross apply reorder_pages(s.[value], iif(rules.is_valid = 1, rules.[value], null)) p
cross apply openjson(concat(N'[', p.pages, N']')) m
where (len(s.[value]) - len(replace(s.[value], ',', ''))) / 2 = cast(m.[key] as tinyint)
option (maxrecursion 0);
go
