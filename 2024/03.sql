/*  AoC 2024-03 (https://adventofcode.com/2024/day/3)  */
declare @input nvarchar(max) = replace((select BulkColumn from openrowset(bulk 'C:/repo/stonebr00k/aoc/input/2024/03', single_clob)_), nchar(13), '');

select part_1 = sum(x.t1 * x.t2)
from string_split(replace(@input, N'mul(', char(17)), char(17)) mul
cross apply(select instr = substring(mul.[value], 1, charindex(N')', mul.[value]) - 1) where charindex(N')', mul.[value]) between 4 and 8) s
cross apply(values(
    try_cast(left(s.instr, charindex(N',', s.instr) - 1) as int),
    try_cast(right(s.instr, charindex(N',', reverse(s.instr)) - 1) as int)
)) x(t1, t2)
where charindex(N',', s.instr) between 2 and 4
    and x.t1 is not null and x.t2 is not null;

select part_2 = sum(x.t1 * x.t2)
from string_split(replace(@input, N'do()', char(17)), char(17)) d
cross apply(values(substring(d.[value], 1, isnull(nullif(charindex(N'don''t()', d.[value]), 0), len(d.[value]))))) do([str])
cross apply string_split(replace(do.[str], N'mul(', char(17)), char(17)) mul
cross apply(select instr = substring(mul.[value], 1, charindex(N')', mul.[value]) - 1) where charindex(N')', mul.[value]) between 4 and 8) s
cross apply(values(
    try_cast(left(s.instr, charindex(N',', s.instr) - 1) as int),
    try_cast(right(s.instr, charindex(N',', reverse(s.instr)) - 1) as int)
)) x(t1, t2)
where charindex(N',', s.instr) between 2 and 4
    and x.t1 is not null and x.t2 is not null;
go
