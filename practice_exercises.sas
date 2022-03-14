ODS HTML CLOSE;
ODS HTML;
* data step;
data work.shoes;
 set sashelp.shoes;
 NetSales=Sales-Returns;
run;
* mean and sum using the means procedure;
proc means data=work.shoes mean sum maxdec=2;
 	var NetSales;
	class region;
run;
* Create a library. First create the folder Output as shown;
libname out "C:\Users\........";

/* Create two data sets class_copy1 and class_copy2 in the Work and out 
libraries */;
data class_copy1 Out.class_copy2;
	set sashelp.class;
run;
proc contents data = out.class_copy2;
run;

OPTIONS validvarname = V7;
LIBNAME Teach XLSX "C:\Users\TCH_DATA.xlsx";

proc contents data = Teach.Children_info_repeat;
run;

proc print data = Teach.Children_info_repeat;
run;

libname Teach clear;

proc import datafile = "C:\Users\SAS Courses\Weather_Data_Leb.csv"
						dbms = csv
						out = weather_leb
						replace;
run;

proc contents data = weather_leb;
run;

proc print data = weather_leb;
run;

proc setinit; run;

/**********************************************/
/* Create the pg1 library. First define       */
/*the file path of the data sets              */
/**********************************************/
%let path=C:/Users/SAS Courses/EPG1V2/data;
libname PG1 "&path";

*list first 10 rows;
proc print data = pg1.storm_summary (obs = 10);
	var Season Name Basin MaxWindMPH MinPressure StartDate EndDate;
run;
/* Calculate summary statistics */;
proc means data = pg1.storm_summary;
	var MaxWindMPH MinPressure;
run;	
/* Calculate extreme values */;
proc univariate data = pg1.storm_summary;
	var MaxWindMPH MinPressure;
run;

/* Macro variables */
%let windSpeed = 100;
%let BasinCode = SP;
%let Date = 01Jan2010;

proc print data = pg1.storm_summary;
	where MaxWindMPH >= &windSpeed and Basin = "&BasinCode" and startDate >= "&Date"d;
	var Basin Name startDate endDate MaxWindMPH;
run;

proc means data = pg1.storm_summary;
	where MaxWindMPH >= &windSpeed and Basin = "&BasinCode" and startDate >= "&Date"d;
	var MaxWindMPH MinPressure;
run;

proc freq data = pg1.np_species;
	where Species_ID LIKE "YOSE%" and Category = "Mammal";
	tables Abundance Conservation_Status;
run;

PROC PRINT DATA = pg1.np_species;
	where Species_ID LIKE "YOSE%" and Category = "Mammal";
	var Species_ID Category Scientific_Name Common_Names;
run;

%let ParkCode=ZION;
%let SpeciesCat=Bird;

proc freq data=pg1.np_species;
    tables Abundance Conservation_Status;
    where Species_ID like "&ParkCode%" and
          Category="&SpeciesCat";
run;

proc print data=pg1.np_species;
    var Species_ID Category Scientific_Name Common_Names;
    where Species_ID like "&ParkCode%" and
          Category="&SpeciesCat";
run;

/*Formatting data values in results*/
proc print data = pg1.storm_damage;
	format Date ddmmyy10.
		   Cost dollar16.;
run;

/*Sort and removing duplicates. The _ALL_ statement to remove adjacent 
duplicate row We'll start by looking at
the Storm_Detail SAS table. Recall that this is a table that includes multiple rows per 
storm. Notice we have measurements every six hours. It's possible that there may
be some rows that are entirely duplicated. And in that situation,
we would like to remove those duplicates. We would also like to
filter this data to create a table that has the
minimum value of pressure for each individual storm. Each storm is
uniquely identified by the season, basin, and name. It's possible that names are
reused in basins or seasons. So by identifying each unique storm, we can keep only the first row
within each storm, the one that has the minimum pressure,
and output that information to a new table. We can use PROC SORT to
accomplish both tasks.*/
proc sort data = pg1.storm_detail out = storm_clean nodupkey dupout = storm_dups;
	BY _ALL_;
