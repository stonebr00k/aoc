/*  AoC 2025-02 (https://adventofcode.com/2025/day/2)  */
declare @input nvarchar(max) = replace((select BulkColumn from openrowset(bulk 'C:/repo/stonebr00k/aoc/input/2025/02', single_clob)_), nchar(13), N'');
set @input = concat(N'[[', replace(replace(@input, N',', N'],['), N'-', N','), N']]');

select part1 = sum(distinct iif(div = 2, id.val, 0))
    ,part2 = sum(distinct id.val)
from openjson(@input) with ([lower] nvarchar(16) N'$[0]', [upper] nvarchar(16) N'$[1]') [str]
cross apply generate_series(2, len([str].[upper])) div
cross apply (
    select div = div.[value]
        ,int_lower = cast([str].[lower] as bigint)
        ,int_upper = cast([str].[upper] as bigint)
        ,lower_remainder = len([str].[lower]) % div.[value]
        ,upper_remainder = len([str].[upper]) % div.[value]
        ,lower_part = cast(left([str].[lower], len([str].[lower]) / div.[value]) as bigint)
        ,upper_part = left([str].[upper], len([str].[upper]) / div.[value])
) _
cross apply (
    select [lower] = cast(iif(lower_remainder = 0,
            lower_part + iif(replicate(lower_part, div) < int_lower, 1, 0),
            concat(1, replicate(0, (len([str].[lower]) + (div - upper_remainder)) / div - 1))
        ) as bigint)
        ,[upper] = cast(iif(upper_remainder = 0,
            upper_part - iif(replicate(upper_part, div) > int_upper, 1, 0),
            replicate(9, (len([str].[upper]) - upper_remainder) / div)
        ) as bigint)
) bound
cross apply generate_series(bound.[lower], bound.[upper]) s
cross apply (values(cast(replicate(s.[value], div) as bigint))) id(val)
where id.val between int_lower and int_upper;
