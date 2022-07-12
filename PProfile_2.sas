********************************************************************************************************
* This program creates a lab analyte summary using PROC DOCUMENT and ODS Layout *
********************************************************************************************************;
OPTIONS ORIENTATION=LANDSCAPE TOPMARGIN=0.75 BOTTOMMARGIN=0.75 LEFTMARGIN=0.75 RIGHTMARGIN=0.75;
options nonumber nodate nocenter;
ods document name=lab(write);
********************************************************************************************************
* This code creates a data set of lab values that is used for the lab summary. Patient info, values, *
* and treatments are randomly created. Descriptive statistics are output using proc means. *
********************************************************************************************************;
data lab;
seed=40832209;
test='Leukocyte Count (WBC)';
units='10^9/L';
do i=1 to 1000;
result=normal(seed)*1.5+6.5; output;
end;
run;

data lab;
set lab;
if mod(_n_,2)=1 then visit='Baseline';
else visit='Final ';
patient=put(int((_n_-1)/2)+1,z4.);
*** normal range 3.2 to 9.8 ***;
if result<3.2 then flag='L';
if result>9.8 then flag='H';
resultc=put(result,4.1)||' '||flag;
run;

proc sort;
by patient;
run;

data patient(keep=patient treatmnt invest);
length treatmnt $7;
set lab;
by patient;
if first.patient;
invest=put(int(_n_/100)+1,z4.);
if ranuni(seed)>.5 then treatmnt='PLACEBO';
else treatmnt='ACTIVE';
run;


data patient;
set patient end=eof;

if _n_=1 then do; 
count1=1; 
count2=1; 
end;
else do;
if treatmnt='ACTIVE' then count1=count1+1;
if treatmnt='PLACEBO' then count2=count2+1;
end;

retain count1 count2;
if eof then call symput('Active',count1);
if eof then call symput('Placebo',count2);
drop count1 count2;
run;


data lab;
merge lab patient;
by patient;
run;

title;
proc means data=lab maxdec=2 fw=7;
class treatmnt visit;
var result;
run;
********************************************************************************************************
* This code creates a plot of baseline values vs end study values using proc gplot *
********************************************************************************************************;
data baseline(rename=(result=baseline flag=baseline_f)) final(rename=(result=final flag=final_f));
set lab;
by patient;
if visit='Baseline' then output baseline;
else output final;
baseline=result;
keep patient result treatmnt flag;
run;


data forgraph;
merge baseline final;
by patient;
run;

symbol1 h=1 v=dot c=black;
symbol2 h=1 v=circle c=black;
proc gplot;
plot final*baseline=treatmnt;
run;
********************************************************************************************************
* This code creates a shift table using two proc freqs. *
********************************************************************************************************;
data shift;
set forgraph(drop=baseline final);
if baseline_f=' ' then baseline=2;
else if baseline_f='L' then baseline=1;
else baseline=3;
if final_f=' ' then final=2;
else if final_f='L' then final=1;
else final=3;
run;
proc format;
value shift 3='High' 1='Low' 2='Normal';
run;
proc freq data=shift order=internal;
where treatmnt='ACTIVE';
format baseline final shift.;
tables baseline*final / norow nocol nopercent sparse;
run;
proc freq data=shift order=internal;
where treatmnt='PLACEBO';
format baseline final shift.;
tables baseline*final / norow nocol nopercent sparse;
run;
ods document close;
proc document name=lab;
list/levels=all;
run;
quit;
ods printer postscript file="C:\lab.ps";
**************************************************
* This Uses ODS Layout with absolute referencing *
**************************************************;
ods layout start;
proc document name=lab;
dir \Means#1; run;
ods region x=0% y=0% width=50% height=50%;
replay Summary#1; run;
dir \Gplot#1; run;
ods region x=50% y=0% width=50% height=50%;
replay Gplot#1; run;
dir \Freq#1\Table1#1; run;
ods region x=0% y=50% width=50% height=50%;
replay CrossTabFreqs#1; run;
dir \Freq#2\Table1#1; run;
ods region x=50% y=50% width=50% height=50%;
replay CrossTabFreqs#1; run;
quit;
ods layout end;
ods printer close;