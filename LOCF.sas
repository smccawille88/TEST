**** PROGRAM 4.1;
**** INPUT SAMPLE CHOLESTEROL DATA AS SDTM LB DOMAIN.;
data LB;
label USUBJID  = 'Unique Subject Identifier'
      LBDTC    = 'Date/Time of Specimen Collection'
      LBTESTCD = 'Lab Test or Examination Short Name'
      LBSTRESN = 'Numeric Result/Finding in Standard Units';
input USUBJID $ 1-3 LBDTC $ 5-14 LBTESTCD $ LBSTRESN; 
datalines;
101 2003-09-05 HDL  48
101 2003-09-05 LDL  188
101 2003-09-05 TRIG 108
101 2003-09-06 HDL  49
101 2003-09-06 LDL  185
101 2003-09-06 TRIG .
102 2003-10-01 HDL  54
102 2003-10-01 LDL  200
102 2003-10-01 TRIG 350
102 2003-10-02 HDL  52
102 2003-10-02 LDL  .
102 2003-10-02 TRIG 360
103 2003-11-10 HDL  .
103 2003-11-10 LDL  240
103 2003-11-10 TRIG 900
103 2003-11-11 HDL  30
103 2003-11-11 LDL  .
103 2003-11-11 TRIG 880
103 2003-11-12 HDL  32
103 2003-11-12 LDL  .
103 2003-11-12 TRIG .
103 2003-11-13 HDL  35
103 2003-11-13 LDL  289
103 2003-11-13 TRIG 930
; 
run;

**** INPUT SAMPLE PILL DOSING DATA AS SDTM EX DOMAIN.;
data EX;
label USUBJID  = 'Unique Subject Identifier'
      EXSTDTC  = 'Start Date/Time of Treatment';
input USUBJID $ 1-3 EXSTDTC $ 5-14; 
datalines;
101 2003-09-07
102 2003-10-07
103 2003-11-13
;
run;

**** JOIN CHOLESTEROL AND DOSING DATA INTO ADLB ANALYSIS DATASET
**** AND CREATE WINDOWING VARIABLES;
proc sql;
    create table ADLB as
    select LB.USUBJID, LBDTC, LBTESTCD as PARAMCD, LBSTRESN as AVAL, 
           EXSTDTC, input(LBDTC,yymmdd10.) as ADT format=yymmdd10.,
           case
             when -5 <= (input(LBDTC,yymmdd10.) - input(EXSTDTC,yymmdd10.)) <= -1 and LBSTRESN ne . then 'YES'
             else 'NO'
           end as within5days
	from LB as LB, EX as EX
	where LB.USUBJID = EX.USUBJID
	order by USUBJID, LBTESTCD, within5days, ADT;
quit;

**** DEFINE ABLFL BASELINE FLAG;
data ADLB;
    set ADLB;
        by USUBJID PARAMCD within5days ADT;

        **** FLAG LAST RECORD WITHIN WINDOW AS BASELINE RECORD;
        if last.within5days and within5days='YES' then
            ABLFL = 'Y';

        label ABLFL    = 'Baseline Record Flag'
              PARAMCD  = 'Parameter Code'
              ADT      = 'Analysis Date'
              AVAL     = 'Analysis Value';

        drop within5days;
run;

proc sort
    data=ADLB;
        by USUBJID PARAMCD ADT;
run;

ods html image_dpi=300 style=htmlblue file='LOCF.html';
proc print data=adlb;
var usubjid paramcd aval adt exstdtc ablfl;
run;
ods html close;
