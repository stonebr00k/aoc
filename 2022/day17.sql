/*  AoC 2022-17 (https://adventofcode.com/2022/day/17)  */
/* 
Setup to enable the use of memory optimized tables and natively compiled functions/procedures.
If on SQL Server 2022 before CU1, you will probably need to enable trace flag 12324 at server startup.

    if not exists (select * from sys.filegroups where [name] = N'memop') begin;
        alter database current add filegroup [memop] contains memory_optimized_data;
    end;
    if not exists (select * from sys.database_files where [name] = N'memop01') begin;
        declare @file_path nvarchar(4000) = cast(serverproperty('instancedefaultdatapath') as nvarchar(4000)) + db_name() + N'_memop01.ndf';
        declare @cmd nvarchar(4000) = N'alter database current add file (name = [memop01], filename = ''' + @file_path + N''') to filegroup [memop];'
        exec(@cmd);
    end;

*/
drop procedure if exists play_tetris;
drop function if exists get_new_rock;
drop type if exists rock; drop type if exists tower; drop type if exists cache;

create type rock as table (x tinyint not null, y bigint not null, index hix hash (x, y) with(bucket_count = 5)) with(memory_optimized = on);
create type tower as table (x tinyint not null, y bigint not null, index ncix unique nonclustered (x, y)) with(memory_optimized = on);
create type cache as table ([state] nvarchar(512) not null, rock_count bigint not null, tower_height bigint not null, index ncix unique nonclustered ([state])) with(memory_optimized = on);
go

create or alter function get_new_rock(@type tinyint, @height int)
returns table with native_compilation, schemabinding
as return (
    select x = p.x, y = p.y + @height 
    from (
        select 1,3,4 union all select 1,4,4 union all select 1,5,4 union all select 1,6,4 union all
        select 2,4,6 union all select 2,3,5 union all select 2,4,5 union all select 2,5,5 union all select 2,4,4 union all
        select 3,5,6 union all select 3,5,5 union all select 3,3,4 union all select 3,4,4 union all select 3,5,4 union all
        select 4,3,7 union all select 4,3,6 union all select 4,3,5 union all select 4,3,4 union all
        select 5,3,5 union all select 5,4,5 union all select 5,3,4 union all select 5,4,4
    ) p(t, x, y)
    where t = @type
);
go

create or alter procedure play_tetris (@no_of_rocks bigint, @jet_pattern varchar(max))
with native_compilation, schemabinding
as begin atomic with (transaction isolation level = snapshot, language = N'us_english');
    declare @rock dbo.rock, @tower dbo.tower, @cache dbo.cache;
    declare @rock_count bigint = 0, @jet_no smallint = 0, @jet char(1), @rest bit = 0, @exists bit,
        @tower_height bigint = 0, @rock_type tinyint = 1, @state nvarchar(512), @added_height bigint = 0;

    insert into @tower (x,y) values(1,0);
    insert into @tower (x,y) values(2,0);
    insert into @tower (x,y) values(3,0);
    insert into @tower (x,y) values(4,0);
    insert into @tower (x,y) values(5,0);
    insert into @tower (x,y) values(6,0);
    insert into @tower (x,y) values(7,0);

    while @rock_count < @no_of_rocks begin;
        set @rock_count += 1; set @rest = 0;

        insert into @rock (x,y) select x, y from dbo.get_new_rock(@rock_type, @tower_height);

        if @added_height = 0 begin;
            set @state = cast(@jet_no as nvarchar(13)) + (select top 32 x, y = @tower_height - y from @tower order by y desc for json path);
            set @exists = 0;
            select top 1 @exists = 1 from @cache where [state] = @state;

            if @exists = 0 begin;
                insert into @cache([state], rock_count, tower_height) values(@state, @rock_count, @tower_height);
            end;
            else begin;
                declare @last_rock_count bigint, @last_tower_height bigint, @drc bigint, @dth bigint, @cycles_to_add bigint;

                select @last_rock_count = rock_count, @last_tower_height = tower_height
                from @cache 
                where [state] = @state;

                set @drc = @rock_count - @last_rock_count;
                set @dth = @tower_height - @last_tower_height;
                set @cycles_to_add = floor((@no_of_rocks - @rock_count) / @drc);
                set @rock_count += @cycles_to_add*@drc;
                set @added_height += @cycles_to_add*@dth;

                delete from @cache;
            end;
        end;

        while @rest = 0 begin;
            set @jet_no = iif(@jet_no = len(@jet_pattern), 1, @jet_no + 1);
            set @jet = substring(@jet_pattern, @jet_no, 1);
            set @exists = 0;

            if @jet = '>' begin;
                select top 1 @exists = 1 from @rock r where x = 7 or exists (select 1 from @tower where x = r.x+1 and y = r.y);
                if @exists = 0 update @rock set x = x + 1;
            end;
            else if @jet = '<' begin;
                select top 1 @exists = 1 from @rock r where x = 1 or exists (select 1 from @tower where x = r.x-1 and y = r.y);
                if @exists = 0 update @rock set x = x - 1;
            end;

            set @exists = 0;
            select top 1 @exists = 1 from @tower t join @rock r on t.x = r.x and t.y = r.y-1;

            if @exists = 1 begin;
                set @rest = 1;
                insert into @tower (x, y) select x, y from @rock;
                select @tower_height = max(y) from @tower;

                set @rock_type = iif(@rock_type = 5, 1, @rock_type + 1);
                delete from @rock;
                delete from @tower where y < @tower_height - 100;
            end;
            else begin;
                update @rock set y = y - 1;
            end;
        end;
    end;

    select height = @tower_height + @added_height;
end
go

declare @ varchar(max) = trim(char(10) from (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/17.input', single_clob) d));
exec play_tetris 2022, @; -- part 1
exec play_tetris 1000000000000, @; -- part 2
