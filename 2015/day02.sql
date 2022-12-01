declare @input varchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2015/02.input', single_clob) d);
set @input = replace(replace(@input, replicate(char(13) + char(10), 2), char(16)), char(13) + char(10), char(17));

select part1 = sum(2*l*w + 2*w*h + 2*h*l + least(l*w, w*h, h*l))
    ,part2 = sum(least(2*l+2*w, 2*w+2*h, 2*h+2*l) + (l*w*h))
from openjson(N'[[' + replace(replace(@input,N'x',N','), char(10), N'],[') + N']]') with (
    l smallint N'$[0]',
    w smallint N'$[1]',
    h smallint N'$[2]'
) box;
go
