-- receipts table checks
-- ---------------------

-- check for receipts with points earned but no money spent
select * 
from fetch_analytics.production.receipts 
where points_earned > 0 and total_spent <= 0;

-- check for receipts scanned before purchase date
select *
from fetch_analytics.production.receipts 
where date_scanned < purchase_date;

-- check for receipts with zero or negative points earned
select *
from fetch_analytics.production.receipts
where points_earned <= 0;


-- receipt line items table checks
-- -------------------------------

-- check for items with zero price
select *
from fetch_analytics.production.receipt_line_items 
where item_price = 0;

-- check for items with null barcodes
select *
from fetch_analytics.production.receipt_line_items 
where barcode is null;

-- check for price discrepancies between user-flagged and item price
select *
from fetch_analytics.production.receipt_line_items 
where user_flagged_price != item_price;

-- check for inconsistent barcode-description mappings
select barcode, count(distinct description) as description_count
from fetch_analytics.production.receipt_line_items 
where barcode is not null
group by barcode
having count(distinct description) > 1
order by description_count desc;

-- brands table checks
-- -------------------

-- check for duplicate barcodes
select barcode, count(*) 
from fetch_analytics.production.brands 
where barcode is not null 
group by barcode 
having count(*) > 1;

-- check for missing brand codes
select *
from fetch_analytics.production.brands
where brand_code is null or trim(brand_code) = '';

-- check for missing categories
select *
from fetch_analytics.production.brands 
where category is null;

-- check for missing category codes
select *
from fetch_analytics.production.brands 
where category_code is null;

-- check for invalid top_brand values
select distinct top_brand
from fetch_analytics.production.brands;

-- users table checks
-- ------------------

-- check for users who have never logged in
select * 
from fetch_analytics.production.users 
where last_login is null;

-- check for users with missing state information
select * 
from fetch_analytics.production.users 
where state is null;

-- check for users with missing sign-up source
select * 
from fetch_analytics.production.users 
where sign_up_source is null;

-- check for duplicate user ids
select user_id, count(*) as count 
from fetch_analytics.production.users 
group by user_id 
having count(*) > 1;

-- cross-table relationship checks
-- -------------------------------

-- check for receipts with non-existent users
select * 
from fetch_analytics.production.receipts r
left join fetch_analytics.production.users u on r.user_id = u.user_id
where u.user_id is null;

-- check for finished receipts with no line items
select *
from fetch_analytics.production.receipts r
left join fetch_analytics.production.receipt_line_items rli on r.receipt_id = rli.receipt_id
where rli.receipt_id is null
  and r.rewards_receipt_status = 'FINISHED';

-- check for receipt line items with non-existent barcodes in brands table
select *
from fetch_analytics.production.receipt_line_items rli
left join fetch_analytics.production.brands b on rli.barcode = b.barcode
where rli.barcode is not null and b.barcode is null;

-- check for total spent discrepancies between receipts and line items
select *
from fetch_analytics.production.receipts r
join (
    select receipt_id, sum(final_price) as total
    from fetch_analytics.production.receipt_line_items
    group by receipt_id
) rli on r.receipt_id = rli.receipt_id
where abs(r.total_spent - rli.total) > 0.01;

-- check for item count discrepancies between receipts and line items
select *
from fetch_analytics.production.receipts r
join (
    select receipt_id, count(*) as item_count
    from fetch_analytics.production.receipt_line_items
    group by receipt_id
) rli on r.receipt_id = rli.receipt_id
where r.purchased_item_count != rli.item_count;

-- check for active users without receipts
select * 
from fetch_analytics.production.users u
left join fetch_analytics.production.receipts r on u.user_id = r.user_id
where u.active = true and r.receipt_id is null;

-- check for receipts created before user creation date
select *
from fetch_analytics.production.receipts r
join fetch_analytics.production.users u on r.user_id = u.user_id
where r.create_date < u.created_date;
