declare @input varchar(max) = '3113322113';
declare @ tinyint = 1;
declare @part1 bigint;

while @ <= 50 begin;
    set @input = (
        select string_agg(s, '') from (
            select g, s = cast(len(string_agg(c, '')) as varchar(32)) + max(c)
            from (
                select i = [value], c, g = sum(iif(c = p, 0, 1)) over(order by [value])
                from generate_series(1, cast(len(@input) as int))
                cross apply (values(substring(@input, [value], 1), substring(@input, [value] - 1, 1))) x(c, p)
            ) x
            group by g
        ) y
    );

    if @ = 40 set @part1 = len(@input);
    set @ += 1;
end;

select part1 = @part1
    ,part2 = len(@input);
