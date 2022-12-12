create or alter function dbo.solve (@part tinyint, @input nvarchar(max))
returns table
as return (
    with monkey as (
        select id = cast([key] as tinyint)
            ,op = cast(json_value([value], '$[2]') as tinyint)
            ,v = cast(json_value([value], '$[3]') as bigint)
            ,div = cast(json_value([value], '$[4]') as int)
            ,true = cast(json_value([value], '$[5]') as tinyint)
            ,false = cast(json_value([value], '$[6]') as tinyint)
            ,[mod] = cast(ceiling(exp(sum(log(cast(json_value([value], '$[4]') as bigint))) over())) as int)
        from openjson(@input)
    )
    ,monkey_business as (
        select ri = 1
            ,monkey = cast(s.[key] as tinyint)
            ,item = cast(i.[value] as bigint)
        from openjson(@input) s
        cross apply openjson([value], '$[0]') i
        union all
        select ri = mb.ri + iif(iif(i.wl % m.div = 0, m.true, m.false) > mb.monkey, 0, 1)
            ,monkey = iif(i.wl % m.div = 0, m.true, m.false)
            ,item = i.wl
        from monkey_business mb
        join monkey m on mb.monkey = m.id
        cross apply (values(mb.item, isnull(m.v, mb.item))) x(i, v)
        cross apply (values(choose(op, x.i+x.v, x.i-x.v, x.i*x.v, x.i/x.v) / choose(@part, 3, 1) % m.[mod])) i(wl)
        where mb.ri <= choose(@part, 20, 10000)
    )
    ,results as (
        select rnk = row_number() over(order by count(*) desc)
            ,cnt = cast(count(*) as bigint)
        from monkey_business
        where ri <= choose(@part, 20, 10000)
        group by monkey
    )

    select answer = sum(choose(rnk, cnt, 0)) * sum(choose(rnk, 0, cnt))
    from results
);
go

declare @ varchar(max) = '{' + (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/11.input', single_clob) d);
select @ = replace(@, tr, rw) from (values
    (' ', ''),(char(10)+char(10), '],'),(':'+char(10)+'Startingitems:', '":[['),(char(10)+'Operation:new=', '],'),
    (char(10)+'Test:divisibleby', ','),(char(10)+'Iftrue:throwtomonkey', ','),(char(10)+'Iffalse:throwtomonkey', ','),
    ('old', 'null'),('+', ',1,'),('-', ',2,'),('*', ',3,'),('/', ',4,'),('Monkey', '"'),(char(10), ']}')
) r(tr, rw);

select part1 = answer from dbo.solve(1, @);
select part2 = answer from dbo.solve(2, @) option(maxrecursion 0);
