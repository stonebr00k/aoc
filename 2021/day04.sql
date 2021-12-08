declare @input nvarchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2021/04.input', single_clob) d);
declare @numbers_json nvarchar(max) = N'[' + substring(@input, 1, charindex(nchar(13), @input) - 1) + N']';
declare @boards nvarchar(max) = substring(@input,charindex(nchar(13), @input) + 1, len(@input));
declare @boards_json nvarchar(max) = N'[' + substring(replace(replace(replace(replace(replace(replace(replace(replace(@boards,
    nchar(13) + nchar(10), nchar(10)),
    nchar(13), nchar(10)),
    nchar(10) + N' ', nchar(10)),
    N' ', nchar(17) + nchar(18)),
    nchar(18) + nchar(17), N''),
    nchar(17) + nchar(18), N','),
    replicate(nchar(10),2), N']],[['),
    nchar(10), N'],['), 4, len(@input)*2) + N']]]';

with board as (
    select id = cast(b.[key] as tinyint)
        ,number = cast(c.[value] as tinyint)
        ,match_idx = cast(n.[key] as tinyint)
        ,row_complete_idx = max(cast(n.[key] as tinyint)) over(partition by b.[key], r.[key])
        ,col_complete_idx = max(cast(n.[key] as tinyint)) over(partition by b.[key], c.[key])
    from openjson(@boards_json) b
    cross apply openjson(b.[value]) r
    cross apply openjson(r.[value]) c
    left join openjson(@numbers_json) n
        on cast(c.[value] as tinyint) = cast(n.[value] as tinyint)
)
,bingo as (
    select board_id = id
        ,idx = iif(min(row_complete_idx) < min(col_complete_idx), min(row_complete_idx), min(col_complete_idx))
        ,[first] = iif(row_number() over(order by iif(min(row_complete_idx) < min(col_complete_idx), min(row_complete_idx), min(col_complete_idx))) = 1, 1, 0)
        ,[last] = iif(row_number() over(order by iif(min(row_complete_idx) < min(col_complete_idx), min(row_complete_idx), min(col_complete_idx)) desc) = 1, 1, 0)
    from board
    group by id
)

select part = 1, answer = sum(iif(bo.idx = bd.match_idx, bd.number, 0)) * sum(iif(bo.idx = bd.match_idx, 0, bd.number))
from bingo bo
join board bd
    on bo.board_id = bd.id
    and bo.idx <= bd.match_idx
where bo.[first] = 1
union all
select part = 2, answer = sum(iif(bo.idx = bd.match_idx, bd.number, 0)) * sum(iif(bo.idx = bd.match_idx, 0, bd.number))
from bingo bo
join board bd
    on bo.board_id = bd.id
    and bo.idx <= bd.match_idx
where bo.[last] = 1;
go
