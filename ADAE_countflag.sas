/*Note commit this to main branch and then test alterantive ways of coding. 
 Hash objects/Proc sql outer union corresponding and then push to separate branch 
 and eventually compare using PROC Compare for possible discrepancies, 
 improvements with memory speed etc*/

**** PROGRAM 5.4;
**** INPUT TREATMENT CODE DATA AS ADAM ADSL DATA.;
data ADSL;
length USUBJID $ 3;
label USUBJID = "Unique Subject Identifier"
      TRTPN   = "Planned Treatment (N)";
input USUBJID $ TRTPN @@;
datalines;
101 1  102 0  103 0  104 1  105 0  106 0  107 1  108 1  109 0  110 1
111 0  112 0  113 0  114 1  115 0  116 1  117 0  118 1  119 1  120 1
121 1  122 0  123 1  124 0  125 1  126 1  127 0  128 1  129 1  130 1
131 1  132 0  133 1  134 0  135 1  136 1  137 0  138 1  139 1  140 1
141 1  142 0  143 1  144 0  145 1  146 1  147 0  148 1  149 1  150 1
151 1  152 0  153 1  154 0  155 1  156 1  157 0  158 1  159 1  160 1
161 1  162 0  163 1  164 0  165 1  166 1  167 0  168 1  169 1  170 1
;
run;



**** INPUT ADVERSE EVENT DATA AS SDTM AE DOMAIN.;
data AE;
label USUBJID     = "Unique Subject Identifier"
      AEBODSYS    = "Body System or Organ Class"
      AEDECOD     = "Dictionary-Derived Term"
      AEREL       = "Causality"
	  AESEV       = "Severity/Intensity";    
input USUBJID $ 1-3 AEBODSYS $ 5-30 AEDECOD $ 34-50 
      AEREL $ 52-67 AESEV $ 70-77;
datalines;
101 Cardiac disorders            Atrial flutter    NOT RELATED       MILD
101 Gastrointestinal disorders   Constipation      POSSIBLY RELATED  MILD
102 Cardiac disorders            Cardiac failure   POSSIBLY RELATED  MODERATE
102 Psychiatric disorders        Delirium          NOT RELATED       MILD
103 Cardiac disorders            Palpitations      NOT RELATED       MILD
103 Cardiac disorders            Palpitations      NOT RELATED       MODERATE
103 Cardiac disorders            Tachycardia       POSSIBLY RELATED  MODERATE
115 Gastrointestinal disorders   Abdominal pain    RELATED           MODERATE
115 Gastrointestinal disorders   Anal ulcer        RELATED           MILD
116 Gastrointestinal disorders   Constipation      POSSIBLY RELATED  MILD
117 Gastrointestinal disorders   Dyspepsia         POSSIBLY RELATED  MODERATE
118 Gastrointestinal disorders   Flatulence        RELATED           SEVERE
119 Gastrointestinal disorders   Hiatus hernia     NOT RELATED       SEVERE
130 Nervous system disorders     Convulsion        NOT RELATED       MILD
131 Nervous system disorders     Dizziness         POSSIBLY RELATED  MODERATE
132 Nervous system disorders     Essential tremor  NOT RELATED       MILD
135 Psychiatric disorders        Confusional state NOT RELATED       SEVERE
140 Psychiatric disorders        Delirium          NOT RELATED       MILD
140 Psychiatric disorders        Sleep disorder    POSSIBLY RELATED  MILD
141 Cardiac disorders            Palpitations      NOT RELATED       SEVERE
;
run;


**** CREATE ADAE ADAM DATASET TO MAKE HELPFUL COUNTING FLAGS FOR SUMMARIZATION.
**** THIS WOULD TYPICALLY BE DONE AS A SEPARATE PROGRAM OUTSIDE OF AN AE SUMMARY.;

proc sort data= adsl;
by usubjid;
run;


data adae;
merge ae(in=inae) adsl;
  by usubjid;
  
  if inae;
  
  select (aesev);
   when ('MILD') AESEVN = 1;
   when ('MODERATE') AESEVN = 2;
   when('SEVERE') AESEVN = 3;
   otherwise;
  end; 
  label aesevn = "Severity/Intensity (N)";
 run;  
 
 
 
 
proc sort data=adae out=adae;
    by usubjid aesevn;
run;

data adae;
set adae;
by usubjid aesevn;

if last.usubjid then aoccifl ='Y';

label aoccifl ="1st Max Sev./Int. Occurrence Flag";
run;

proc sort
  data=adae;
    by usubjid aebodsys aesevn;
run;

data adae;
  set adae;
    by usubjid aebodsys aesevn;

    if last.aebodsys then
      aoccsifl = 'Y';

    label aoccsifl = "1st Max Sev./Int. Occur Within SOC Flag";
run;

proc sort
  data=adae;
    by usubjid aedecod aesevn;
run;

data adae;
  set adae;
    by usubjid aedecod aesevn;

    if last.aedecod then
      aoccpifl = 'Y';

    label aoccpifl = "1st Max Sev./Int. Occur Within PT Flag";
