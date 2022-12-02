declare @input varchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/02.input', single_clob) d);
set @input = '[["' + replace(replace(@input, char(10), '"],["'), ' ', '","') + '"]]'; -- transform into json

select part1 = sum(isnull(choose(a.me - a.elf + 3, 6, 0, 3, 6), 0) + a.me)
    ,part2 = sum(choose(a.me, choose(a.elf, 3, 1, 2), a.elf, choose(a.elf, 2, 3, 1)) + choose(a.me, 0, 3, 6))
from openjson(@input) with (elf char(1) '$[0]', me char(1) '$[1]') g
cross apply (select elf = ascii(g.elf) - 64, me = ascii(g.me) - 87) a;
go
