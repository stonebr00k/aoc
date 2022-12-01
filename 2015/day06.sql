declare @input varchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2015/06.input', single_clob) d);
set @input = replace(replace(trim(char(10) from @input), replicate(char(13) + char(10), 2), char(16)), char(13) + char(10), char(17));

drop table if exists #grid_o_lights;
drop table if exists #instructions;

declare @input_json varchar(max) = '[[' 
    + replace(replace(replace(replace(replace(@input,
        char(10), '],['),
        'turn off ', '0,'),
        'turn on ', '1,'),
        'toggle ', '2,'),
        ' through ', ',')
    + ']]';
    
select id = cast([key] as smallint) + 1
    ,[action] = cast(json_value([value], '$[0]') as tinyint)
    ,x1 = cast(json_value([value], '$[1]') as smallint)
    ,y1 = cast(json_value([value], '$[2]') as smallint)
    ,x2 = cast(json_value([value], '$[3]') as smallint)
    ,y2 = cast(json_value([value], '$[4]') as smallint)
into #instructions
from openjson(@input_json);

create unique clustered index ucix_#instructions on #instructions (id);

select x = cast(x.[value] as smallint)
    ,y = cast(y.[value] as smallint)
    ,is_on = cast(0 as bit)
    ,brightness = cast(0 as smallint)
into #grid_o_lights
from generate_series(0, 999) x
cross join generate_series(0, 999) y;

create unique clustered index ucix_#grid_o_lights on #grid_o_lights (x, y);

declare @instruction_id smallint = 1;
declare @no_of_instructions smallint = (select max(id) from #instructions);

while @instruction_id <= @no_of_instructions begin;
    update g set 
        is_on = iif(i.[action] = 2, ~g.is_on, cast(i.[action] as bit)),
        brightness = brightness + iif(i.[action] = 0, iif(brightness = 0, 0, -1), i.[action])
    from #grid_o_lights g
    join #instructions i
        on i.id = @instruction_id
        and g.x between i.x1 and i.x2
        and g.y between i.y1 and i.y2;

    set @instruction_id += 1;
end;

select part1 = sum(cast(is_on as int))
    ,part2 = sum(brightness)
from #grid_o_lights;
go