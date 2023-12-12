/*  AoC 2023-07 (https://adventofcode.com/2023/day/7)  */
declare @ nvarchar(max) = replace((select BulkColumn from openrowset(bulk 'c:/temp/aoc/2023/07', single_clob)_), char(13), '');
set @ = concat(N'[["', replace(replace(@, nchar(10), N'],["'), N' ', N'",'), N']]');

with hand as (
    select part = p.part 
        ,id = row_number() over(order by (select null))
        ,cards = translate(cards, 'TJQKA', p.translation)
        ,bid
    from openjson(@) with (cards char(5) N'$[0]', bid smallint N'$[1]')
    cross join (values(1, 'abcde'),(2, 'a0cde')) p(part, translation)
)

select part, answer = sum(winnings)
from (
    select part, winnings = bid * row_number() over(partition by part order by [type], cards)
    from hand h
    cross apply (
        select [type] = isnull(string_agg(cnt + iif(is_first = 1, j, 0), '') within group(order by cnt desc), '5')
        from (
            select cnt
                ,is_first = ~cast(row_number() over(order by cnt desc, crd desc) -1 as bit)
                ,j = 5 - len(replace(h.cards, '0', ''))
            from (
                select crd, cnt = count(*)
                from (values(1),(2),(3),(4),(5)) i(val)
                cross apply (values(substring(h.cards, i.val, 1))) c(crd)
                where crd > '0'
                group by crd
            ) _
        ) _
    ) _
) _
group by part;
go
