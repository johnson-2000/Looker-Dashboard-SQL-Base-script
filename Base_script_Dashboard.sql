
/*
Purpose: This script is a Base script for the tables accesed by the Dangerous goods suite of reporting dash board 
Created: Nov 22, 2023 by Donbosco Johnson (Dangerous Goods)
Server: `xyz`
Last updated:
Procedure Name (if applicable): 
Builds Table (if applicable): `Haz_loc_DD`
                              `Haz_shipping_details`
                              `junk.maintable`
                              `Hazsupplier_details`
                              `Hazquantity_OH`
*/




---------------HAZMAT LOOKER INVENTORY ------
CREATE OR REPLACE TEMP TABLE tmp_inventory_details AS (
   
  WITH hazmat_opra AS (
    SELECT SprID
    FROM `opra_hazmat_classification`
    GROUP BY 1
  )
 
  , location_ids AS (
    SELECT
      tsi.wh_id,
      ti.sprid,
      tsi.location_id,
    FROM `item` ti
    INNER JOIN `_item` tsi
      ON ti.ID = tsi.item_id
    INNER JOIN hazmat_opra
      ON hazmat_opra.SprID = ti.Sprid
    WHERE 1=1
      AND wh_id IN ('02','03','05','08','09','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24','25','26','27','28','29','30','31','32','33','34','35','36','37','38','39','40','41','42','44','47','48','49')
    GROUP BY 1,2,3
  )
 
  , inventory AS (
  SELECT
    iq.SprID,
    spr.SprPrSKU,
    CONCAT(iq.WHID) AS WHID, -- WHID is now a STRING
    wms.WSWHName AS WH_Name,
    jssp.SprWholesale AS Unit_Wholesale,
    SprWholesale*SUM(QtyInWarehouse) AS Value,
    SprOwnerSuID,
    s2.SuName,
    SUM(QtyInWarehouse) AS QtyInWarehouse,
    SUM(QtyOnHand) AS QtyOnHand,
    sum(QtyOnHold) AS QtyOnHold,
    SUM(QtyAvailableForSale) AS QtyAvailable,
    SUM(QtyUnprocessedAdjustments) AS QtyUnprocessedAdjustments,
    SUM(QtyUnprocessedCycleCount) AS QtyUnprocessedCycleCount,
    SUM(QtyInWarehouse)-SUM(QtyUnprocessedAdjustments) AS QtyActual,
    SUM(QtyInWarehouse)-SUM(QtyUnprocessedAdjustments)-SUM(QtyUnprocessedCycleCount) AS QtyActualLessCycle,
    (SUM(QtyAvailableForSale))*SprWholesale AS Available_Value,
    (SUM(QtyInWarehouse)-SUM(QtyUnprocessedAdjustments))*SprWholesale AS Total_Value,
    (SUM(QtyInWarehouse)-SUM(QtyUnprocessedAdjustments)-SUM(QtyUnprocessedCycleCount))*SprWholesale AS Total_Value_Less_Cycle


  FROM `inventory_quantity` iq
  LEFT JOIN `stock_product_owner` o
    ON iq.ownerid = o.sprownerid
  LEFT JOIN `wsupplier` s2
    ON o.sprownerSuID = s2.suid
  JOIN `_stock_product` spr
    ON spr.SprID = iq.SprID
  JOIN `supplier` wms
    ON wms.WSWHID = iq.WHID
  LEFT JOIN `supplier_stock_product` jssp
    ON spr.SprID = jssp.SprID
    AND SprOwnerSuID = jssp.SprSuID


  WHERE 1=1
    AND spr.sprid in (
      SELECT SprID
      FROM `hazmat_classification`  
      GROUP BY 1
      )
    AND QtyInWarehouse > 0
  GROUP BY iq.SprID,spr.SprPrSKU, iq.WHID, wms.WSWHName, jssp.SprWholesale, SprOwnerSuID, s2.SuName
  ORDER BY iq.WHID, iq.SprID
  )


  , rest AS (
    SELECT
      SprID,
      prsku,
      clid,
      ClInternalRef,
      prname,
      COALESCE(MAX(Haz_Goods), MIN(Haz_Goods)) AS Hazmat_Goods,    --COALESCE(MAX(Haz_Goods), MIN(Haz_Goods)) AS Haz_Goods,
      COALESCE(MAX(UN_ID_NUMBER), MIN(UN_ID_NUMBER)) AS UN_ID_NUMBERm,
      COALESCE(MAX(Battery_or_Battery_Included), MIN(Battery_or_Battery_Included)) AS Battery_included,
      COALESCE(MAX(Hazard_Class), MIN(Hazard_Class)) AS Hazard_Classm,
      COALESCE(MAX(Packing_Group), MIN(Packing_Group)) AS Packing_Groupm,
      COALESCE(MAX(Haz_Mat_Weight), MIN(Haz_Mat_Weight)) AS Haz_Mat_Weightm,
      COALESCE(MAX(Lithium_Battery), MIN(Lithium_Battery)) AS Lithium_Batterym,
      COALESCE(MAX(Battery_Comp), MIN(Battery_Comp)) AS Battery_Compm,
      COALESCE(MAX(Weight_Cells_Batts), MIN(Weight_Cells_Batts)) AS Weight_Cells_Battsm,
      COALESCE(MAX(Battery_Shipment), MIN(Battery_Shipment)) AS Battery_Shipmentm
   
    FROM `wf-gcp-us-ae-ops-prod.csn_whs_reporting.tbl_opra_hazmat_classification`
    GROUP BY  SprID, prsku,clid, ClInternalRef,prname
  )


  SELECT  
    i.*,
    ClInternalRef,
    prname,
    Hazmat_Goods,
    r.clid,
    r.UN_ID_NUMBERm,
    r.Battery_included,
    r.Hazard_Classm,
    r.Packing_Groupm,
    r.Haz_Mat_Weightm,
    r.Lithium_Batterym,
    r.Battery_Compm,
    r.Weight_Cells_Battsm,
    r.Battery_Shipmentm,
    l.location_id -- this will add N-1 number rows to your data where N is SUM(DISTINCT location_ids) for each SprID + wh_id


  FROM inventory i
  INNER JOIN rest r ON i.SprID = r.SprID
  LEFT JOIN location_ids l
    ON l.SprID = i.SprID
    AND l.wh_id = i.WHID
);