run;

/*NOTE Repitive code processes here. Aim to create a dynamic macro that would automise this process*/

****PUT COUNTS OF TREATMENT POPULATION INTO MACRO VARIABLES*******;

proc sql noprint;
select count (unique usubjid) format = 3.
       into :n0 from adsl 
       where trtpn = 0;
select count (unique usubjid) format 3.
       into :n1 from adsl 
       where trtpn = 1;
select count (unique usubjid) format 3.
       into :n2 from adsl            
  ;
quit;


*****OUTPUT A SUMMARY TREATMENT SET OF RECORDS. TRTPN=2*********;
data adae;
set adae;
 output;
 trtpn=2;
 output;
run;

*****BY SEVERITY ONLY COUNTS*********;

proc sql noprint ;
create table All as
       select trtpn,
              sum(aoccifl = 'Y') as frequency from adae
       group by trtpn;
quit;   

proc sql noprint;
create table AllBySev as
       select aesev, trtpn,
              sum(aoccifl= 'Y') as frequency from adae
       group by aesev, trtpn;
 quit;
 


 
 *****BY BODY SYSTEM AND SEVERITY ONLY COUNTS*********;
 
proc sql noprint ;
create table AllBodysys as
       select trtpn, aebodsys,
              sum(aoccsifl = 'Y') as frequency from adae
       group by trtpn, aebodsys;
quit;   

proc sql noprint;
create table AllBodysysBysev as
       select aesev, trtpn,aebodsys,
              sum(aoccsifl= 'Y') as frequency from adae
       group by aesev, trtpn, aebodsys;
 quit;
 
 
 
 
 
  *****BY PREFERRED TERM AND SEVERITY COUNTS*********;
proc sql noprint;
create table AllPT as
       select trtpn, aebodsys,aedecod,
       sum(aoccpifl='Y') as frequency from adae
       group by trtpn, aebodsys, aedecod;
quit;
 
proc sql noprint;
create table ALLPTBySev as
       select aesev, trtpn, aebodsys, aedecod, 
       sum(aoccpifl='Y') as frequency from adae
 group by aesev,trtpn, aebodsys, aedecod;
quit;    




****PUT ALL COUNT TOGETHER*******;
data all;
set ALL(in=in1)
    AllBySev(in=in2)
    AllBodysys (in=in3)
    AllBodysysBysev(in=in4)
    AllPT(in=in5)
    AllPTBysev(in=in6);
    
 length description $ 40 sorter $ 200;
   if in1 then
      description = 'Any Event';
   else if in2 or in4 or in6 then
      description = '#{nbspace 6} ' || propcase(aesev);
   else if in3 then
      description =aebodsys;
   else if in5 then   
      description = '#{nbspace 3} ' || aedecod;
    
 sorter = aebodsys || aedecod || aesev;
 
 run;
 
 proc sort data= all;
 by sorter aebodsys aedecod description;
 run;
 
 ******TRANSPOSE THE FREQUENCY COUNTS******;
 
 proc transpose data= all
 out=flat
 prefix = count;
 by sorter aebodsys aedecod description;
 id trtpn;
 var frequency;
 run;
 
 
 proc sort
  data=flat;
  by aebodsys aedecod sorter;
run;

**** CREATE A SECTION BREAK VARIABLE AND FORMATTED COLUMNS;
data flat;
  set flat;
  by aebodsys aedecod sorter;

  retain section 1;

  length col0 col1 col2 $ 20;
  if count0 not in (.,0) then
    col0 = put(count0,3.) || " (" || put(count0/&n0*100,5.1) || "%)";
  if count1 not in (.,0) then
    col1 = put(count1,3.) || " (" || put(count1/&n1*100,5.1) || "%)";
  if count2 not in (.,0) then
    col2 = put(count2,3.) || " (" || put(count2/&n2*100,5.1) || "%)";
  
  if sum(count1,count2,count3)>0 then
    output;
  if last.aedecod then
    section + 1;
run;

**** USE PROC REPORT TO WRITE THE AE TABLE TO FILE.; 
options nodate nonumber missing = ' ';
ods escapechar='#';
ods pdf style=htmlblue file='program5.4.pdf';

proc report
   data=flat
   nowindows
   split = "|";

   columns section description col1 col0 col2;

   define section     /order order = internal noprint;
   define description /display style(header)=[just=left] 
   "Body System|#{nbspace 3} Preferred Term|#{nbspace 6} Severity";
   define col0        /display "Placebo|N=&n0";
   define col1        /display "Active|N=&n1";
   define col2        /display "Overall|N=&n2";

   compute after section;
      line '#{newline}';
   endcomp;

   title1 j=l 'Company/Trial Name' 
          j=r 'Page #{thispage} of #{lastpage}';
   title2 j=c 'Table 5.4';
   title3 j=c 'Adverse Events';
   title4 j=c "By Body System, Preferred Term, and Greatest Severity";
run; 
ods pdf close; 
 
 
 
 
 

    


       















