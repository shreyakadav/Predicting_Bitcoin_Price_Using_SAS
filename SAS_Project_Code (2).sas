
/* Import all the three files */
proc import
	datafile = "C:\Users\skadav\Downloads\bitcoin_price_volume_main_2017_2021_fixed.xlsx"
	out = price_orig
	dbms = xlsx;
run;

proc import
	datafile = "C:\Users\skadav\Downloads\Google_Trends_BuyBitcoin_5yr.xlsx"
	out = googlefile_orig
	dbms = xlsx;
run;

proc import
	datafile = "C:\Users\skadav\Downloads\Bitcoin Crypto Active wallets.csv"
	out = wallets_orig
	dbms = csv;
run;

/* Prepare the wallets file to aggregate it to daily records */
data wallets2;
set wallets_orig;
rename n_unique_addresses = wallets_char;
Excel_Date = round(Excel_Date);
sasdate = Excel_Date - 21916;
if sasdate < 20818 then delete;
record + 1;
run;

proc sort data = wallets2; by descending record; run;

/* Calculate the wallets for daily records by taking the lag of wallets */
data wallets_compare1;
set wallets2;
format wallets 9.;
wallets = input(wallets_char, comma9.);
wallets_next = lag(wallets);
wallets_daydiff = wallets_next - wallets;
run;

/* Creating the daily records with wallets */
data make_days_wallets;
set wallets_compare1;
do i = 0 to 2;
	new_date = sasdate + i;
	new_date2 = put(new_date, date9.);
	change_value = i * (wallets_daydiff / 3);
	new_wallet = sum(wallets, change_value);
	format new_wallet 9.;
keep date_orig wallets new_wallet new_date new_date2;
output;
end;
run;

proc sort data = make_days_wallets; by new_date; run;

/* data wallet3;
retain data_orig new_date new_date2 wallets new_wallet;
set make_days_wallets;
new_wallet = round(new_wallet);
if new_date > 22287 then delete;
keep date_orig new_date new_date2 new_wallet wallets_daydiff date_orig record i;
run; */

/* Covert 3 day to 1 day interval
proc expand data = wallets2 out = zwallet_daily to day method = join;
	convert wallets = daily_wallets;
	id date_orig;
run; */

/* Preparing the price dataset for merge */
data price_date;
set price_orig;
new_date = Date;
drop k l m n;
run;

/* Sort before merging */
proc sort data = make_days_wallets; by new_date; run;

proc sort data = price_date; by new_date; run;

/* Merge price and wallets file */
data combo_price_wallets;
merge make_days_wallets (in = a) price_date (in = b);
by new_date;
year = year(date);
if a and b then count + 1;
if a and b then output;
run;

/* Prepare combo file before merge */
data combo2;
length week_str $2 unique_week $6;
set combo_price_wallets;
week = week(new_date, 'w');
week_str = week;
if week < 10 then week_str = cats(0, week);
unique_week = cats(year, week_str);
keep unique_week Coin_Avg coin_day new_date new_wallet year week;
run;

proc sort data = combo2; by unique_week; run;

/* Aggregate the combo file to weekly level */
proc means data = combo2 noprint;
class unique_week;
var coin_avg new_wallet coin_day;
output out = agg_combo2;
run;

/* Clean the aggregated merged file */
data combo_weekly;
length year 4;
set agg_combo2;
where _type_ > 0 and _stat_ = "MEAN";
year2 = substr(unique_week, 1, 4);
year = year2 + 0;
drop _type_ _stat_ _freq_ year2;
run;

/* Prepare google file for merge */
data google2;
length year 4 week_str $2 unique_week $6;
set googlefile_orig;
sasdate = round(excel_date_google) - 21916;
if sasdate < 20820 then delete;
year = year(sasdate);
week = week(sasdate, 'w');
week_str = week;
google_date = date_orig;
drop date_orig;
if week < 10 then week_str = cats(0, week);
unique_week = cats(year, week_str);
run;

/* Sort both the files before merging */
proc sort data = combo_weekly; by unique_week; run;

proc sort data = google2; by unique_week; run;

/* Merge the file (3 files) */
data combo_google_price_wallets;
merge combo_weekly (in = a) google2 (in = b);
by unique_week;
if a and b then output;
run;

proc freq data = combo_google_price_wallets; tables year; run;

