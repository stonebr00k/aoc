declare @input varchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2015/07.input', single_clob) d);
set @input = '[[["' + replace(replace(replace(trim(char(10) from @input), ' -> ', '"],"'), char(10), N'"],[["'), ' ','","') + '"]]]';
declare @part tinyint = 1, @rowcount int;

select w
    ,op = cast(iif(a = 'NOT', 'N', isnull(left(b, 1), N'>')) as char(1))
    ,i1 = iif(a = 'NOT', b, a)
    ,i2 = c
    ,v = cast(null as int)
into #circuit
from openjson(@input) with (w varchar(2) '$[1]', a varchar(8) '$[0][0]', b varchar(8) '$[0][1]', c varchar(8) '$[0][2]');

while @part <= 2 begin;
    set @rowcount = 1;
    while @rowcount > 0 begin;
        update c set v = x.val
        from #circuit c
        left join #circuit i1v on c.i1 = i1v.w
        left join #circuit i2v on c.i2 = i2v.w
        cross apply (values(isnull(try_cast(c.i1 as int), i1v.v),isnull(try_cast(c.i2 as int), i2v.v))) v(i1, i2)
        cross apply (values('>', v.i1),('N', ~v.i1),('A', v.i1 & v.i2),('O', v.i1 | v.i2),('R', v.i1 >> v.i2),('L', v.i1 << v.i2)) x(op, val)
        where c.v is null
            and v.i1 is not null 
            and (c.i2 is null or v.i2 is not null)
            and c.op = x.op;

        set @rowcount = @@rowcount;
    end;
    
    if @part = 1 update #circuit set i1 = iif(w = 'b', cast((select v from #circuit where w = 'a') as varchar(8)), i1), v = null;
    set @part += 1;
end;

select part1 = (select v from #circuit where w = 'b')
    ,part2 = (select v from #circuit where w = 'a');