run; 

/* Now want to capture the minimum pressure */
proc sort data = pg1.storm_detail out = min_pressure;
	where Pressure is not missing and Name is not missing;
	by descending Season Basin Name Pressure;
run;

proc sort data = min_pressure nodupkey;
	by descending Season Basin Name;
run;

proc print data = min_pressure(obs=10);
run;

/* Data step used to manipulate and process data */
data myclass;
	set sashelp.class;
	WHERE Age >= 15;
	DROP Sex;
	FORMAT Height 4.1
		   Weight 3.; 
run;

proc print data = myclass;
run;

%let outputPath=C:/Users/SAS Courses/EPG1V2/output;
libname out "&outputPath";

data out.fox;
	set pg1.np_species;
	where Category = "Mammal" and Common_Names like "%Fox%";
	Drop Category Record_Status Occurrence Nativeness;
run;

proc sort data = out.fox out = sorted;
	BY Common_Names;
	where Common_names not like '%Squirrel%';
run;

proc print data = sorted;
run;

/* Using expressions to create new columns (Feature Engineering) */
data cars_new;
	set sashelp.cars;
	where Origin ne "USA";
	Profit = MSRP - Invoice;
	Source = "Non-US Cars";
	FORMAT Profit dollar10.;
	KEEP Make Model MSRP Invoice Profit Source;
run;

proc print data = cars_new;
run;

PROC SQL;
	SELECT Make, SUM(Profit) format dollar10. as tot_profit
	from cars_new
	GROUP BY Make
	ORDER BY tot_profit desc;

data wind;
	SET pg1.storm_range;
	WindAvg = MEAN(wind1, wind2, wind3, wind4);
	WindRange = RANGE(wind1-4);
run;

proc print data = wind(obs=10);
run;

/*Character functions */
data storm_new;
	set pg1.storm_summary;
	drop Type Hem_EW Hem_NS MinPressure Lat Lon Ocean;
	Basin = upcase(Basin);
	Name = propcase(Name);
	Hemisphere = cats(Hem_NS, Hem_EW);
	Ocean = substr(Basin, 2, 1);
	if Ocean = "A" THEN Ocean_Name = "Atlantic";
	ELSE IF Ocean = "I" THEN Ocean_Name = "Indian";
	ELSE Ocean_Name = "Pacific";
run;

proc print data = storm_new(obs=10);
run; 

/* Date Functions */
data storm_new;
	set pg1.storm_damage;
	yearPassed = yrdif(Date, today(), "age");
	Anniversary = mdy(month(Date), day(Date), year(today()));
	format yearPassed 4.1 Date Anniversary ddmmyy10.;
run;

proc print data = storm_new(obs=10);
run;

/* data processing using if-then do statement */
data indian atlantic pacific;
	set pg1.storm_summary;
	length Ocean $8;
	keep Basin Season Name MaxWindMPH Ocean;
	Basin = upcase(Basin);
	Name = propcase(Name);
	OceanCode = substr(Basin, 2, 1);
	if OceanCode = "I" then do;
		Ocean = "Indian";
		output indian;
	end; 
	else if OceanCode = "A" then do;
		Ocean = "Atlantic";
		output atlantic;
	end; 
	else do;
		Ocean = "Pacific";
		output pacific;
	end;
run;

/* print one of the above data sets */
proc print data = indian(obs=10);
run;

/* Segmenting reports */
proc sort data = sashelp.cars out = cars_sort;
	by Origin;
run;

proc freq data = cars_sort;
	by Origin;
	tables Type;
run;

/* SAS reports, labels, by statements, sorting before splitting the report by category (BasinNmae for this example */
proc sort data = pg1.Storm_final out=storm_sort;
	by BasinName descending MaxWindMPH;
	WHERE MaxWindMPH > 156;
RUN; 

