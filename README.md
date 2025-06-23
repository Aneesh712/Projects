
## ⚙️ Steps Performed

1. Importing Data
   - Used `PROC IMPORT` to load Excel files.
2. Data Cleaning & Preparation
   - Filtered datasets using flags like `ITTFL='Y'` and `SAFFL='Y'`.
   - Created derived variables such as treatment groups and summary rows (`trt01a='Overall'`).
3. Statistical Analysis
   - Generated descriptive statistics (`mean`, `median`, `min`, `max`, `std`) using `PROC SUMMARY` and `PROC MEANS`.
   - Frequency tables using `PROC FREQ`.
   - Used macros to automate repeated steps.
4. Table Creation
   - Formatted output tables using `PROC TRANSPOSE`, `PROC SQL`, and data steps for display-ready reports.

## 🧰 Tools Used
- SAS 9.4
- Excel for input files

## 📈 Output
- Demographic summary table by treatment arm
- Adverse event summary table
- Response analysis table (e.g., BOR – Best Overall Response)

## 🧠 Key Learnings
- Efficient SAS macro programming
- Creating analysis-ready datasets
- Structuring clinical reports from raw data
- Importance of treatment flags (`ITTFL`, `SAFFL`, `TRT01A`) in clinical trials

## 👤 Author
Aneesh Reddy Pappireddy
Master's in Health Data Science  


