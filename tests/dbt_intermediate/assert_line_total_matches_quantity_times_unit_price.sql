-- line_total should always equal quantity * unit_price_usd.
-- Return rows where this invariant is broken to make the test fail.
select *
from {{ ref('order_items') }}
where line_total != quantity * unit_price_usd