**** PROGRAM 5.3;
**** INPUT SAMPLE DEMOGRAPHICS DATA AS CDISC ADaM ADSL;
data ADSL;
label USUBJID = "Unique Subject Identifier"
      TRTPN   = "Planned Treatment (N)"
      SEXN    = "Sex (N)"
      RACEN   = "Race (N)"
      AGE     = "Age";
input USUBJID $ TRTPN SEXN RACEN AGE @@;
datalines;
101 0 1 3 37  301 0 1 1 70  501 0 1 2 33  601 0 1 1 50  701 1 1 1 60
102 1 2 1 65  302 0 1 2 55  502 1 2 1 44  602 0 2 2 30  702 0 1 1 28
103 1 1 2 32  303 1 1 1 65  503 1 1 1 64  603 1 2 1 33  703 1 1 2 44
104 0 2 1 23  304 0 1 1 45  504 0 1 3 56  604 0 1 1 65  704 0 2 1 66
105 1 1 3 44  305 1 1 1 36  505 1 1 2 73  605 1 2 1 57  705 1 1 2 46
106 0 2 1 49  306 0 1 2 46  506 0 1 1 46  606 0 1 2 56  706 1 1 1 75
201 1 1 3 35  401 1 2 1 44  507 1 1 2 44  607 1 1 1 67  707 1 1 1 46
202 0 2 1 50  402 0 2 2 77  508 0 2 1 53  608 0 2 2 46  708 0 2 1 55
203 1 1 2 49  403 1 1 1 45  509 0 1 1 45  609 1 2 1 72  709 0 2 2 57
204 0 2 1 60  404 1 1 1 59  510 0 1 3 65  610 0 1 1 29  710 0 1 1 63
205 1 1 3 39  405 0 2 1 49  511 1 2 2 43  611 1 2 1 65  711 1 1 2 61
206 1 2 1 67  406 1 1 2 33  512 1 1 1 39  612 1 1 2 46  712 0 . 1 49
;
 
**** DEFINE VARIABLE FORMATS NEEDED FOR TABLE;
proc format;
   value trtpn
      1 = "Active"
      0 = "Placebo"; 
   value sexn
      . = "Missing"
      1 = "Male"
      2 = "Female";
   value racen
      1 = "White"
      2 = "Black"
      3 = "Other*";
run;

**** DUPLICATE THE INCOMING DATASET FOR OVERALL COLUMN CALCULATIONS SO
**** NOW TRT HAS VALUES 0 = PLACEBO, 1 = ACTIVE, AND 2 = OVERALL.;
data adsl;
   set adsl;
   output; /*Doubling the data to be suymmarised and assigning those data to trtpn-Create overall column*/
   trtpn = 2;
   output;
run;

**** AGE STATISTICS PROGRAMMING ************************************;
**** GET P VALUE FROM NON PARAMETRIC COMPARISON OF AGE MEANS.;
proc npar1way
data = adsl
wilcoxon /*age is not normally distributed. Wilcoxon signed rnak test is used to calculate the p-value and palced in data set called p-value*/
noprint;
where trtpn in (0,1);
class trtpn;
var age;
output out= pvalue wilcoxon;
run;

proc sort 
   data=adsl;
      by trtpn;
run;
 
***** GET AGE DESCRIPTIVE STATISTICS N, MEAN, STD, MIN, AND MAX.;
proc univariate
data = adsl noprint;
   by trtpn;
   
var age;
output out = age
n = _n  mean = _mean std = _std min =_min max = _max;
run;   

**** FORMAT AGE DESCRIPTIVE STATISTICS FOR THE TABLE.;

data age;
set age;
format n mean std min max $14.;
drop _:;

n = put(_n , 5.);
mean = put(_mean,7.1);
std = put(_std,8.2);
min = put(_min,7.1);
max = put(_max,7.1);
run;


**** TRANSPOSE AGE DESCRIPTIVE STATISTICS INTO COLUMNS.;
proc transpose
data = age
out= age
prefix = col;
   var n min std min max;
