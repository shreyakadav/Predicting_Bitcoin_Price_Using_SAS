# 📈 Bitcoin Price Prediction using SAS

This project involves a time series regression analysis to predict the weekly average price of Bitcoin (`coin_avg`) using various financial and behavioral indicators. The analysis was conducted using SAS, and the dataset includes weekly observations of variables such as Google search trends, stock prices, market indices, and cryptocurrency wallet metrics.

## 🧠 Objective
To identify statistically significant predictors of Bitcoin price changes and build a parsimonious regression model that can explain weekly variability.

## 📊 Dataset Description
The dataset includes 206 weekly observations with the following key variables:

- `coin_avg`: Weekly average price of Bitcoin (dependent variable)
- `new_wallets`: Number of new active wallets
- `coin_day`: Number of Bitcoins sold per week
- `buy_bitcoin`: Google search interest in "buy Bitcoin"
- `avg_dxy_value`: Average USD index value
- `gold`: Weekly price of gold
- `Intel_avg`: Average price of Intel stock
- `wallets_total`: Total number of Bitcoin wallets
- `snp_close`: S&P 500 closing value

All predictor variables were first-differenced to reduce autocorrelation.

## 📈 Methodology
- Initial full model regression with all variables
- Evaluation using p-values, t-values, and R² to assess significance
- Final parsimonious model created by removing non-significant variables

## 🧪 Final Model Results
- **R² = 27.68%** | Model statistically significant (p < 0.0001)
- Significant predictors:
  - `new_wallet_diff`: +$4.96 per 1000 new wallets
  - `buy_bitcoin_diff`: +$19.83 per 1% increase in search interest
  - `wallets_total_diff`: +$1.55 per 1000 new wallets
  - `snp_close_diff`: +$1.77 per 1% increase in S&P closing value

## 📁 Files
- `SAS_Project_Code.sas`: Contains SAS code for regression analysis
- `SAS_Project_Analysis.docx`: Contains statistical outputs and interpretation

## 📚 Skills Demonstrated
- Time series regression
- Variable transformation
- Model selection (parsimonious modeling)
- Data interpretation and report writing in SAS

## 📬 Contact
For questions, feel free to connect via [LinkedIn](https://www.linkedin.com/in/your-profile).
