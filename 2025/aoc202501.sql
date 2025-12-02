/*  AoC 2025-01 (https://adventofcode.com/2025/day/1)  */
declare @input nvarchar(max) = replace((select BulkColumn from openrowset(bulk 'C:/repo/stonebr00k/aoc/input/2025/01', single_clob)_), nchar(13), '');
set @input = concat(N'.50', nchar(10), @input); -- Add starting point

with rotator as (
    select ended_at_zero = iif(pos = 0, 1, 0)
        ,passed_zero = full_rotations + iif(pos > 0 and not clicks + pos between 0 and 100, 1, 0)
    from (
        select id = i.ordinal
            ,full_rotations = abs(lead(clicks) over(order by ordinal) / 100)
            ,clicks = lead(clicks) over(order by ordinal) % 100
            ,pos = sum(clicks) over(order by ordinal) % 100 + iif(sum(clicks) over(order by ordinal) % 100 < 0, 100, 0)
        from string_split(@input, nchar(10), 1) i
        cross apply (
            select clicks = iif(left([value], 1) = N'R', 1, -1) * right([value], len([value]) - 1)
        ) _
    ) _
)

select part1 = sum(ended_at_zero)
    ,part2 = sum(ended_at_zero + passed_zero)
from rotator;