id trtpn;
run; 

**** CREATE AGE FIRST ROW FOR THE TABLE.;
data label;
  set pvalue(keep = p2_wil rename = (p2_wil = pvalue));
  length label $ 85;
  label = "#S={font_weight=bold} Age (years)"; /*Find formatting code for p-value*/
run;  

**** APPEND AGE DESCRIPTIVE STATISTICS TO AGE P VALUE ROW AND 
**** CREATE AGE DESCRIPTIVE STATISTIC ROW LABELS.;

data age;
   length label $ 85 col0 col1 col2 $ 25 ;
   set label age;

   keep label col0 col1 col2 pvalue ;
   if _n_ > 1 then 
      select;
         when(_NAME_ = 'n')    label = "#{nbspace 6}N"; /*FORMATTING PDF Commands*/
         when(_NAME_ = 'mean') label = "#{nbspace 6}Mean";
         when(_NAME_ = 'std')  label = "#{nbspace 6}Standard Deviation";
         when(_NAME_ = 'min')  label = "#{nbspace 6}Minimum";
         when(_NAME_ = 'max')  label = "#{nbspace 6}Maximum";
         otherwise;
      end;
run;
**** END OF AGE STATISTICS PROGRAMMING *****************************;

 
**** SEX STATISTICS PROGRAMMING ************************************;
**** GET SIMPLE FREQUENCY COUNTS FOR SEX.;

proc freq
data = adsl
noprint;
where trtpn ne .;
tables trtpn * sexn / missing outpct out = sexn;
run;
 
**** FORMAT SEX N(%) AS DESIRED.;
data sexn;
   set sexn;
      where sexn ne .;
      length value $25;
      value = put(count,4.) || ' (' || put(pct_row,5.1)||'%)';
run;

proc sort
   data = sexn;
      by sexn;
run;
 
**** TRANSPOSE THE SEX SUMMARY STATISTICS.;
proc transpose
data = sexn
out= sexn (drop = _name_)
prefix = col;
  by sexn;
  var value;
  id trtpn;
run;  

**** PERFORM A CHI-SQUARE TEST ON SEX COMPARING ACTIVE VS PLACEBO.;

proc freq 
   data = adsl 
   noprint;
      where sexn ne . and trtpn not in (.,2);
      table sexn * trtpn / chisq;
      output out = pvalue pchi;
run;

**** CREATE SEX FIRST ROW FOR THE TABLE.;
data label;
	set pvalue(keep = p_pchi rename = (p_pchi = pvalue));
	length label $ 85;
	label = "#S={font_weight=bold} Sex";
run;

**** APPEND SEX DESCRIPTIVE STATISTICS TO SEX P VALUE ROW AND 
**** CREATE SEX DESCRIPTIVE STATISTIC ROW LABELS.; 
data sexn;
   length label $ 85 col0 col1 col2 $ 25 ;
   set label sexn;

   keep label col0 col1 col2 pvalue ;
   if _n_ > 1 then 
        label= "#{nbspace 6}" || put(sexn,sexn.);
run;
**** END OF SEX STATISTICS PROGRAMMING *****************************;

**** RACE STATISTICS PROGRAMMING ***********************************;
**** GET SIMPLE FREQUENCY COUNTS FOR RACE;
proc freq 
   data = adsl 
   noprint;
      where trtpn ne .; 
      tables trtpn * racen / missing outpct out = racen;
run;
 
**** FORMAT RACE N(%) AS DESIRED;
data racen;
   set racen;
      where racen ne .;
      length value $25;
      value = put(count,4.) || ' (' || put(pct_row,5.1)||'%)';
run;

proc sort
   data = racen;
      by racen;
run;
 
**** TRANSPOSE THE RACE SUMMARY STATISTICS;
proc transpose 
   data = racen 
   out = racen(drop = _name_) 
   prefix=col;
      by racen;
      var value;
      id trtpn;
