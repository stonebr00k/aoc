declare @input varchar(max) = trim(nchar(10) from (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/05.input', single_clob) d));
set @input = '["' + replace(@input, nchar(10), '","') + '"]';

declare @ins varchar(max) = (
    select '[' + string_agg('[' + replace(replace(replace([value], 'move ', ''), ' from ', ','), ' to ', ',') + ']', ',') + ']'
    from openjson(@input)
    where [value] like 'move%'
);

with rearranger as (
    select i = 0
        ,s1 = cast((
            select c1 = reverse(trim(string_agg(substring([value], 2, 1), '')))
                ,c2 = reverse(trim(string_agg(substring([value], 6, 1), '')))
                ,c3 = reverse(trim(string_agg(substring([value], 10, 1), '')))
                ,c4 = reverse(trim(string_agg(substring([value], 14, 1), '')))
                ,c5 = reverse(trim(string_agg(substring([value], 18, 1), '')))
                ,c6 = reverse(trim(string_agg(substring([value], 22, 1), '')))
                ,c7 = reverse(trim(string_agg(substring([value], 26, 1), '')))
                ,c8 = reverse(trim(string_agg(substring([value], 30, 1), '')))
                ,c9 = reverse(trim(string_agg(substring([value], 34, 1), '')))
            for json path, without_array_wrapper
        ) as varchar(max))
        ,s2 = cast(null as varchar(max))
    from openjson(@input)
    where [value] like '[[]%'
    union all
    select i = r.i + 1
        ,s1 = cast(json_modify(json_modify(r.s1, 
            i.t, st.t1 + reverse(right(st.f1, i.c))), 
            i.f, left(st.f1, len(st.f1) - i.c)) as varchar(max))
        ,s2 = cast(json_modify(json_modify(isnull(r.s2, r.s1), 
            i.t, st.t2 + right(st.f2, i.c)), 
            i.f, left(st.f2, len(st.f2) - i.c)) as varchar(max))
    from rearranger r
    cross apply (values(
        json_value(@ins, '$[' + cast(r.i as varchar(8)) + '][0]'),
        cast('$.c' + cast(json_value(@ins, '$[' + cast(r.i as varchar(8)) + '][1]') as varchar(1)) as varchar(6)),
        cast('$.c' + cast(json_value(@ins, '$[' + cast(r.i as varchar(8)) + '][2]') as varchar(1)) as varchar(6))
    )) i(c, f, t)
    cross apply (values(
        cast(json_value(r.s1, i.f) as varchar(max)),
        cast(json_value(r.s1, i.t) as varchar(max)),
        cast(json_value(isnull(r.s2, r.s1), i.f) as varchar(max)),
        cast(json_value(isnull(r.s2, r.s1), i.t) as varchar(max))
    )) st(f1, t1, f2, t2)
    where i.c is not null
)

select top 1 part1 = part1.answer
    ,part2 = part2.answer
from rearranger
cross apply (select answer = string_agg(right([value], 1), '') from openjson(s1)) part1
cross apply (select answer = string_agg(right([value], 1), '') from openjson(s2)) part2
order by i desc
option (maxrecursion 0);
