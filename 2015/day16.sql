declare @ varchar(max) = (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2015/16.input', single_clob) d);
set @ = '[{' + trim(nchar(10) from @) + '}]';

select @ = replace(@, tr, rw) from (values
    (':', ','),('Sue', '"sue":'),('children,', '"children":'),('cats,', '"cats":'),('samoyeds,', '"samoyeds":'),
    ('pomeranians,', '"pomeranians":'),('akitas,', '"akitas":'),('vizslas,', '"vizslas":'),('goldfish,', '"goldfish":'),
    ('trees,', '"trees":'),('cars,', '"cars":'),('perfumes,', '"perfumes":'),(char(10), '},{')
) r(tr, rw);

select part1 = sue
from openjson(@) with (
    sue int, children int, cats int, samoyeds int, pomeranians int, akitas int,
    vizslas int, goldfish int, trees int, cars int, perfumes int
)
where isnull(children, 3) = 3
    and isnull(cats, 7) = 7
    and isnull(samoyeds, 2) = 2
    and isnull(pomeranians, 3) = 3
    and isnull(akitas, 0) = 0
    and isnull(vizslas, 0) = 0
    and isnull(goldfish, 5) = 5
    and isnull(trees, 3) = 3
    and isnull(cars, 2) = 2
    and isnull(perfumes, 1) = 1;

select part2 = sue
from openjson(@) with (
    sue int, children int, cats int, samoyeds int, pomeranians int, akitas int,
    vizslas int, goldfish int, trees int, cars int, perfumes int
)
where isnull(children, 3) = 3
    and isnull(cats, 8) > 7
    and isnull(samoyeds, 2) = 2
    and isnull(pomeranians, 2) < 3
    and isnull(akitas, 0) = 0
    and isnull(vizslas, 0) = 0
    and isnull(goldfish, 4) < 5
    and isnull(trees, 4) > 3
    and isnull(cars, 2) = 2
    and isnull(perfumes, 1) = 1;
