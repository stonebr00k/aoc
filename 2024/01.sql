/*  AoC 2024-01 (https://adventofcode.com/2024/day/1)  */
declare @input nvarchar(max) = replace((select BulkColumn from openrowset(bulk 'C:/repo/stonebr00k/aoc/input/2024/01', single_clob)_), nchar(13), '');
declare @lists_json nvarchar(max) = concat(N'[[', replace(replace(@input, N'   ', N','), nchar(10), N'],[') ,N']]');

-- Part 1
select part1 = sum(abs(left_list.location_id - right_list.location_id))
from (
    select idx = row_number() over(order by location_id)
        ,location_id
    from openjson(@lists_json) with(location_id int N'$[0]')
) left_list
join (
    select idx = row_number() over(order by location_id)
        ,location_id
    from openjson(@lists_json) with(location_id int N'$[1]')
) right_list
    on left_list.idx = right_list.idx;

-- Part 2
select part2 = sum(right_list.location_id)
from openjson(@lists_json) with(location_id int N'$[0]') left_list
join openjson(@lists_json) with(location_id int N'$[1]') right_list
    on left_list.location_id = right_list.location_id;
go
