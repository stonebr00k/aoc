declare @input nvarchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2021/13.input', single_clob) d);
declare @json nvarchar(max) = N'["' + replace(trim(nchar(10) from @input), nchar(10), N'","') + N'"]';

drop table if exists #paper;
create table #paper (fold smallint not null, x smallint not null, y smallint not null, primary key (fold, x, y));

insert into #paper(fold, x, y)
    select fold = 0 
        ,x = cast(substring([value], 1, charindex(N',', [value]) - 1) as smallint)
        ,y = cast(substring([value], charindex(N',', [value]) + 1, len([value])) as smallint)
    from openjson(@json)
    where [value] like N'[0-9]%';
    
declare @fold_count tinyint = 0;
declare @is_horizontal bit;
declare @fold_at smallint;

declare fold cursor fast_forward for
    select is_horizontal = cast(iif(left(replace([value], N'fold along ', N''), 1) = N'y', 1, 0) as bit)
        ,[at] = cast(replace(replace(replace([value], N'fold along ', N''), N'x=',N''), N'y=', N'') as smallint)
    from openjson(@json)
    where [value] like N'fold%'
    order by cast([key] as smallint);

open fold;
fetch next from fold into @is_horizontal, @fold_at;

while @@fetch_status = 0 begin;
    set @fold_count += 1;

    insert into #paper (fold, x, y)
        select fold = @fold_count
            ,x = isnull(folded.x, p2.x)
            ,y = isnull(folded.y, p2.y)
        from #paper p1
        cross apply (values(
            iif(@is_horizontal = 1, p1.x, @fold_at * 2 - x),
            iif(@is_horizontal = 0, p1.y, @fold_at * 2 - y)
        )) folded(x, y)
        full join #paper p2
            on folded.x = p2.x
            and folded.y = p2.y
            and p1.fold = p2.fold
        where isnull(p1.fold, p2.fold) = @fold_count - 1
            and iif(@is_horizontal = 1, isnull(folded.y, p2.y), isnull(folded.x, p2.x)) < @fold_at;

    fetch next from fold into @is_horizontal, @fold_at;
end;

close fold;
deallocate fold;

select part_1 = count(*) from #paper where fold = 1;

with i as (
    select i = row_number() over(order by (select null)) - 1
    from (values(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) i1(i)
    cross join (values(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) i10(i)
    cross join (values(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) i100(i)
)

select part_2 = string_agg(iif(p.x is not null, N'#', N' '), N'') within group(order by ix.i)
from i ix
cross join i iy
left join #paper p
    on ix.i = p.x
    and iy.i = p.y
    and p.fold = @fold_count
where ix.i <= (select max(x) from #paper where fold = @fold_count)
    and iy.i <= (select max(y) from #paper where fold = @fold_count)
group by iy.i
order by iy.i;
