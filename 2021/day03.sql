-- Part 1
declare @input nvarchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2021/03.input', single_clob) d);
declare @input_json nvarchar(max) = N'["' + replace(replace(replace(@input, nchar(13) + nchar(10), N'","'), nchar(10), N'","'), nchar(13), N'","') + N'"]';

with bits as (
    select pos = pos.n
        ,gamma_bit = cast(iif(sum(x.[bit]) > count(x.[bit]) / 2, 1, 0) as bit)
    from openjson(@input_json) i
    cross join (values(0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11)) pos(n)
    cross apply (
        select [bit] = cast(left(right(reverse(i.[value]), 12 - pos.n),1) as tinyint)
    ) x
    group by pos.n
)

select part_1 = sum(gamma_bit * power(2, pos)) * sum(~gamma_bit * power(2, pos))
from bits;
go

-- Part 2
create or alter function dbo.bit_string_to_int (
    @bit_str varchar(16)
)
returns table
as return (
    select [value] = sum(x.[bit] * power(2, pos.n))
    from (values(0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15)) pos(n)
    cross apply (
        select [bit] = cast(left(right(reverse(right('0000000000000000' + @bit_str, 16)), 16 - pos.n),1) as bit)
    ) x
);
go

create or alter function dbo.reduce_by_position (
    @json nvarchar(max),
    @bit_pos tinyint,
    @of tinyint,
    @find_most_common bit
)
returns table
as return(
    with most_common as (
        select [value] = iif(sum(iif([value] & [bit] = 0, 0, 1)) >= cast(count(*) as decimal(5,1)) / 2 , @find_most_common, ~@find_most_common) * max(x.[bit])
            ,[bit] = max(x.[bit])
        from openjson(@json) with ([value] int N'$.value')
        cross apply (values(power(2, @of - @bit_pos))) x([bit])
    )

    select [value] = (
        select j.[value]
        from openjson(@json) with ([value] int N'$.value') j
        cross join most_common c
        where j.[value] & c.[bit] = c.[value]
        for json path
    )
);
go

--declare @input_json nvarchar(max) = N'["00100","11110","10110","10111","10101","01111","00111","11100","10000","11001","00010","01010"]';
declare @input nvarchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2021/03.input', single_clob) d);
declare @input_json nvarchar(max) = N'["' + replace(replace(replace(@input, nchar(13) + nchar(10), N'","'), nchar(10), N'","'), nchar(13), N'","') + N'"]';

with dec_vals as (
    select [values] = (
        select [value] = d.[value]
        from openjson(@input_json) i
        cross apply dbo.bit_string_to_int(i.[value]) d
        for json path
    )
)
,oxygen as (
    select [bit] = 1
        ,[reduced] = r.[value]
    from dec_vals dv
    cross apply dbo.reduce_by_position(dv.[values], 1, 12, 1) r
    union all
    select [bit] = i.[bit] + 1
        ,[reduced] = r.[value]
    from oxygen i
    cross apply dbo.reduce_by_position(i.reduced, i.[bit] + 1, 12, 1) r
    where json_query(i.reduced, N'$[1]') is not null
)
,co2 as (
    select [bit] = 1
        ,[reduced] = r.[value]
    from dec_vals dv
    cross apply dbo.reduce_by_position(dv.[values], 1, 12, 0) r
    union all
    select [bit] = i.[bit] + 1
        ,[reduced] = r.[value]
    from co2 i
    cross apply dbo.reduce_by_position(i.reduced, i.[bit] + 1, 12, 0) r
    where json_query(i.reduced, N'$[1]') is not null
)

select part_2 = cast(json_value(o.reduced, N'$[0].value') as int) * cast(json_value(c.reduced, N'$[0].value') as int)
from oxygen o 
cross join co2 c
where json_query(o.reduced, N'$[1]') is null
    and json_query(c.reduced, N'$[1]') is null;
go