-- SELECT * FROM tmp_inventory_details;




CREATE OR REPLACE TABLE `Hazmat_loc_DD`  as
( select * from tmp_inventory_details)                                    ------------------- Perm table creation
;


---------------  HAZMAT LOOKER INVENTORY ---------


---------------  HAZMAT SUPPLIER SHIPPING --------


CREATE OR REPLACE TEMP TABLE tmp_shipping_details AS (
       
    WITH t1 AS
    (
        SELECT
            DISTINCT
            ttl.tran_log_id
            ,extract(date from ttl.start_tran_date)  as start_date
            ,  FORMAT_DATE('%B %Y', ttl.start_tran_date) AS month_name
            ,ttl.start_tran_date
            , DATE_TRUNC(ttl.start_tran_date, month) as tran_date
            , concat(wh.wh_id,' - ',wh.city) as Warehouse
            , ttl.item_number
            , ttl.tran_qty
            , loc.item_hu_indicator
            ,tor.order_number
            ,tor.order_id
            ,tor.store_order_number
            , haz.SprID as hazmat_sprid
        FROM
            `tran_log` ttl
        INNER JOIN
            `location` loc
        ON
                ttl.wh_id = loc.wh_id
            AND ttl.location_id = loc.location_id


        INNER JOIN
            `t_order` tor
        ON
                ttl.control_number = tor.order_number


        LEFT JOIN
            (
                SELECT DISTINCT SprID
                from `hazmat_classification`
            ) haz
        ON
                haz.SprID = ttl.item_number


        INNER JOIN
            `prod.aad.t_whse` wh
        ON
                ttl.wh_id = wh.wh_id


        WHERE
                ttl.tran_type = '301' ----- Picking Transactions
            AND ttl.start_tran_date between DATE_SUB(CURRENT_DATE(), INTERVAL 24 MONTH) and CURRENT_DATE()   --- 24 months from today
            AND tor.type_id IN (38, 414, 416, 419) ----- Live Orders(Excludes Liquidations, RTVs and Transfers)
    )


    SELECT
    *
    FROM t1
    WHERE hazmat_sprid is not null


);


