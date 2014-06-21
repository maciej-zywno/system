-- params: <period>, <day>, <minimum_c>, <minimum_v>, <record_limit>
with tmp as (
	select json_array_elements(indicators->'130') as t, ohlcv_per_symbol from indicators where day = '2014-06-13'
)
select t->>'symbol' as symbol
from tmp
where
  (ohlcv_per_symbol->(t->>'symbol')->>'c')::numeric > <minimum_c>
    and
  (ohlcv_per_symbol->(t->>'symbol')->>'v')::int > <minimum_v>
order by (t->>'rs')::decimal desc limit <record_limit>
