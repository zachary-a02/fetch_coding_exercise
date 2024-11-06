# fetch_coding_exercise

<b>First: Review Existing Unstructured Data and Diagram a New Structured Relational Data Model</b>

<img width="1658" alt="Screenshot 2024-11-05 at 7 11 41 PM" src="https://github.com/user-attachments/assets/a467425d-ccd7-4d1e-96b3-b50aeb030a8c">

---

<b>Second: Write queries that directly answer predetermined questions from a business stakeholder</b>

1. What are the top 5 brands by receipts scanned for most recent month?
```sql
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
    order by date_scanned_month desc,brand_scanned_rank asc

;
```
![Screenshot 2024-11-05 at 7 08 55 PM](https://github.com/user-attachments/assets/6edd9b17-077a-44a3-a05f-cdca0a6f8553)


2. How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?
```sql
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
    order by date_scanned_month desc,brand_scanned_rank asc
```
![Screenshot 2024-11-05 at 7 08 40 PM](https://github.com/user-attachments/assets/b9cbab66-5a7f-49d5-ad70-39d3b79c5daa)

<b>Entire Data Model Result</b>

Things to note:
1. Utilized dense_rank for date_scanned_month_rank and brand_scanned_rank because we want to include ties (EX: brands DIETCHRIS2 & PREGO both have the same scanned amount in 2021-01-01 so we would want to include both of them)

```sql
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
    -- where brand_scanned_rank <= 5
    -- and date_scanned_month_rank <= 1
    order by date_scanned_month desc,brand_scanned_rank asc

;
```
![Screenshot 2024-11-05 at 7 08 21 PM](https://github.com/user-attachments/assets/649fe4f0-a253-434b-a0c8-c4aa02f5fa97)

---
<b>Third: Evaluate Data Quality Issues in the Data Provided</b>
1. These could be automated inside dbt utilizing data tests

