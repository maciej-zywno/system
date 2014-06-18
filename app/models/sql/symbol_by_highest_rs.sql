-- params: <period>, <day>, <minimum_c>, <minimum_v>, <record_limit>
with tmp as (
	select (json_array_elements(indicators->'<period>')) as t from indicators where day = '<day>' --'2014-06-13'
)
select t->>'symbol' as symbol
--select t->>'symbol' as symbol, (t->>'o')::decimal as o, (t->>'c')::decimal as c, (t->>'rs')::decimal as rs
from tmp
where (t->>'c')::decimal > <minimum_c> and (t->>'v')::int > <minimum_v>
order by (t->>'rs')::decimal desc limit <record_limit>
