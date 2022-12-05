declare @ varchar(max) = 'vzbxkghb';

declare @part1 varchar(8) = (
    select iif(c4 <= 120 and substring(@, 4, 5) < 'xxyzz', 
        substring(@, 1, 3) + replicate(char(c4), 2) + char(c4 + 1) + replicate(char(c4 + 2), 2),
        substring(@, 1, 2) + char(ascii(substring(@, 3, 1)) + 1) + 'aabcc'
    )
    from (values(ascii(substring(@, 4, 1)))) x(c4)
);

set @ = @part1;

declare @part2 varchar(8) = (
    select iif(c4 <= 120 and substring(@, 4, 5) < 'xxyzz', 
        substring(@, 1, 3) + replicate(char(c4), 2) + char(c4 + 1) + replicate(char(c4 + 2), 2),
        substring(@, 1, 2) + char(ascii(substring(@, 3, 1)) + 1) + 'aabcc'
    )
    from (values(ascii(substring(@, 4, 1)))) x(c4)
);

select part1 = @part1
    ,part2 = @part2;
