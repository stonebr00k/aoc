/*  AoC 2025-05 (https://adventofcode.com/2025/day/5)  */
declare @input nvarchar(max) = replace((select BulkColumn from openrowset(bulk 'C:\repo\stonebr00k\aoc\input\2025\05', single_clob)_), nchar(13), N'');
declare @input_json nvarchar(max) = concat(N'[[[', replace(replace(replace(trim(nchar(10) from @input), N'-', N','), replicate(nchar(10), 2), N']],[['), nchar(10), N'],['), N']]]');

select part_1 = (
        select count(*)
        from openjson(@input_json, N'$[1]') with (id bigint N'$[0]') i
        where exists (
            select *
            from openjson(@input_json, N'$[0]') with (l bigint N'$[0]', u bigint N'$[1]') r
            where i.id between r.l and r.u
        )
    )
    ,part_2 = (
        select sum([upper] - [lower] + 1)
        from (
            select [lower] = greatest(max(u) over(order by l rows between unbounded preceding and 1 preceding) + 1, l)
                ,[upper] = greatest(max(u) over(order by l rows between unbounded preceding and 1 preceding), u)
            from openjson(@input_json, N'$[0]') with (l bigint N'$[0]', u bigint N'$[1]')
        ) bounds
    );
