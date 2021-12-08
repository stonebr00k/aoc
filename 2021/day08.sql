declare @input nvarchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2021/08.input', single_clob) d);
declare @json nvarchar(max) = N'[["' + replace(replace(replace(trim(nchar(10) from @input), N' | ', N'","'), nchar(10), N'"],["'), N' ',N'","') + N'"]]';

with chr_bit_map as (
    select chr = cast(chr as char(1))
        ,[bit] = cast([bit] as tinyint)
    from (values('a', 1),('b', 2),('c', 4),('d', 8),('e', 16),('f', 32),('g', 64)) x(chr, [bit])
)
,input as (
    select entry_id = cast(e.[key] as tinyint)
        ,[int] = cast(sum(m.[bit]) as tinyint)
        ,[len] = cast(len(s.[value]) as tinyint)
        ,val_id = cast(s.[key] as tinyint)
        ,is_output = iif(cast(s.[key] as tinyint) > 9, 1, 0)
    from openjson(@json) e
    cross apply openjson(e.[value]) s
    join chr_bit_map m
        on charindex(m.chr, s.[value]) > 0
    group by e.[key]
        ,s.[key]
        ,s.[value]
)
,[output] as (
    select entry_id
        ,[int] = [int]
        ,[mod] = cast('1' + replicate('0', row_number() over(partition by entry_id order by val_id desc) - 1) as smallint)
    from input
    where is_output = 1
)
,signal_pattern as (
    select entry_id 
        ,[len]
        ,[int]
        ,b1 = sum(iif([len] = 2, [int], null)) over(partition by entry_id)
        ,b4 = sum(iif([len] = 4, [int], null)) over(partition by entry_id)
        ,b7 = sum(iif([len] = 3, [int], null)) over(partition by entry_id)
        ,b8 = sum(iif([len] = 7, [int], null)) over(partition by entry_id)
    from input
    where is_output = 0
)
,deducer as (
    select entry_id
        ,[int]
        ,[value] = case [len] 
            when 2 then 1
            when 3 then 7
            when 4 then 4
            when 5 then case
                when [int] & b1 = b1 then 3
                when sum(iif([len] = 6 and [int] & b4 = b4, [int], null)) over(partition by entry_id) & [int] = [int] then 5
                else 2
                end
            when 6 then case
                when [int] & b1 != b1 then 6
                when [int] & b4 = b4 then 9
                else 0
                end
            when 7 then 8
            end
    from signal_pattern
)

select part_1 = sum(iif([value] in (1, 4, 7, 8), 1, null)) 
    ,part_2 = sum(o.[mod] * [value])
from deducer d
join [output] o
    on d.entry_id = o.entry_id
    and d.[int] = o.[int];
