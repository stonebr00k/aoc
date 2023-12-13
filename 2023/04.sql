/*  AoC 2023-04 (https://adventofcode.com/2023/day/4)  */
declare @ varchar(max) = (select BulkColumn from openrowset(bulk 'C:/repo/stonebr00k/aoc/input/2023/04', single_clob)_);

declare @cards nvarchar(max) = (
    select [card].num
        ,new_cards = new_cards.[value]
        ,points = new_cards.points
        ,amount = 1
    from string_split(@, char(10), 1) ss
    cross apply (
        select num = cast(substring(ss.[value], 6, 3) as tinyint)
            ,win = concat(N'[', replace(replace(trim(substring(ss.[value], 11, 29)), '  ', ' '), ' ', ','), N']')
            ,my = concat(N'[', replace(replace(trim(substring(ss.[value], 42, 100)), '  ', ' '), ' ', ','), N']')
    ) [card]
    cross apply (
        select [value] = count(*)
            ,points = power(2, count(*) - 1)
        from openjson([card].win) w
        join openjson([card].my) m
            on w.[value] = m.[value]
    ) new_cards
    order by [card].num
    for json path
);
declare @original_no_of_cards tinyint = (select count(*) from openjson(@cards));

with scratcher as (
    select num = 1
        ,cards = @cards
        ,is_last = cast(0 as bit)
    union all
    select num = s.num + 1
        ,cards = (
            select num = c.num
                ,new_cards = c.new_cards
                ,amount = c.amount 
                    + iif(c.num between s.num + 1 and s.num + max(iif(c.num = s.num, new_cards, null)) over(order by (select null)), 1, 0) 
                    * max(iif(c.num = s.num, amount, null)) over(order by (select null))
            from openjson(s.cards) with (num tinyint, new_cards tinyint, amount int) c
            for json path
        )
        ,is_last = cast(iif(s.num + 1 = @original_no_of_cards, 1, 0) as bit)
    from scratcher s
    where s.is_last = 0
)

select part1 = (
        select sum(points)
        from openjson(@cards) with (points int)
    )
    ,part2 = (
        select sum(amount)
        from openjson((select cards from scratcher where is_last = 1)) with (amount int)
    )
option(maxrecursion 0);
go
