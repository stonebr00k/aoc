declare @input nvarchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2021/10.input', single_clob) d);
declare @json nvarchar(max) = N'["' + replace(trim(nchar(10) from @input), nchar(10), N'","') + N'"]';

with line as (
    select id = cast([key] as tinyint)
        ,string = cast([value] as varchar(200))
    from openjson(@json)
)
,reducer as (
    select i = 1, id, string
    from line
    union all
    select i = i + 1, id, cast(replace(replace(replace(replace(string,'()',''),'<>',''),'[]',''),'{}','') as varchar(200))
    from reducer
    where charindex('[]', string) | charindex('{}', string) | charindex('()', string) | charindex('<>', string) > 0
)
,reduced as (
    select top 1 with ties id
        ,illegal_char = x.chr
        ,reverse_string = iif(x.chr is null, rev, null)
    from reducer
    cross apply (values(
        nullif(substring(string, patindex(N'%[})>¤]%', replace(string, N']', N'¤')), 1), N''),
        reverse(replace(replace(replace(replace(string,'(',')'),'[',']'),'{','}'),'<','>'))
    )) x(chr, rev)
    order by row_number() over(partition by id order by i desc)
)
,completion as (
    select id = r.id, i = i.i, points = val
    from reduced r
    cross apply (
        select top (isnull(len(r.reverse_string),0)) i = row_number() over(order by (select null))
        from (values(1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) a(i)
        cross join (values(1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) b(i)
    ) i
    cross apply (values(cast(substring(r.reverse_string,i.i,1) as char(1)))) x(chr)
    join (values(')',1),(']',2),('}',3),('>',4)) points(chr,val)
        on x.chr = points.chr
)
,points_calculator as (
    select id
        ,i
        ,points = cast(points as bigint)
    from completion
    where i = 1
    union all
    select c.id
        ,cmp.i
        ,c.points * 5 + cmp.points
    from points_calculator c
    join completion cmp
        on c.id = cmp.id
        and c.i = cmp.i - 1
)
,total_points as (
    select top 1 with ties id, points
    from points_calculator
    order by row_number() over(partition by id order by i desc)
)

select part_1 = (
        select sum(x.points)
        from reduced r
        left join (values(')',3),(']',57),('}',1197),('>',25137)) x(chr,points)
            on r.illegal_char = x.chr
    )
    ,part_2 = (
        select points
        from (
            select point_id = row_number() over(order by points)
                ,middle = count(*) over() / 2 + 1
                ,points
            from total_points
        ) x
        where point_id = middle
    );
