* Import data;

proc import out = hf
	datafile = "/home/u63827850/Survival_8108/data/heartfailure.csv"
	dbms = csv replace;
	getnames = yes;
run;

proc contents data = hf;
run;

data hf;
	set hf;
	if Anaemia = 0 then Anaemia_status ='No Anaemia';
	else if Anaemia = 1 then Anaemia_status = 'Anaemia';
	if high_blood_pressure = 0 then HBP = 'No Hypertension';
	else if high_blood_pressure = 1 then HBP = 'Hypertension';
	if death_event = 0 then Event = 'Censor';
	else if death_event = 1 then Event  = 'Death';
	if smoking = 0 then smoking_status = 'No Smoke';
	else smoking_status = 'Smoke';
	if sex = 0 the Gender = 'Female';
	else Gender = 'Male';
	if Diabetes = 0 then Diabetes_status = 'No Diabetes';
	else Diabetes_status = 'Diabetes';
	if  30 < ejection_fraction <= 45 then EFCAT = 'Median';
	else if ejection_fraction <= 30 then EFCAT = 'Low';
	else EFCAT = 'High' ;
run;

********************************************************************************************************************
**********************************    1204      *******************************************************************
********************************************************************************************************************
* Descriptive statistics for continuous variable;

data continous;
	set hf; 
	keep event age creatinine_phosphokinase platelets serum_sodium serum_creatinine time;
run;
	

proc tabulate data = continous;
	class event;
	var age creatinine_phosphokinase  platelets serum_sodium serum_creatinine time;
    table (age creatinine_phosphokinase platelets serum_sodium serum_creatinine time)*(mean std min median max),
    (event all) / box='Descriptive Statistics for Continuous Vairables' misstext='N/A';
run;

* Descriptive statistics for category variable;

data category;
	set hf; 
	keep event Gender Anaemia_status HBP smoking_status Diabetes_status EFCAT;
run;

proc tabulate data = category;
	class event Gender Anaemia_status HBP smoking_status Diabetes_status EFCAT;
    table (Gender  Anaemia_status  HBP  smoking_status  Diabetes_status   EFCAT )*(n PCTN),
    (event all = 'Total') / box='Descriptive Statistics for Category Vairables' misstext='N/A';
    keylabel n = 'N' pctn='Percent';
run;

* histogram and density plot for continuous variables;

proc sgplot data = continous;
	histogram age / scale = count binwidth=1.5 showbins;
    density age / type = kernel;
    xaxis label = 'Age';
run;

proc sgplot data = continous;
	histogram creatinine_phosphokinase / scale = count binwidth=200 showbins;
    density creatinine_phosphokinase / type = kernel;
    xaxis label = 'Creatinine Phosphokinase';
run;

proc sgplot data = continous;
	histogram platelets / scale = count binwidth=15000 showbins;
    density platelets / type = kernel;
    xaxis label = 'Platelets';
run;

proc sgplot data = continous;
	histogram serum_sodium / scale = count binwidth=1 showbins;
    density serum_sodium / type = kernel;
    xaxis label = 'Serum Sodium';
run;

proc sgplot data = continous;
	histogram serum_creatinine / scale = count binwidth=0.2 showbins;
    density serum_creatinine / type = kernel;
    xaxis label = 'Serum Creatinine';
run;

proc sgplot data = continous;
	histogram time / scale = count binwidth=8 showbins;
    density time / type = kernel;
    xaxis label = 'Time';
run;

* bar plot for category variables;
proc sgplot data = category;
	vbar event / datalabel barwidth=0.3;
	xaxis label = 'Event';
	yaxis label = 'Count';
run;

proc sgplot data = category;
	vbar Gender / datalabel barwidth=0.3;
	xaxis label = 'Gender';
	yaxis label = 'Count';
run;

proc sgplot data = category;
	vbar smoking_status / datalabel barwidth=0.3;
	xaxis label = 'Smoking Status';
	yaxis label = 'Count';
run;

proc sgplot data = category;
	vbar Anaemia_status / datalabel barwidth=0.3;
	xaxis label = 'Anaemia Status';
	yaxis label = 'Count';
run;

proc sgplot data = category;
	vbar HBP / datalabel barwidth=0.3;
	xaxis label = 'High Blood Pressure';
	yaxis label = 'Count';
run;

proc sgplot data = category;
	vbar Diabetes_status / datalabel barwidth=0.3;
	xaxis label = 'Diabetes status';
	yaxis label = 'Count';
run;

proc sgplot data = category;
	vbar EFCAT / datalabel barwidth=0.3;
	xaxis label = 'Ejection Fraction';
	yaxis label = 'Count';
run;

*****************************************Non-parametric Survival Estimate***********************************************;
* First create dataset in this part, we only need time and event;

data time_event;
	set hf (keep=time death_event);
run;

***************** life table;
proc lifetest data=time_event outsurv=survres intervals=0 to 300 by 30 method=act;
  time time*death_event(0);
run;
* estimated hazard function at the midpoint ;
proc print data=survres; run;

* plot;
symbol1 i=stepjl;
proc gplot data=survres;
    plot HAZARD*MIDPOINT / vaxis=0 to 0.005 by 0.001 haxis=0 to 300 by 30;
    title1 ’Hazard Rates vs Midpoint’;
run;


***************** Kaplan-Meier Curve

** ODS Graphics for KM survival plot **;
ods trace on;
proc lifetest data=time_event method=KM alpha=0.05 plots=survival(cl);
  time time*death_event(0); 
  ods select SurvivalPlot;
  title 'Kaplan-Meier Survival Curve';
run;
ods trace off;

***************** Fleming−Harrington Survival Curve;
ods trace on;
proc lifetest data=time_event method=FH alpha=0.05 plots=survival(cl);
  time time*death_event(0); 
  ods select Lifetest.Stratum1.SurvivalPlot;
  title 'Fleming−Harrington Survival Curve';
run;
ods trace off;

*****************  Log-Rank test and Wilcoxon test;
proc lifetest data=hf plots=survival(cl);
    time time*death_event(0);
    strata Anaemia_status/ test=logrank test=wilcoxon;       
run;

proc lifetest data=hf plots=survival(cl);
    time time*death_event(0); 
    strata HBP/ test=logrank test=wilcoxon;      
run;

ods trace on;
proc lifetest data=hf plots=survival(cl);
    time time*death_event(0); 
    strata EFCAT/ test=logrank test=wilcoxon;    
run;
ods trace off;