/* Generate the report using proc print */
title "Categpory 5 Storms";
proc print data = storm_sort label noobs;
	var Season Name MaxWindMPH MinPressure StartDate StormLength;
	by BasinName;
	label MaxWindMPH="Max Wind (MPH)"
		  MinPressure="Min Pressure"
		  StartDate="Start Date"
		  StormLength="Length of Storm";
run;

title;

/* Applying permanent labels to columns in the data step */
data cars_update;
	set sashelp.cars;
	KEEP Make Model MSRP AvgMPG;
	AvgMPG=mean(MPG_Highway, MPG_City);
	label MSRP="Manufacture Suggested Retail Price"
		  AvgMPG="Average Miles per Gallon";
run;

proc contents data = cars_update;
run;

/*Creating Freq Reports and graphs using the Freq proc*/
ods graphics on;
ods noproctitle;
title "Frequency Report for Basin and Storm Month";

proc freq data = pg1.storm_final order=freq nlevels;
	tables BasinName StartDate / nocum plot=freqplot(orient=horizontal scale=percent)
	format StartDate monname.;
	label BasinName="Basin"
		 StartDate="Month";
run;
title;
ods proctitle;

proc freq data = pg1.storm_final order=freq nlevels noprint;
	tables BasinName StartDate / nocum out=storm_count;
	format StartDate monname.;
run;

proc print data = storm_count;
run;

proc freq data = pg1.storm_final;
	tables BasinName*StartDate / nocol norow nopercent;
	format StartDate monname.;
run;

/* OR */
proc freq data = pg1.storm_final;
	tables BasinName*StartDate / crosslist;
	format StartDate monname.;
run;

/* OR */
proc freq data = pg1.storm_final;
	tables BasinName*StartDate / list;
	format StartDate monname.;
run;

/* OR */
proc freq data = pg1.storm_final noprint;
	tables BasinName*StartDate / out=stormcounts;
	format StartDate monname.;
run;
proc sort data = stormcounts out=counts_sort;
	by descending Count;
run;
/*Print the results of stormcounts*/
proc print data=counts_sort;
run;

/*Creating summary reports*/
proc means data=pg1.storm_final mean median min max maxdec=0;
	var MaxWindMPH;
	CLASS BasinName StormType;
	ways 0 1 2;
run;

%let outpath=C:\Users\SAS Courses;
proc export data=sashelp.cars
	 outfile="&outpath\cars.csv"
	 dbms=csv replace;
run;

libname xlout xlsx "&outpath/southpacific.xlsx";

data xlout.South_Pacific;
	set pg1.storm_final;
	where Basin="SP";
RUN;

PROC means data=xlout.South_Pacific noprint maxdec=1;
	VAR MaxWindKM;
	class Season;
	ways 1;
	output out=xlout.Season_Stats n=Count mean=AvgMaxWindKM max=StrongestWindKM;
run;

libname xlout clear;

/*Check the styles*/
proc template;
	list styles;
run;
/*Output Delivery System*/
ods excel file="&outpath/wind.xlsx" style=sasdocprinter options(sheet_name="Wind Stats");
title "Wind Statistics by Basin";
ods noproctitle;
proc means data=pg1.storm_final min mean median max maxdec=0;
	class Basin;
	var MaxWindMPH;
run;

ods excel options(sheet_name="Wind Distribution");
title "Distribution of Maximum Wind";
proc sgplot data=pg1.storm_final;
	histogram MaxWindMPH;
	density MaxWindMPH;
run;

title;
ods proctitle;
ods excel close;

/*pdf*/
ods pdf file="&outpath/wind.pdf" startpage=no style=journal pdftoc=1;
ods noproctitle;
ods proclabel "Wind Statistics";
title "Wind Statistics by Basin";

proc means data=pg1.storm_final min mean median max maxdec=0;
	class Basin;
	var MaxWindMPH;
run;

ods proclabel "Wind Distribution";
proc sgplot data=pg1.storm_final;
	histogram MaxWindMPH;
	density MaxWindMPH;
run;

title;
ods proctitle;
ods pdf close;	
