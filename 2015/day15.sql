declare @ varchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2015/15.input', single_clob) d);
set @ = '[[' + trim(nchar(10) from @) + ']]]';

select @ = replace(@, tr, rw) from (values
    (': capacity ', '['),(' durability ', ''),(' flavor ', ''),(' texture ', ''),(' calories ', ''),
    ('Sprinkles', ''),('PeanutButter', ''),('Frosting', ''),('Sugar', ''),(char(10), '],')
) r(tr, rw);

select part1 = max(c*d*f*t)
    ,part2 = max(iif(cs = 500, c*d*f*t, 0))
from generate_series(1, 100) a
join generate_series(1, 100) b on a.[value] + b.[value] <= 100
join generate_series(1, 100) c on a.[value] + b.[value] + c.[value] <= 100
join generate_series(1, 100) d on a.[value] + b.[value] + c.[value] + d.[value] = 100
cross apply (values(a.[value],b.[value],c.[value],d.[value])) p(sp, pb, fr, su)
cross apply openjson(@) with (
    spc int '$[0][0]', spd int '$[0][1]', spf int '$[0][2]', spt int '$[0][3]', spcs int '$[0][4]',
    pbc int '$[1][0]', pbd int '$[1][1]', pbf int '$[1][2]', pbt int '$[1][3]', pbcs int '$[1][4]',
    frc int '$[2][0]', frd int '$[2][1]', frf int '$[2][2]', frt int '$[2][3]', frcs int '$[2][4]',
    suc int '$[3][0]', sud int '$[3][1]', suf int '$[3][2]', sut int '$[3][3]', sucs int '$[3][4]'
)
cross apply (values(
    greatest(sp*spc + pb*pbc + fr*frc + su*suc, 0),
    greatest(sp*spd + pb*pbd + fr*frd + su*sud, 0),
    greatest(sp*spf + pb*pbf + fr*frf + su*suf, 0),
    greatest(sp*spt + pb*pbt + fr*frt + su*sut, 0),
    greatest(sp*spcs + pb*pbcs + fr*frcs + su*sucs, 0)
)) x(c, d, f, t, cs);
