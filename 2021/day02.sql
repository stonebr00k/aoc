-- Get input as string
declare @input nvarchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2021/input02.dat', single_clob) d); --<< Enter path to your input file here
-- Convert input to JSON
declare @input_json nvarchar(max) = N'["' + replace(replace(replace(@input, nchar(13) + nchar(10), N'","'), nchar(10), N'","'), nchar(13), N'","') + N'"]';

-- Part 1
select part_1 = sum(iif(direction = N'f', [value], 0)) * sum(iif(direction = N'u', -1, 1) * iif(direction = N'f', 0, [value]))
from (
    select id = cast([key] as int)
        ,direction = cast(left([value], 1) as char(1))
        ,[value] = cast(substring([value], charindex(N' ', [value]) + 1, len([value])) as smallint)
    from openjson(@input_json)
) m;

-- Part 2
with change as (
    select horizontal = [value] * h_mod
        ,depth = [value] * h_mod * sum(d_mod * [value]) over(order by rid rows between unbounded preceding and current row)
    from (
        select rid = cast([key] as int)
            ,h_mod = cast(iif(left([value], 1) = N'f', 1, 0) as tinyint)
            ,d_mod = cast(iif(left([value], 1) = N'f', 0, 1) * iif(left([value], 1) = N'd', 1, -1) as smallint)
            ,[value] = cast(substring([value], charindex(N' ', [value]) + 1, len([value])) as smallint)
        from openjson(@input_json)
    ) m
)

select part_2 = sum(horizontal) * sum(depth)
from change;