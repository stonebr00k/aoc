declare @input varchar(max) = 'iwrupvqb';

select top 1 part = 1, answer = [value]
from generate_series(0, 999999)
where left(convert(varchar(8), hashbytes('MD5', @input + cast([value] as varchar(32))), 1), 7) = '0x00000'
union all
select top 1 part = 2, answer = [value]
from generate_series(0, 9999999)
where convert(varchar(8), hashbytes('MD5', @input + cast([value] as varchar(32))), 1) like '0x000000%';
go
