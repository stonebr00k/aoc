declare @input varchar(max) = trim(nchar(10) from (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/05.input', single_clob) d));
set @input = '["' + replace(@input, nchar(10), '","') + '"]';

declare @ins varchar(max) = (
    select '[' + string_agg('[' + replace(replace(replace([value], 'move ', ''), ' from ', ','), ' to ', ',') + ']', ',') + ']'
    from openjson(@input)
    where [value] like 'move%'
);

with rearranger as (   
    select i = 0 
        ,s1 = cast('[' + string_agg(s, ',') within group (order by p) + ']' as varchar(max))
        ,s2 = cast('[' + string_agg(s, ',') within group (order by p) + ']' as varchar(max))
    from (
        select x.p, s = '"' + trim(string_agg(substring([value], x.p, 1), '') within group(order by cast([key] as int) desc)) + '"'
        from openjson(@input)
        cross apply(values(2),(6),(10),(14),(18),(22),(26),(30),(34)) x(p)
        where [value] like '[[]%'
        group by x.p
    ) x
    union all
    select i = r.i + 1
        ,s1 = cast(json_modify(json_modify(r.s1, i.t, st.t1 + reverse(right(st.f1, i.c))), i.f, left(st.f1, len(st.f1) - i.c)) as varchar(max))
        ,s2 = cast(json_modify(json_modify(isnull(r.s2, r.s1), i.t, st.t2 + right(st.f2, i.c)), i.f, left(st.f2, len(st.f2) - i.c)) as varchar(max))
    from rearranger r
    cross apply (values(
        json_value(@ins, '$[' + cast(r.i as varchar(8)) + '][0]'),
        cast('$[' + cast(json_value(@ins, '$[' + cast(r.i as varchar(8)) + '][1]') - 1 as varchar(1)) + ']' as varchar(6)),
        cast('$[' + cast(json_value(@ins, '$[' + cast(r.i as varchar(8)) + '][2]') - 1 as varchar(1)) + ']' as varchar(6))
    )) i(c, f, t)
    cross apply (values(
        cast(json_value(r.s1, i.f) as varchar(128)),
        cast(json_value(r.s1, i.t) as varchar(128)),
        cast(json_value(r.s2, i.f) as varchar(128)),
        cast(json_value(r.s2, i.t) as varchar(128))
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
