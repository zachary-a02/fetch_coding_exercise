--create raw and production schemas 
create schema fetch_analytics.production;
create schema fetch_analytics.raw;

---receipts 
--create raw table
CREATE OR REPLACE TABLE fetch_analytics.raw.receipts (
    json_data VARIANT
); 

--copy json data from stage into raw table
COPY INTO fetch_analytics.raw.receipts 
FROM @FETCH_ANALYTICS.PRODUCTION.FETCH_JSON/receipts.json
FILE_FORMAT = (TYPE = JSON);

--flatten json data
CREATE OR REPLACE TABLE fetch_analytics.production.receipts (
    receipt_id STRING,
    bonus_points_earned INT,
    bonus_points_earned_reason STRING,
    create_date TIMESTAMP_NTZ,
    date_scanned TIMESTAMP_NTZ,
    finished_date TIMESTAMP_NTZ,
    modify_date TIMESTAMP_NTZ,
    points_awarded_date TIMESTAMP_NTZ,
    points_earned FLOAT,
    purchase_date TIMESTAMP_NTZ,
    purchased_item_count INT,
    rewards_receipt_status STRING,
    total_spent FLOAT,
    user_id STRING,
    rewards_receipt_item_list VARIANT
) AS
SELECT 
    json_data:_id['$oid']::string as receipt_id,
    json_data:bonusPointsEarned::INT AS bonus_points_earned,
    json_data:bonusPointsEarnedReason::STRING AS bonus_points_earned_reason,
    TO_TIMESTAMP_NTZ(json_data:createDate['$date']::NUMBER / 1000) AS create_date,
    TO_TIMESTAMP_NTZ(json_data:dateScanned['$date']::NUMBER / 1000) AS date_scanned,
    TO_TIMESTAMP_NTZ(json_data:finishedDate['$date']::NUMBER / 1000) AS finished_date,
    TO_TIMESTAMP_NTZ(json_data:modifyDate['$date']::NUMBER / 1000) AS modify_date,
    TO_TIMESTAMP_NTZ(json_data:pointsAwardedDate['$date']::NUMBER / 1000) AS points_awarded_date,
    json_data:pointsEarned::FLOAT AS points_earned,
    TO_TIMESTAMP_NTZ(json_data:purchaseDate['$date']::NUMBER / 1000) AS purchase_date,
    json_data:purchasedItemCount::INT AS purchased_item_count,
    json_data:rewardsReceiptStatus::STRING AS rewards_receipt_status,
    json_data:totalSpent::FLOAT AS total_spent,
    json_data:userId::STRING AS user_id,
    json_data:rewardsReceiptItemList AS rewards_receipt_item_list
FROM FETCH_ANALYTICS.RAW.RECEIPTS;


---brands
--create raw table
CREATE OR REPLACE TABLE fetch_analytics.raw.brands (
    json_data VARIANT
); 

--copy json data from stage into raw table
COPY INTO fetch_analytics.raw.brands 
FROM @FETCH_ANALYTICS.PRODUCTION.FETCH_JSON/brands.json
FILE_FORMAT = (TYPE = JSON);

--flatten json data
CREATE OR REPLACE TABLE fetch_analytics.production.brands (
    brand_id STRING,
    barcode STRING,
    category STRING,
    category_code STRING,
    cpg_id STRING,
    cpg_ref STRING,
    name STRING,
    top_brand BOOLEAN,
    brand_code STRING
) AS
SELECT 
    json_data:_id['$oid']::STRING as brand_id,
    json_data:barcode::STRING AS barcode,
    json_data:category::STRING AS category,
    json_data:categoryCode::STRING AS category_code,
    json_data:cpg['$id']['$oid']::STRING AS cpg_id,
    json_data:cpg['$ref']::STRING AS cpg_ref,
    json_data:name::STRING AS name,
    json_data:topBrand::BOOLEAN AS top_brand,
    json_data:brandCode::STRING AS brand_code
FROM FETCH_ANALYTICS.RAW.BRANDS;

--users
--create raw table
CREATE OR REPLACE TABLE fetch_analytics.raw.users (
    json_data VARIANT
); 

--copy json data from stage into raw table
COPY INTO fetch_analytics.raw.users 
FROM @FETCH_ANALYTICS.PRODUCTION.FETCH_JSON/users.json
FILE_FORMAT = (TYPE = JSON);

--flatten json data
CREATE OR REPLACE TABLE fetch_analytics.production.users (
    user_id STRING,
    active BOOLEAN,
    created_date TIMESTAMP_NTZ,
    last_login TIMESTAMP_NTZ,
    role STRING,
    sign_up_source STRING,
    state STRING
) AS
SELECT 
    json_data:_id['$oid']::STRING as user_id,
    json_data:active::BOOLEAN AS active,
    TO_TIMESTAMP_NTZ(json_data:createdDate['$date']::NUMBER / 1000) AS created_date,
    TO_TIMESTAMP_NTZ(json_data:lastLogin['$date']::NUMBER / 1000) AS last_login,
    json_data:role::STRING AS role,
    json_data:signUpSource::STRING AS sign_up_source,
    json_data:state::STRING AS state
FROM FETCH_ANALYTICS.RAW.USERS;

select * from fetch_analytics.production.users limit 1 ;

------

CREATE OR REPLACE TABLE fetch_analytics.production.receipt_line_items (
    receipt_id STRING,
    item_id INT,
    barcode STRING,
    description STRING,
    final_price FLOAT,
    item_price FLOAT,
    needs_fetch_review BOOLEAN,
    partner_item_id STRING,
    prevent_target_gap_points BOOLEAN,
    quantity_purchased INT,
    user_flagged_barcode STRING,
    user_flagged_description STRING,
    user_flagged_new_item BOOLEAN,
    user_flagged_price FLOAT,
    user_flagged_quantity INT,
    rewards_group STRING,
    rewards_product_partner_id STRING,
    points_not_awarded_reason STRING,
    points_payer_id STRING,
    PRIMARY KEY (receipt_id, item_id)
) AS
SELECT 
    r.receipt_id as receipt_id,
    i.index + 1 as item_id,
    i.value:barcode::STRING AS barcode,
    i.value:description::STRING AS description,
    i.value:finalPrice::FLOAT AS final_price,
    i.value:itemPrice::FLOAT AS item_price,
    i.value:needsFetchReview::BOOLEAN AS needs_fetch_review,
    i.value:partnerItemId::STRING AS partner_item_id,
    i.value:preventTargetGapPoints::BOOLEAN AS prevent_target_gap_points,
    i.value:quantityPurchased::INT AS quantity_purchased,
    i.value:userFlaggedBarcode::STRING AS user_flagged_barcode,
    i.value:userFlaggedDescription::STRING AS user_flagged_description,
    i.value:userFlaggedNewItem::BOOLEAN AS user_flagged_new_item,
    i.value:userFlaggedPrice::FLOAT AS user_flagged_price,
    i.value:userFlaggedQuantity::INT AS user_flagged_quantity,
    i.value:rewardsGroup::STRING AS rewards_group,
    i.value:rewardsProductPartnerId::STRING AS rewards_product_partner_id,
    i.value:pointsNotAwardedReason::STRING AS points_not_awarded_reason,
    i.value:pointsPayerId::STRING AS points_payer_id
FROM 
    fetch_analytics.production.receipts r,
    LATERAL FLATTEN(input => r.rewards_receipt_item_list) i;