run;
 
**** PERFORM A FISHER'S EXACT TEST ON RACE COMPARING ACTIVE VS PLACEBO.;
proc freq 
   data = adsl 
   noprint;
      where racen ne . and trtpn not in (.,2);
      table racen * trtpn / exact; /*if there are nonrandom associations between two categorical variables (Treatment and Race)*/
      output out = pvalue exact;
run;
 
**** CREATE RACE FIRST ROW FOR THE TABLE.;
data label;
	set pvalue(keep = xp2_fish rename = (xp2_fish = pvalue));
	length label $ 85;
	label = "#S={font_weight=bold} Race";
run;

**** APPEND RACE DESCRIPTIVE STATISTICS TO RACE P VALUE ROW AND 
**** CREATE RACE DESCRIPTIVE STATISTIC ROW LABELS.; 
data racen;
   length label $ 85 col0 col1 col2 $ 25 ;
   set label racen;

   keep label col0 col1 col2 pvalue ;
   if _n_ > 1 then 
        label= "#{nbspace 6}" || put(racen,racen.);
run;
**** END OF RACE STATISTICS PROGRAMMING *******************************;


**** CONCATENATE AGE, SEX, AND RACE STATISTICS AND CREATE GROUPING
**** GROUP VARIABLE FOR LINE SKIPPING IN PROC REPORT.;
data forreport;
   set age(in = in1)
       sexn(in = in2)
       racen(in = in3);

       group = sum(in1 * 1, in2 * 2, in3 * 3);
run;


**** DEFINE THREE MACRO VARIABLES &N0, &N1, AND &NT THAT ARE USED IN 
**** THE COLUMN HEADERS FOR "PLACEBO," "ACTIVE" AND "OVERALL" THERAPY 
**** GROUPS.;
data _null_;
   set adsl end=eof;

   **** CREATE COUNTER FOR N0 = PLACEBO, N1 = ACTIVE.;
   if trtpn = 0 then
      n0 + 1;
   else if trtpn = 1 then
      n1 + 1;

   **** CREATE OVERALL COUNTER NT.; 
   nt + 1;
  
   **** CREATE MACRO VARIABLES &N0, &N1, AND &NT.;
   if eof then
      do;     
         call symput("n0",compress('(N='||put(n0,4.) || ')'));
         call symput("n1",compress('(N='||put(n1,4.) || ')'));
         call symput("nt",compress('(N='||put(nt,4.) || ')'));
      end;
run;


**** USE PROC REPORT TO WRITE THE DEMOGRAPHICS TABLE TO FILE.; 
options nodate nonumber missing = ' ';
ods escapechar='#';
ods pdf style=htmlblue file='/home/smccawille1/Output/ADSL.pdf';

proc report
   data=forreport
   nowindows
   spacing=1
   headline
   headskip
   split = "|";

   columns (group label col1 col0 col2 pvalue);

   define group   /order order = internal noprint;
   define label   /display " ";
   define col0    /display style(column)=[asis=on] "Placebo|&n0";
   define col1    /display style(column)=[asis=on] "Active|&n1";
   define col2    /display style(column)=[asis=on] "Overall|&nt";
   define pvalue  /display center " |P-value**" f = pvalue5.2;

   compute after group;
      line '#{newline}';
   endcomp;

   title1 j=l 'Company/Trial Name' 
          j=r 'Page #{thispage} of #{lastpage}';
   title2 j=c 'Table 5.3';
   title3 j=c 'Demographics and Baseline Characteristics';

   footnote1 j=l '* Other includes Asian, Native American, and other'
                 ' races.';
   footnote2 j=l "** P-values:  Age = Wilcoxon rank-sum, Sex = Pearson's"  
                 " chi-square, Race = Fisher's exact test.";
   footnote3 j=l "Created by %sysfunc(getoption(sysin)) on &sysdate9..";  
run; 
ods pdf close;   