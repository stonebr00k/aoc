declare @input nvarchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/01.input', single_clob) d);

-- Transform list to json
with list as (
    select [value] = N'[['
        + replace(replace(@input,
            replicate(nchar(13) + nchar(10), 2), N'],['),
            nchar(13) + nchar(10), N',') 
        + N']]'
)
-- Get top 3 elves by calories carried
,top_3_calorie_carriers as (
    select top 3 calories_carried = sum(cast(food_item.[value] as int))
    from list l
    cross apply openjson(l.[value]) elf
    cross apply openjson(elf.[value]) food_item
    group by elf.[key]
    order by sum(cast(food_item.[value] as int)) desc
)

-- Get max and sum of those 3
select part1 = max(calories_carried)
    ,part2 = sum(calories_carried)
from top_3_calorie_carriers;
go
