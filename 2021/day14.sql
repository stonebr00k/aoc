declare @input nvarchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2021/14.input', single_clob) d);
declare @json nvarchar(max) = N'["' + replace(trim(nchar(10) from @input), nchar(10), N'","') + N'"]';
declare @polymer_template varchar(32) = json_value(@json, N'$[0]');
declare @pair_replacement table (pair char(2), repl char(2), primary key (pair, repl));
declare @pair_count table (iteration tinyint not null, pair char(2) not null, cnt bigint not null, primary key (iteration, pair));

insert into @pair_replacement (pair, repl)
    select pair = left([value], 2)
        ,repl = right([value], i) + left([value], ~i) + right(left([value], 2), i) + right([value], ~i)
    from openjson(@json) pir
    cross join (values(cast(0 as bit)),(cast(1 as bit))) x(i)
    where cast([key] as tinyint) > 1;

insert into @pair_count (iteration, pair, cnt)
    select iteration = 0 
        ,pair = cast(substring(@polymer_template, i.i, 2) as char(2))
        ,cnt = count(*)
    from (values(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) i1(i)
    cross join (values(0),(1),(2)) i10(i)
    cross apply (values(i10.i * 10 + i1.i)) i(i)
    where i.i between 1 and len(@polymer_template)
    group by substring(@polymer_template, i.i, 2);

declare @iteration tinyint = 1;
while @iteration <= 40 begin;    
    insert into @pair_count (iteration, pair, cnt)
        select iteration = @iteration
            ,pair = pr.repl
            ,cnt = sum(pc.cnt)
        from @pair_count pc
        join @pair_replacement pr
            on pc.pair = pr.pair
        where pc.iteration = @iteration - 1
        group by pr.repl;

    set @iteration += 1;
end;

with char_count as (
    select iteration 
        ,chr
        ,cnt = sum(cnt) / 2 + iif(chr in (left(@polymer_template, 1), right(@polymer_template, 1)), 1, 0)
    from @pair_count pc
    cross join (values(cast(0 as bit)),(cast(1 as bit))) x(i)
    cross apply (values(left(pc.pair, i) + right(pc.pair, ~i))) c(chr)
    where pc.iteration in (10,40)
    group by chr, iteration
)
select part_1 = max(iif(iteration = 10, cnt, null)) - min(iif(iteration = 10, cnt, null))
    ,part_2 = max(iif(iteration = 40, cnt, null)) - min(iif(iteration = 40, cnt, null))
from char_count;
go
