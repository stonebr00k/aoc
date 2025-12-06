/*  AoC 2025-06 (https://adventofcode.com/2025/day/6)  */
declare @input nvarchar(max) = (select BulkColumn from openrowset(bulk 'C:\repo\stonebr00k\aoc\input\2025\06', single_clob)_);
set @input = trim(nchar(10) from replace(@input, nchar(13), ''));

with worksheet as (
    select problem = cast(sum(iif(s.symbol in ('+', '*'), 1, 0)) over(order by c.[value], r.ordinal desc) as smallint)
        ,operator = last_value(iif(s.symbol in ('+', '*'), s.symbol, null)) ignore nulls over(order by c.[value])
        ,[row] = cast(r.ordinal as tinyint)
        ,[column] = c.[value]
        ,symbol = cast(s.symbol as char(1))
    from string_split(@input, nchar(10), 1) r
    cross apply generate_series(cast(1 as smallint), cast(len(r.[value]) as smallint)) c
    cross apply (values(nullif(substring(r.[value], c.[value], 1), N' '))) s(symbol)
    where s.symbol is not null
)
,problems as (
    select part, problem, operator, number = cast(trim(string_agg(symbol, '') within group (order by [order])) as bigint)
    from worksheet
    cross apply (values(1, [column], [row]),(2, [row], [column])) _(part, [order], [group])
    where symbol not in ('+', '*')
    group by part, problem, operator, [group]
)
,answers as (
    select part, answer = iif(operator = '+', sum(number), product(number))
    from problems
    group by part, problem, operator
)

select part, answer = sum(answer)
from answers
group by part;
