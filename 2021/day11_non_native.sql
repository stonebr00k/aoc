-- SETUP
/*
    if not exists (select * from sys.filegroups where [name] = N'memop') begin;
        alter database current add filegroup [memop] contains memory_optimized_data;
    end;
    if not exists (select * from sys.database_files where [name] = N'memop01') begin;
        declare @file_path nvarchar(4000) = cast(serverproperty('instancedefaultdatapath') as nvarchar(4000)) + db_name() + N'_memop01.ndf';
        declare @cmd nvarchar(4000) = N'alter database current add file (name = [memop01], filename = ''' + @file_path + ''') to filegroup [memop];'
        exec(@cmd);
    end;
*/

drop procedure if exists dbo.solve;
drop type if exists dbo.flashing_octopus;
drop table if exists dbo.octopi;
go

create table dbo.octopi (
    id tinyint not null,
    xpos tinyint not null,
    ypos tinyint not null,
    energy tinyint not null,
    constraint pk_octopi primary key nonclustered (id),
    index hix_octopi_pos unique hash (xpos,ypos,energy) with (bucket_count = 100),
    index ncix_octopi_energy unique hash (energy,xpos,ypos) with (bucket_count = 100),
) with (memory_optimized = on, durability = schema_only);
go

create type dbo.flashing_octopus as table (
    xpos tinyint not null,
    ypos tinyint not null,
    is_new bit not null default 1,
    index hix_octopus unique hash (xpos,ypos,is_new) with(bucket_count = 100)
) with (memory_optimized = on); 
go

create or alter procedure dbo.solve
as begin;
    set nocount on;
    declare @cnt smallint = 0;
    declare @step_flashes tinyint = 0;
    declare @total_flashes smallint = 0;
    declare @flashing_octopi dbo.flashing_octopus;
    declare @all_flash_step_count smallint;

    while @cnt < 100 or @all_flash_step_count is null begin;
        update dbo.octopi set energy = energy + 1;

        insert into @flashing_octopi (xpos, ypos)
        select xpos, ypos from dbo.octopi where energy = 10;
        
        while @@rowcount > 0 begin;
            with cte as (
                select o.xpos, o.ypos, increase = count(*)
                from @flashing_octopi fo
                join dbo.octopi o
                    on o.xpos between fo.xpos - 1 and fo.xpos + 1
                    and o.ypos between fo.ypos - 1 and fo.ypos + 1
                where fo.is_new = 1
                group by o.xpos, o.ypos
            )
            update o set energy += increase
            from dbo.octopi o
            join cte c 
                on o.xpos = c.xpos
                and o.ypos = c.ypos;

            update @flashing_octopi set is_new = 0;

            insert into @flashing_octopi (xpos, ypos)
                select xpos, ypos from dbo.octopi where energy > 9
                except 
                select xpos, ypos from @flashing_octopi;
        end;
        
        update o set energy = 0
        from dbo.octopi o
        join @flashing_octopi fo
            on o.xpos = fo.xpos
            and o.ypos = fo.ypos;

        set @step_flashes = @@rowcount;
        set @total_flashes += iif(@cnt < 100, @step_flashes, 0);
        
        set @cnt += 1;
        set @all_flash_step_count = isnull(@all_flash_step_count, iif(@step_flashes = 100, @cnt, null))
        delete @flashing_octopi;
    end;

    select part_1 = @total_flashes
        ,part_2 = @all_flash_step_count;
end;
go

declare @input nvarchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2021/11.input', single_clob) d);
declare @json nvarchar(max) = N'["' + replace(trim(nchar(10) from @input), nchar(10), N'","') + N'"]';

insert into dbo.octopi (id, xpos, ypos, energy)
    select id = row_number() over(order by cast([key] as tinyint), x.pos)
        ,xpos = cast(x.pos as tinyint)
        ,ypos = cast([key] as tinyint)
        ,energy = cast(substring(l.[value], x.pos + 1, 1) as tinyint)
    from openjson(@json) l
    cross apply(values(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) x(pos);
    
exec dbo.solve;
