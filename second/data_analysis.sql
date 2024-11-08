--What are the top 5 brands by receipts scanned for most recent month?
with receipt_brand_breakout as (
    select 
    
        r.receipt_id,
        date_trunc('month',date_scanned)::date as date_scanned_month,
        b.brand_code
        
    from receipts r 
    left join receipt_line_items ri ON r.receipt_id = ri.receipt_id
    left join brands b ON ri.barcode = b.barcode
),
scanned_brands_aggregated as (
    select 
    
        date_scanned_month,
        brand_code,
        count(*) as scanned_count,
        dense_rank() over (order by date_scanned_month desc) as date_scanned_month_rank,
        dense_rank() over (partition by date_scanned_month order by scanned_count desc) as brand_scanned_rank

    from receipt_brand_breakout
    group by 1,2 
)

    select 
        *
    from scanned_brands_aggregated
    where brand_scanned_rank <= 5
    and date_scanned_month_rank <= 1
    order by date_scanned_month desc,brand_scanned_rank asc;


--How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?
with receipt_brand_breakout as (
    select 
    
        r.receipt_id,
        date_trunc('month',date_scanned)::date as date_scanned_month,
        b.brand_code
        
    from receipts r 
    left join receipt_line_items ri ON r.receipt_id = ri.receipt_id
    left join brands b ON ri.barcode = b.barcode
),
scanned_brands_aggregated as (
    select 
    
        date_scanned_month,
        brand_code,
        count(*) as scanned_count,
        dense_rank() over (order by date_scanned_month desc) as date_scanned_month_rank,
        dense_rank() over (partition by date_scanned_month order by scanned_count desc) as brand_scanned_rank

    from receipt_brand_breakout
    group by 1,2 
)

    select 
        *
    from scanned_brands_aggregated
    where brand_scanned_rank <= 5
    and date_scanned_month_rank <= 2
    order by date_scanned_month desc,brand_scanned_rank asc;


-------
--Entire Data Model Result


 with receipt_brand_breakout as (
    select 
    
        r.receipt_id,
        date_trunc('month',date_scanned)::date as date_scanned_month,
        b.brand_code
        
    from receipts r 
    left join receipt_line_items ri ON r.receipt_id = ri.receipt_id
    left join brands b ON ri.barcode = b.barcode
),
scanned_brands_aggregated as (
    select 
    
        date_scanned_month,
        brand_code,
        count(*) as scanned_count,
        dense_rank() over (order by date_scanned_month desc) as date_scanned_month_rank,
        dense_rank() over (partition by date_scanned_month order by scanned_count desc) as brand_scanned_rank

    from receipt_brand_breakout
    group by 1,2 
)

    select 
        *
    from scanned_brands_aggregated
    order by date_scanned_month desc,brand_scanned_rank asc

;