/* Caluclating the first difference */
data diff_combo;
set combo_google_price_wallets;
coin_avg_lag = lag(coin_avg);
coin_avg_diff = coin_avg - coin_avg_lag;
new_wallet_lag = lag(new_wallet);
new_wallet_diff = new_wallet - new_wallet_lag;
coin_day_lag = lag(coin_day);
coin_day_diff = coin_day - coin_day_lag;
buy_bitcoin_lag = lag(buy_bitcoin);
buy_bitcoin_diff = buy_bitcoin - buy_bitcoin_lag;
if year > 2020 then delete;
run; 

/* Import the remaining five files */
libname down "C:\Users\skadav\Downloads";
run;

data dollar_strength;
set down.dollar_strength_dxy_index;
run;

data gold_price;
set down.gold_price_update;
run;

data intel_stock;
set down.intel_stock;
run;

data total_wallets;
set down.total_wallets;
run;

data weekly_snp;
set down.weekly_snp;
run;

/* Sort the first three out of the five files for merging */
proc sort data = dollar_strength; by sasdate; run;

proc sort data = gold_price; by sasdate; run;

proc sort data = intel_stock; by sasdate; run;

/* Merge the above three files */
data combo1;
merge dollar_strength (in = a) gold_price (in = b) intel_stock (in = c);
by sasdate;
if a and b and c then output;
run;

/* Change variables for merge */
data total_wallets;
length unique_week $6;
set total_wallets;
unique_week = put(week_uniq, 6.);
run;

data weekly_snp;
length unique_week $6;
set weekly_snp;
unique_week = put(year_week, 6.);
run;

/* Sort before merging */
proc sort data = combo1; by unique_week; run;

proc sort data = total_wallets; by unique_week; run;

proc sort data = weekly_snp; by unique_week; run;

/* Merge the 5 new files */
data combo_5_files;
merge combo1 (in = a) total_wallets (in = b) weekly_snp (in = c);
by unique_week;
if a and b and c then output;
drop year_week week_uniq;
run;

/* Sort both the combo files (3FilesMerged and 5FilesMerged) */
proc sort data = combo_5_files; by unique_week; run;

proc sort data = diff_combo; by unique_week; run;

/* Final Merge with 8 files */
data Final_8_Files_Merge;
merge combo_5_files (in = a) diff_combo (in = b);
by unique_week;
if a and b then output;
run;

proc freq data = Final_8_Files_Merge; tables year; run;

/* Calculate the first differences */
data Final_diff_combo;
set Final_8_Files_Merge;
avg_dxy_value_lag = lag(avg_dxy_value);
avg_dxy_value_diff = avg_dxy_value - avg_dxy_value_lag;
gold = price;
gold_lag = lag(gold);
gold_diff = gold - gold_lag;
Intel_avg_lag = lag(Intel_avg);
Intel_avg_diff = Intel_avg - Intel_avg_lag;
wallets_total_lag = lag(wallets_total);
wallets_total_diff = wallets_total - wallets_total_lag;
snp_close_lag = lag(snp_close);
snp_close_diff = snp_close - snp_close_lag;
run;

/* Save the final dataset */
data down.Final_SAS_Merge;
set Final_diff_combo;
run;

/* Descriptive Statistics */
proc means data = Final_diff_combo;
class year;
var coin_avg new_wallet coin_day buy_bitcoin avg_dxy_value gold Intel_avg wallets_total snp_close;
run;

proc means data = Final_diff_combo;
class year;
var coin_avg;
run;

proc means data = Final_diff_combo;
class unique_week;
var coin_avg;
run;

proc sort data = Final_diff_combo; by unique_week; run;

proc sgplot data = Final_diff_combo;
series X = unique_week Y = coin_avg;
xaxis label = "Year_Week";
*xaxis fitpolicy = thin;
*xaxis fitpolicy = rotatethin;
run;

proc means data = Final_diff_combo;
class unique_week;
var wallets_total;
run;

proc sgplot data = Final_diff_combo;
series X = unique_week Y = wallets_total;
run;

proc sgplot data = Final_diff_combo;
series X = unique_week Y = avg_dxy_value;
run;

proc sgplot data = Final_diff_combo;
series X = unique_week Y = new_wallet;
run;

proc arima data = Final_diff_combo
plots(unpack) = all;
identify var = coin_avg;
run;
quit;

proc arima data = Final_diff_combo
plots(unpack) = all;
identify var = coin_avg_diff;
run;
quit;

