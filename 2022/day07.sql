declare @ varchar(max) = trim(nchar(10) from (select BulkColumn from openrowset(bulk 'c:/temp/aoc/2022/07.input', single_clob) d));
set @ = '[["' + replace(replace(@, ' ', '","'), char(10), '"],["') + N'"]]';
declare @fs_json nvarchar(max);
declare @space_needed bigint;

with cmdlst as (
    select i = cast([key] as smallint) 
        ,a = cast(json_value([value], '$[0]') as nvarchar(16)) 
        ,b = cast(json_value([value], '$[1]') as nvarchar(16))
        ,c = cast(json_value([value], '$[2]') as nvarchar(16))
    from openjson(@)
)
,fs_builder as (
    select i = cast(0 as smallint)
        ,cpath = cast(N'$' as nvarchar(4000))
        ,a = cast(null as nvarchar(16))
        ,b = cast(null as nvarchar(16))
        ,c = cast(null as nvarchar(16))
        ,fs = cast(N'{}' as nvarchar(max))
    union all
    select i = l.i
        ,cpath = p.pth
        ,a = l.a, b = l.b ,c = l.c
        ,fs = iif(l.a = '$', b.fs, json_modify(b.fs, p.pth + '."' + l.b + '"', iif(l.a = 'dir', json_query(N'{}'), l.a)))
    from cmdlst l
    join fs_builder b on l.i = b.i + 1
    cross apply (values(
        iif(l.a + l.b = '$cd',iif(l.c = '..', left(b.cpath, len(b.cpath) - charindex('.', reverse(b.cpath))), b.cpath + '.' + l.c), b.cpath)
    )) p(pth)
)

select @fs_json = (select top 1 fs from fs_builder order by i desc) 
    ,@space_needed = -40000000 + (select sum(try_cast(a as int)) from cmdlst)
option(maxrecursion 0);

with tree as (
    select hid = cast(N'/' as nvarchar(64))
        ,[value] = cast(@fs_json as nvarchar(max))
        ,[type] = cast(5 as tinyint)
    union all
    select hid = cast(t.hid + cast(row_number() over(partition by t.hid order by (select null)) as nvarchar(3)) + N'/' as nvarchar(64))
        ,[value] = j.[value]
        ,[type] = j.[type]
    from tree t
    cross apply openjson(t.[value]) j
    where t.[type] in (4, 5)
)
,dirs as (
    select size = sum(cast(c.[value] as int))
    from tree p
    join tree c on hierarchyid::Parse(c.hid).IsDescendantOf(hierarchyid::Parse(p.hid)) = 1
    where p.[type] = 5 and c.[type] = 2
    group by p.hid
)

select part1 = sum(iif(size <= 100000, size, 0))
    ,part2 = min(iif(size >= @space_needed, size, 70000000))
from dirs;