CREATE OR REPLACE TABLE `Hazmat_shipping_details`  as
( select * from tmp_shipping_details)                                    ------------------- Perm table creation
;


CREATE or REPLACE TABLE `maintable` AS
(  SELECT SAFE_CAST(m.store_order_number as int64) as Store_order_num_int,*
FROM `Hazmat_shipping_details` m
INNER JOIN (
  SELECT order_number as Ordernumber,SUM(tran_qty) as Total_hazmat
  FROM `Hazmat_shipping_details`
  GROUP BY Ordernumber
  ) ij
ON ij.Ordernumber = m.order_number
LEFT JOIN (
  SELECT  distinct SprID
,SprPrSKU
,ClInternalRef
,prname
,clid
,Hazmat_Goods
,UN_ID_NUMBERm
,Battery_included
,Hazard_Classm
,Packing_Groupm
,Haz_Mat_Weightm
,Lithium_Batterym
 FROM `Hazmat_loc_DD`
  ) lj
ON  m.item_number = lj.SprID );


---------------  HAZMAT SUPPLIER SHIPPING -----------




---------------  HAZMAT SUPPLIER DETAILS-----------


CREATE OR REPLACE TEMP TABLE tmp_supplier_details AS (  
 
    WITH wayfaircatalog AS (  
        select distinct p.prsku as PrSKU,p.prname,prcyid, cylongname,
        prstatusname,COALESCE (acsdescription,drdescription) as Status_Reason,
        psmp.SupplierID,suname,psmp.IsActive , s.sudropship,s.suid,s.SuParentSuID,
        ClInternalRef, c.clid, PrBclgID, s.sugenerallocation
        from `_product` p                            
        INNER JOIN `join_product_class` pc
            ON pc.prsku = p.PrSKU                          
        INNER JOIN `class` c
            ON c.clid = pc.ClID                            
        INNER JOIN `_product_status` ps
            ON ps.prstatus = p.prstatus                                
        LEFT OUTER JOIN `_product_additional` a
            ON a.prsku = p.PrSKU                                                                                                            
        LEFT OUTER JOIN `_discontinued_reason` dr
            ON dr.DrID = a.PrDrID                                                                                          
        LEFT OUTER JOIN `scan_sell_reason` ac
            ON ac.AcsID = a.PrAcsID                                        
        LEFT OUTER JOIN `_supplier_manufacturer_part` psmp
            ON p.PrSKU = psmp.PrSKU        
        LEFT OUTER JOIN `supplier` s
            ON s.SuID = psmp.SupplierID
        LEFT OUTER JOIN `_country`
            ON cyid = prcyid                        
        )


       
    , rest AS (
    SELECT
      SprID,
      prsku as SKU,
      clid as ClassID,
      ClInternalRef as Internal_ref ,
      --prname as prName,
      SupplierID as Suppid,
      suname as SupplierName,
      COALESCE(MAX(Haz_Goods), MIN(Haz_Goods)) AS Hazmat_Goods,    --COALESCE(MAX(Haz_Goods), MIN(Haz_Goods)) AS Haz_Goods,
      COALESCE(MAX(UN_ID_NUMBER), MIN(UN_ID_NUMBER)) AS UN_ID_NUMBERm,
      COALESCE(MAX(Battery_or_Battery_Included), MIN(Battery_or_Battery_Included)) AS Battery_included,
      COALESCE(MAX(Hazard_Class), MIN(Hazard_Class)) AS Hazard_Classm,
      COALESCE(MAX(Packing_Group), MIN(Packing_Group)) AS Packing_Groupm,
      COALESCE(MAX(Haz_Mat_Weight), MIN(Haz_Mat_Weight)) AS Haz_Mat_Weightm,
      COALESCE(MAX(Lithium_Battery), MIN(Lithium_Battery)) AS Lithium_Batterym,
      COALESCE(MAX(Battery_Comp), MIN(Battery_Comp)) AS Battery_Compm,
      COALESCE(MAX(Weight_Cells_Batts), MIN(Weight_Cells_Batts)) AS Weight_Cells_Battsm,
      COALESCE(MAX(Battery_Shipment), MIN(Battery_Shipment)) AS Battery_Shipmentm
   
    FROM `_hazmat_classification`
    GROUP BY  SprID, SKU,ClassID, Internal_ref,SupplierID,suname
        )






select * from catalog wc
INNER JOIN  rest hz
    ON  hz.SKU = wc.PrSKU
    AND hz.Suppid = wc.SupplierID
WHERE
   wc.PrSKU IN (SELECT prsku from `_hazmat_classification`  )    
and  wc.prstatusname = "Live Product"
order by wc.PrSKU  
);