/* Correlations */
proc corr data = Final_diff_combo;
var coin_avg new_wallet coin_day buy_bitcoin avg_dxy_value gold Intel_avg wallets_total snp_close;
run;

proc corr data = Final_diff_combo;
var coin_avg_diff new_wallet_diff coin_day_diff buy_bitcoin_diff avg_dxy_value_diff gold_diff Intel_avg_diff wallets_total_diff snp_close_diff;
run;

/* All predictive variables */
proc reg data = Final_diff_combo;
model coin_avg_diff =  new_wallet_diff coin_day_diff buy_bitcoin_diff avg_dxy_value_diff gold_diff Intel_avg_diff wallets_total_diff snp_close_diff;
run;
quit;

/* Removing insignificant variables one-by-one */
proc reg data = Final_diff_combo;
model coin_avg_diff =  new_wallet_diff buy_bitcoin_diff avg_dxy_value_diff gold_diff Intel_avg_diff wallets_total_diff snp_close_diff;
run;
quit;

proc reg data = Final_diff_combo;
model coin_avg_diff =  new_wallet_diff coin_day_diff buy_bitcoin_diff gold_diff Intel_avg_diff wallets_total_diff snp_close_diff;
run;
quit;

proc reg data = Final_diff_combo;
model coin_avg_diff =  new_wallet_diff coin_day_diff buy_bitcoin_diff avg_dxy_value_diff Intel_avg_diff wallets_total_diff snp_close_diff;
run;
quit;

proc reg data = Final_diff_combo;
model coin_avg_diff =  new_wallet_diff coin_day_diff buy_bitcoin_diff avg_dxy_value_diff gold_diff wallets_total_diff snp_close_diff;
run;
quit;

/* Bivariate Regressions */
proc reg data = Final_diff_combo;
model coin_avg_diff = new_wallet_diff;
run;
quit;

proc reg data = Final_diff_combo;
model coin_avg_diff = coin_day_diff;
run;
quit;

proc reg data = Final_diff_combo;
model coin_avg_diff = buy_bitcoin_diff;
run;
quit;

proc reg data = Final_diff_combo;
model coin_avg_diff = avg_dxy_value_diff;
run;
quit;

proc reg data = Final_diff_combo;
model coin_avg_diff = gold_diff;
run;
quit;

proc reg data = Final_diff_combo;
model coin_avg_diff = Intel_avg_diff;
run;
quit;

proc reg data = Final_diff_combo;
model coin_avg_diff = wallets_total_diff;
run;
quit;

proc reg data = Final_diff_combo;
model coin_avg_diff = snp_close_diff;
run;
quit;

/* Final Model: Only significant predictive variables (Parsimonious Model)*/
proc reg data = Final_diff_combo;
model coin_avg_diff =  new_wallet_diff buy_bitcoin_diff wallets_total_diff snp_close_diff;
run;
quit;







/*

Autocorrelation, first-differencing, Correlation & Regression for 3 Files

proc freq data = combo_google_price_wallets; tables year; run;

/* Caluclating the first difference
data diff_combo;
set combo_google_price_wallets;
coin_avg_lag = lag(coin_avg);
coin_avg_diff = coin_avg - coin_avg_lag;
new_wallet_lag = lag(new_wallet);
new_wallet_diff = new_wallet - new_wallet_lag;
coin_day_lag = lag(coin_day);
coin_day_diff = coin_day - coin_day_lag;
buy_bitcoin_lag = lag(buy_bitcoin);
buy_bitcoin_diff = buy_bitcoin - buy_bitcoin_lag;
if year > 2020 then delete;
run; */

/* Correlation
proc corr data = diff_combo;
var coin_avg new_wallet coin_day buy_bitcoin;
run;

proc corr data = diff_combo;
var coin_avg_diff new_wallet_diff coin_day_diff buy_bitcoin_diff;
run; */

/* Regression
proc reg data = diff_combo plots = none;
model coin_avg = new_wallet;
run;
quit;

proc reg data = diff_combo plots = none;
model coin_avg_diff = new_wallet_diff;
run;
quit;

proc reg data = diff_combo plots = none;
model coin_avg = new_wallet coin_day buy_bitcoin year;
run;
quit;

proc reg data = diff_combo plots = none;
model coin_avg_diff = new_wallet_diff coin_day_diff buy_bitcoin_diff;
run;
quit;

proc reg data = diff_combo plots = none;
model coin_avg_diff = new_wallet_diff coin_day_diff buy_bitcoin_diff year;
run;
quit; */
