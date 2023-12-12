/*  AoC 2023-06 (https://adventofcode.com/2023/day/6)  */
declare @ varchar(max) = replace((select BulkColumn from openrowset(bulk 'c:/temp/aoc/2023/06', single_clob)_), char(13), '');

with races as (
    select race
        ,t = max(iif(ordinal = 1, cast(substring([value], s.pos, 7) as smallint), null))
        ,d = max(iif(ordinal = 2, cast(substring([value], s.pos, 7) as smallint), null))
    from string_split(@, char(10), 1)
    cross join (values(1, 9), (2, 15), (3, 22), (4, 29)) s(race, pos)
    group by race
)
,big_race as (
    select t = cast(string_agg(t, N'') within group (order by race) as bigint)
        ,d = cast(string_agg(d, N'') within group (order by race) as bigint)
    from races
)

select part1 = ( -- The brute force approach
        select exp(sum(log(cnt)))
        from (
            select cnt = count(*)
            from races
            cross apply generate_series(1, t - 1)
            where [value] * (t - [value]) > d
            group by race
        ) _
    )
    ,part2 = ( -- The more elegant approach :)
        select floor(t/2 + sqrt(power(t/2, 2) - d)) - ceiling(t/2 - sqrt(power(t/2, 2) - d)) + 1
        from big_race
    );
go