CREATE OR REPLACE TABLE `Hazmat_supplier_details`  as
( select * from tmp_supplier_details)                                    ------------------- Perm table creation
;


---------------  HAZMAT SUPPLIER DETAILS-----------


---------------  Quantity Script--------------------


CREATE OR REPLACE TABLE `Hazmat_quantity_OH`  as(
  SELECT
    iq.SprID,
    spr.SprPrSKU,
    CONCAT(iq.WHID) AS WHID, -- WHID is now a STRING
    wms.WSWHName AS WH_Name,
    jssp.SprWholesale AS Unit_Wholesale,
    SprWholesale*SUM(QtyInWarehouse) AS Value,
    SprOwnerSuID,
    s2.SuName,
    SUM(QtyInWarehouse) AS QtyInWarehouse,
    SUM(QtyOnHand) AS QtyOnHand,
    sum(QtyOnHold) AS QtyOnHold,
    SUM(QtyAvailableForSale) AS QtyAvailable,
    SUM(QtyUnprocessedAdjustments) AS QtyUnprocessedAdjustments,
    SUM(QtyUnprocessedCycleCount) AS QtyUnprocessedCycleCount,
    SUM(QtyInWarehouse)-SUM(QtyUnprocessedAdjustments) AS QtyActual,
    SUM(QtyInWarehouse)-SUM(QtyUnprocessedAdjustments)-SUM(QtyUnprocessedCycleCount) AS QtyActualLessCycle,
    (SUM(QtyAvailableForSale))*SprWholesale AS Available_Value,
    (SUM(QtyInWarehouse)-SUM(QtyUnprocessedAdjustments))*SprWholesale AS Total_Value,
    (SUM(QtyInWarehouse)-SUM(QtyUnprocessedAdjustments)-SUM(QtyUnprocessedCycleCount))*SprWholesale AS Total_Value_Less_Cycle


  FROM `inventory_quantity` iq
  LEFT JOIN `stock_product_owner` o
    ON iq.ownerid = o.sprownerid
  LEFT JOIN `supplier` s2
    ON o.sprownerSuID = s2.suid
  JOIN `stock_product` spr
    ON spr.SprID = iq.SprID
  JOIN `wms_supplier` wms
    ON wms.WSWHID = iq.WHID
  LEFT JOIN `supplier_stock_product` jssp
    ON spr.SprID = jssp.SprID
    AND SprOwnerSuID = jssp.SprSuID


  WHERE 1=1
    AND spr.sprid in (
      SELECT SprID
      FROM `opra_hazmat_classification`  
      GROUP BY 1
      )
    AND QtyInWarehouse > 0
  GROUP BY iq.SprID,spr.SprPrSKU, iq.WHID, wms.WSWHName, jssp.SprWholesale, SprOwnerSuID, s2.SuName
  ORDER BY iq.WHID, iq.SprID
  );


