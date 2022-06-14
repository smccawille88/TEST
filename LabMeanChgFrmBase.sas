/****************************************************************************************
Program:          Program_3-5.sas

SAS Version:      SAS Enterprise Guide 7.15 (SAS 9.4m5)
Developer:        Richann Watson 
Date:             2020-01-17
Purpose:          Produce outputs for SAS� Graphics for Clinical Trials by Example book. 
Operating Sys:    Windows 10

Macros:           NONE

Input:            adlchem.sas7bdat, adlbstat.sas7bdat

Output:           Output_3-6.rtf

Comments:         Use CustomSapphire style that was provided by SAS press
                  Note CustomSapphire is not provided with SAS but rather created 
                  specifically for SAS Press books
----------------------------------------------------------------------------------------- 
****************************************************************************************/

/*******************************************/
/*** BEGIN SECTION TO BE UPDATED BY USER ***/
/*******************************************/
options validvarname=upcase;
%include "/home/smccawille1/sasuser.v94/Program/Styles/CustomSapphire.sas";
libname adam "/home/smccawille1/sasuser.v94/ADAM";
%let outpath =/home/smccawille1/sasuser.v94/Output;
%let outname = Output_3-6;

/* you can download any custom font at dafont.com to test this out or you can remove the portion for custom fonts */
%let font = primetime; 
/*****************************************/
/*** END SECTION TO BE UPDATED BY USER ***/
/*****************************************/

title;

/* formats to display time point */
proc format;
   value trt
       0 = 'Placebo'
       54 = 'Xanomeline Low Dose'
       81 = 'Xanomeline High Dose'
                ;
run;

/* get a list of all unique visits */
proc sort data = adam.adlbchem 
           out = visit (keep = avisit:) nodupkey;
  by avisitn avisit;
  where avisitn ne 99;
run;

data visfmt;
   set visit (rename = (avisitn = start avisit = label));
   label = strip(label);
   fmtname = 'vis';
run;

/* store the data set in the format library so visit format can be used in PROC SGRENDER */
proc format cntlin = visfmt;
run;

/* create a macro variable that contains a list of all the visits numbers for the tick marks */
data vislist;
   set visit end = last;
   length vis $100;
   retain vis;
   vis = catx(' ', vis, avisitn);
   if last;
   call symputx('vlist', vis);
run;

ods rtf file = "&outpath.\Display_3-3.rtf"
        image_dpi = 300
        style = customSapphire;

proc print data = adam.adlbstat (obs = 10 drop = paramcd trtan avisitn);
run;

ods rtf close;

/* specify custom font */
proc fontreg mode = all msglevel=verbose;
   fontpath "C:\Users\gonza\Desktop\DataRich Consulting\Company Branding\Fonts\&font";
run;

options nobyline nodate nonumber;
ods graphics on / imagefmt = png width = 5in noborder;
ods rtf file = "&outpath.\&outname..rtf"
        image_dpi = 300
        style = customSapphire;

title j = c 'Laboratory Test: ' font = "&font" bold height = 11pt '#byval2';

proc sgplot data = adam.adlbstat; 
   by paramcd param;
   format trtan trt. avisitn vis.;

   series x = avisitn y = chg_mean / markers
                                     group = trta;

   scatter x = avisitn y = chg_mean / group = trtan
                                      yerrorlower = lerr
                                      yerrorupper = uerr;

   xaxis type = linear label = "Analysis Visit"
         min = 2 max = 26
         values = (&vlist)
         fitpolicy =  rotate
         valuesrotate = diagonal2;
   yaxis type = linear label = "Change from Baseline" ;
run;

ods rtf close;
ods graphics off;