/*  AoC 2022-04 (https://adventofcode.com/2022/day/4)  */
declare @input varchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/04.input', single_clob) d);
set @input = '[[' + replace(replace(@input, '-', ','), char(10), '],[') + ']]';

select part1 = sum(iif(a1 >= b1 and a2 <= b2 or b1 >= a1 and b2 <= a2, 1, 0))
    ,part2 = sum(iif(a1 <= b2 and b1 <= a2, 1, 0))
from openjson(@input) with (a1 int '$[0]', a2 int '$[1]', b1 int '$[2]', b2 int '$[3]');
