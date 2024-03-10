
---

# Looker Dashboard/ SQL Base script

## Project Overview
This project focuses on creating a reporting dashboard for managing dangerous goods inventory. It utilizes Looker to visualize inventory data extracted from various tables related to hazardous materials.

## Base Script Overview
The base script is used to populate tables accessed by the HAZMAT Looker Inventory dashboard. It involves several key steps:

1. **Creating Temporary Inventory Details:**
   - Combines data from multiple tables to create a temporary table (`inventory_details`) with inventory details for hazardous materials.
   - Utilizes common table expressions (CTEs) to organize and filter data efficiently.

2. **Creating Final Inventory Table:**
   - Populates the `Hazmat_loc_DD` table with the data from the temporary table, acting as a permanent table for inventory details.
   - Provides a solid foundation for Looker to access and visualize inventory data.

3. **Creating Temporary Shipping Details:**
   - Extracts shipping data related to hazardous materials from transaction logs and order details.
   - Creates a temporary table (`shipping_details`) to store shipping details for hazardous materials.

4. **Creating Final Shipping Table:**
   - Populates the `Hazmat_shipping_details` table with the data from the temporary shipping table, acting as a permanent table for shipping details.

5. **Creating Supplier Details:**
   - Extracts supplier information related to hazardous materials.
   - Creates a temporary table (`supplier_details`) to store supplier details for hazardous materials.

6. **Creating Final Supplier Table:**
   - Populates the `Hazmat_supplier` table with the data from the temporary supplier table, acting as a permanent table for supplier details.

7. **Creating Quantity Table:**
   - Extracts quantity information related to hazardous materials inventory.
   - Creates a table (`Hazmat_quantity`) to store quantity details for hazardous materials.

## SQL Scripting Skills Demonstrated
- **Data Extraction and Manipulation:** Efficiently extracting data from multiple tables and using CTEs for organizing and filtering data.
- **Table Creation:** Creating temporary and permanent tables to store and manage inventory, shipping, and supplier details.
- **Join Operations:** Utilizing inner and left joins to combine data from different tables based on common columns.
- **Aggregation Functions:** Using aggregate functions like SUM to calculate total quantities and values.
- **Data Cleaning and Transformation:** Handling NULL values and using COALESCE to select non-NULL values.
- **SQL Best Practices:** Following best practices such as using aliases for readability and ordering data appropriately.

This base script serves as a foundational element for the HAZMAT Looker Inventory dashboard, providing a comprehensive and structured approach to managing and visualizing hazardous materials inventory data.

---












