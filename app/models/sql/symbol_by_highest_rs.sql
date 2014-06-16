-- params: <period>, <day>, <eod>, <volume>, <limit>
with tmp as (
	select (json_array_elements(indicators->'<period>')) as t from indicators where day = '<day>' --'2014-06-13'
)
select t->>'symbol' as symbol
--select t->>'symbol' as symbol, (t->>'sod')::decimal as sod, (t->>'eod')::decimal as eod, (t->>'rs')::decimal as rs
from tmp
where (t->>'eod')::decimal > <eod> and (t->>'volume')::int > <volume>
order by (t->>'rs')::decimal desc limit <limit>
