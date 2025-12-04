/*  AoC 2025-04 (https://adventofcode.com/2025/day/4)  */
declare @input nvarchar(max) = replace((select BulkColumn from openrowset(bulk 'C:/repo/stonebr00k/aoc/input/2025/04', single_clob)_), nchar(13), N'');
declare @removed int = 1, @part1 int, @part2 int = 0;

drop table if exists #rolls;
create table #rolls ([row] int not null, col int not null, primary key ([row], col));

insert into #rolls ([row], col)
    select r.ordinal, c.[value]
    from string_split(trim(nchar(10) from @input), nchar(10), 1) r
    cross apply generate_series(1, cast(len(r.[value]) as int)) c
    where substring(r.[value], c.[value], 1) = N'@';

while @removed > 0 begin;
    delete r
    from #rolls r
    where exists (
        select *
        from #rolls
        cross join (values(-1, 0),(-1, 1),(0, 1),(1, 1),(1, 0),(1, -1),(0, -1),(-1, -1)) [mod](r, c)
        where [row] = r.[row] + [mod].r
            and col = r.col + [mod].c
        having count(*) < 4
    );
    select @removed = @@rowcount, @part1 = isnull(@part1, @@rowcount), @part2 += @@rowcount;
end;

select part_1 = @part1
    ,part_2 = @part2;
