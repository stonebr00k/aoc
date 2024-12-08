/*  AoC 2024-07 (https://adventofcode.com/2024/day/7)  */
go
create or alter function evaluate (@test_value bigint, @numbers nvarchar(128), @concat bit)
returns table as return (
    with evaluator as (
        select i = (select count(*) from openjson(@numbers)), r = @test_value
        union all
        select i = e.i-1, r = r.v
        from evaluator e
        cross apply (values(cast(json_value(@numbers, '$'+quotename(e.i-1)) as bigint))) n(v)
        cross apply (values
            (iif(e.r<n.v, -1, e.r-n.v)),
            (iif(e.r%n.v = 0, e.r/n.v, -1)),
            (iif(@concat = 1 and len(e.r)>len(n.v) and right(e.r, len(n.v)) = n.v, cast(left(e.r, len(e.r)-len(n.v)) as bigint), -1))
        ) r(v)
        where e.i > 1 and r.v > -1
    )

    select top 1 is_true = cast(1 as bit)
    from evaluator
    where i = 1 and r = cast(json_value(@numbers, N'$[0]') as bigint)
);
go

declare @input varchar(max) = replace((select BulkColumn from openrowset(bulk 'C:/repo/stonebr00k/aoc/input/2024/07', single_clob)_), nchar(13), '');

with equations as (
    select test_value = cast(left([value], charindex(':', [value]) - 1) as bigint)
        ,numbers = quotename(replace(right([value], charindex(':', reverse([value]))-2), ' ', ','))
    from string_split(@input, char(10), 1) s
)

select part_1 = (select sum(test_value) from equations cross apply evaluate(test_value, numbers, 0))
    ,part_2 = (select sum(test_value) from equations cross apply evaluate(test_value, numbers, 1));

drop function if exists evaluate;
go
