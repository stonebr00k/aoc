/*  AoC 2023-01 (https://adventofcode.com/2023/day/1)  */
declare @ varchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2023/01', single_clob)_);

with calibration_values as (
    select top 1 with ties part = part.val
        ,[value] = dir.multiplier * [match].digit
    from string_split(@, nchar(10), 1) ss
    cross join (values
        (1, 1, '1'),(1, 2, '2'),(1, 3, '3'),(1, 4, '4'),(1, 5, '5'),(1, 6, '6'),(1, 7, '7'),(1, 8, '8'),(1, 9, '9'),
        (2, 1, 'one'),(2, 2, 'two'),(2, 3, 'three'),(2, 4, 'four'),(2, 5, 'five'),(2, 6, 'six'),(2, 7, 'seven'),(2, 8, 'eight'),(2, 9, 'nine')
    ) [match](part, digit, digit_str)
    join (values(1),(2)) part(val) 
        on part.val = 2 or [match].part = part.val
    cross apply (values
        (10, [match].digit_str, ss.[value]),
        (1, reverse([match].digit_str), reverse(ss.[value]))
    ) dir(multiplier, digit_str, string)
    cross apply (values(patindex(concat('%', dir.digit_str, '%'), dir.string))) pat(idx)
    where pat.idx > 0
    order by row_number() over(partition by ss.ordinal, part.val, dir.multiplier order by pat.idx)
)

select part, answer = sum([value])
from calibration_values 
group by part;
go
