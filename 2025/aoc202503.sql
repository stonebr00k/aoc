/*  AoC 2025-03 (https://adventofcode.com/2025/day/3)  */

create or alter function find_highest_joltage_battery (@bank nvarchar(256), @start_pos tinyint, @end_pos tinyint)
returns table as return (
    select top 1 position = s.[value]
        ,joltage = battery.joltage
    from generate_series(@start_pos, @end_pos) s
    cross apply(values(cast(substring(@bank, s.[value], 1) as tinyint))) battery(joltage)
    order by battery.joltage desc, s.[value] asc
);
go

create or alter function get_max_joltage (@bank nvarchar(256), @no_of_batteries tinyint)
returns table as return (
    with calculator as (
        select iteration = 1
            ,battery_position = bt.position
            ,joltage_string = cast(bt.joltage as nvarchar(256))
        from find_highest_joltage_battery(@bank, 1, len(@bank) - @no_of_batteries + 1) bt
        union all
        select iteration = iteration + 1
            ,battery_position = bt.position
            ,joltage_string = cast(concat(c.joltage_string, bt.joltage) as nvarchar(256))
        from calculator c
        cross apply find_highest_joltage_battery(@bank, c.battery_position + 1, len(@bank) - @no_of_batteries + c.iteration + 1) bt
        where c.iteration < @no_of_batteries
    )

    select joltage = cast(joltage_string as bigint)
    from calculator
    where iteration = @no_of_batteries
);
go

declare @input nvarchar(max) = replace((select BulkColumn from openrowset(bulk 'C:/repo/stonebr00k/aoc/input/2025/03', single_clob)_), nchar(13), N'');

with bank as (
    select batteries = cast([value] as nvarchar(256))
    from string_split(trim(nchar(10) from @input), nchar(10))
)
select part = part.number
    ,answer = sum(mj.joltage)
from bank
cross join(values(1, 2), (2, 12)) part(number, no_of_batteries)
cross apply get_max_joltage(bank.batteries, part.no_of_batteries) mj
group by part.number;

drop function if exists get_max_joltage, find_highest_joltage_battery;
