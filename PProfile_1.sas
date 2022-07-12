********************************************************************************************************
* This program creates a patient profile using PROC DOCUMENT and ODS Layout *
********************************************************************************************************;
OPTIONS ORIENTATION=PORTRAIT TOPMARGIN=0.5 BOTTOMMARGIN=0.5 LEFTMARGIN=0.5 RIGHTMARGIN=0.5;
options nonumber nodate nocenter;
ods document name=profile(write);
****************************************
* This creates a block of demog info. *
****************************************;
data demog;
patient=1001; initials='SAS'; ht=75; wt=190; race='Caucasian'; gender='Male';
age=34; treatmnt='Placebo'; firstdos='01Apr2001'd; lastdose='21Apr2001'd; complete='Yes';
withdraw='N/A';
format firstdos lastdose date9.;
length text $50 resp $50;
text='Patient Number: '; resp=Patient; output;
text='Patient Initials: '; resp=Initials; output;
text='Gender: '; resp=gender; output;
text='Race: '; resp=race; output;
text='Age: '; resp=age; output;
text='Height (in): '; resp=ht; output;
text='Weight (lbs): '; resp=wt; output;
text='Treatment: '; resp=Treatmnt; output;
text='First Dose Date: '; resp=put( firstdos, date9.); output;
text='Last Dose Date: '; resp=put( lastdose, date9.); output;
text='Completed Study? '; resp=complete; output;
text='Withdrawal Reason: '; resp=withdraw; output;
label text='00'x resp='00'x;
keep text resp;
run;
title;
proc print data=demog noobs label; var text resp; run;
***********************************************
* This creates a block of physical exam info. *
***********************************************;
data ph_exam;
body='CARDIOVASCULAR '; screen='NORMAL '; final='NORMAL '; OUTPUT;
body='ENDOCRINE '; screen='NORMAL '; final='NORMAL '; OUTPUT;
body='GASTROINTESTINAL '; screen='NORMAL '; final='NORMAL '; OUTPUT;
body='GENITOURINARY '; screen='NORMAL '; final='NORMAL '; OUTPUT;
body='HEENT '; screen='ABNORMAL'; final='NORMAL '; OUTPUT;
body='LYMPHATIC '; screen='NORMAL '; final='NORMAL '; OUTPUT;
body='MUSCULOSKELETAL '; screen='NORMAL '; final='NORMAL '; OUTPUT;
body='NEUROLOGICAL '; screen='ABNORMAL'; final='NORMAL '; OUTPUT;
body='OTHER '; screen='NORMAL '; final='NORMAL '; OUTPUT;
body='RESPIRATORY '; screen='NORMAL '; final='NORMAL '; OUTPUT;
body='SKIN '; screen='NORMAL '; final='NORMAL '; OUTPUT;
LABEL BODY='Body System' SCREEN='Screening' final='End_Study';
RUN;
PROC PRINT DATA=PH_EXAM NOOBS LABEL; VAR BODY SCREEN FINAL; RUN;
****************************************
* This creates a block of ae info. *
****************************************;
data adverse;
FORMAT START STOP DATE9.;
ae='HEADACHE '; START='04APR2004'D; STOP='04APR2004'D; CAUSE='RELATED ';
SEVERIT='MILD '; SERIOUS='NO '; ACTION='CON MED'; OUTCOME='RECOVERED'; OUTPUT;
ae='FEVER '; START='04APR2004'D; STOP='04APR2004'D; CAUSE='RELATED ';
SEVERIT='MILD '; SERIOUS='NO '; ACTION='CON MED'; OUTCOME='RECOVERED'; OUTPUT;
ae='FATIGUE '; START='04APR2004'D; STOP='04APR2004'D; CAUSE='RELATED ';
SEVERIT='MILD '; SERIOUS='NO '; ACTION='NONE '; OUTCOME='RECOVERED'; OUTPUT;
ae='NAUSEA '; START='04APR2004'D; STOP='04APR2004'D; CAUSE='RELATED ';
SEVERIT='MODERATE'; SERIOUS='NO '; ACTION='CON MED'; OUTCOME='RECOVERED'; OUTPUT;
LABEL AE='Adverse Event' START='Start Date' STOP='Stop Date' SEVERIT='Severity' CAUSE='Causality'
ACTION='Action Taken' OUTCOME='Outcome' SERIOUS='Serious';
RUN;
PROC PRINT DATA=ADVERSE LABEL NOOBS; VAR AE START STOP SEVERIT CAUSE ACTION OUTCOME; RUN;
****************************************
* This creates a block of vitals info. *
****************************************;
DATA VITALS;
FORMAT DATE DATE9.;
VISIT='VISIT 1'; DATE='15MAR2004'D; HR='64'; BP='114/ 70'; OUTPUT;
VISIT='VISIT 2'; DATE='01APR2004'D; HR='78'; BP='118/ 70'; OUTPUT;
VISIT='VISIT 3'; DATE='08APR2004'D; HR='82'; BP='116/ 70'; OUTPUT;
VISIT='VISIT 4'; DATE='15APR2004'D; HR='76'; BP='122/ 80'; OUTPUT;
LABEL VISIT='Visit' BP='Blood Pressure' HR='Heart Rate' DATE='Date';
RUN;
PROC PRINT DATA=VITALS NOOBS LABEL SPLIT='|'; VAR VISIT HR BP; RUN;
******************************************
* This creates a block of efficacy info. *
******************************************;
DATA EFFICACY;
FORMAT DATE DATE9.;
VISIT='VISIT 1'; DATE='15MAR2004'D;
SCORE1=PUT(INT(RANUNI(DATE)*4)+1,2.); SCORE2=PUT(INT(RANUNI(DATE)*4)+1,2.);
SCORE3=PUT(INT(RANUNI(DATE)*4)+1,2.); TOTAL=PUT(SCORE1+SCORE2+SCORE3,2.); OUTPUT;
VISIT='VISIT 2'; DATE='01APR2004'D;
SCORE1=PUT(INT(RANUNI(DATE)*4)+1,2.); SCORE2=PUT(INT(RANUNI(DATE)*4)+1,2.);
SCORE3=PUT(INT(RANUNI(DATE)*4)+1,2.); TOTAL=PUT(SCORE1+SCORE2+SCORE3,2.); OUTPUT;
VISIT='VISIT 3'; DATE='08APR2004'D;
SCORE1=PUT(INT(RANUNI(DATE)*4)+1,2.); SCORE2=PUT(INT(RANUNI(DATE)*4)+1,2.);
SCORE3=PUT(INT(RANUNI(DATE)*4)+1,2.); TOTAL=PUT(SCORE1+SCORE2+SCORE3,2.); OUTPUT;
VISIT='VISIT 4'; DATE='15APR2004'D;
SCORE1=PUT(INT(RANUNI(DATE)*4)+1,2.); SCORE2=PUT(INT(RANUNI(DATE)*4)+1,2.);
SCORE3=PUT(INT(RANUNI(DATE)*4)+1,2.); TOTAL=PUT(SCORE1+SCORE2+SCORE3,2.); OUTPUT;
LABEL VISIT='Visit' DATE='Date' SCORE1='Score 1' SCORE2='Score 2' SCORE3='Score 3' TOTAL='Total';
RUN;
PROC PRINT DATA=EFFICACY LABEL NOOBS; VAR VISIT DATE SCORE1 SCORE2 SCORE3 TOTAL; RUN;
******************************************
* This creates a block of con meds info. *
******************************************;
data conmed;
FORMAT START STOP DATE9.;
conmed='TYLENOL PM '; START='04APR2004'D; STOP='04APR2004'D; CONT='NO '; DOSE='500 MG QID PO ';
INDICAT='HEADACHE/FEVER '; OUTPUT;
conmed='ZANTAC '; START='04APR2004'D; STOP='04APR2004'D; CONT='NO '; DOSE='75 MG PRN PO ';
INDICAT='NAUSEA '; OUTPUT;
conmed='BENADRYL '; START='10APR2004'D; STOP='20APR2004'D; CONT='NO '; DOSE='CREAM PRN TOPICALLY';
INDICAT='RASH '; OUTPUT;
LABEL CONMED='Concomitant Medication' START='Start Date' STOP='Stop Date' CONT='Continue'
DOSE='Dose/Units/ Frequency/Route' INDICAT='Indication';
run;
PROC PRINT DATA=CONMED LABEL NOOBS SPLIT='|'; VAR CONMED START STOP CONT DOSE INDICAT; RUN;
ods document close;


proc document name=profile; run;
list/levels=all;
run; 
quit;

ods pdf file="C:\profile.pdf";
ods layout start rows=4 columns=2;
proc document name=profile;
dir \Print#1; run;
ods region row=1 column=1;
replay Print#1;
dir \Print#2; run;
ods region row=1 column=2;
replay Print#1;
dir \Print#3; run;
ods region row=2 column=1 column_span=2;
replay Print#1;
dir \Print#4; run;
ods region row=3 column=1;
replay Print#1;
dir \Print#5; run;
ods region row=3 column=2;
replay Print#1;
dir \Print#6; run;
ods region row=4 column=1 column_span=2;
replay Print#1;
quit;
ods layout end;
ods pdf close;