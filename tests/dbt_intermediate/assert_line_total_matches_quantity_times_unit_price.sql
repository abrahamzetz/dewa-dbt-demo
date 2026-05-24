-- line_total should always equal quantity * unit_price.
-- Return rows where this invariant is broken to make the test fail.
select *
from {{ ref('order_items') }}
where line_total != quantity * unit_price
   or line_total is null
