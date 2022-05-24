/*Bar Chart showing patients pain score ratings by treatment. The percentage of patients with each pain rating is displayed for each drug classification*/


**** PROGRAM 6.3;
**** INPUT SAMPLE PAIN SCALE DATA AS CDISC ADAM ADPAIN DATASET;
data ADPAIN;
label USUBJID  = "Unique Subject Identifier"
      AVALCAT1 = "Analysis Category 1"
      TRTPN    = "Planned Treatment (N)";
input USUBJID $ AVALCAT1 TRTPN @@;
datalines;
113 1 1    420 1 2    780 0 3
121 1 1    423 0 2    784 0 3
122 1 1    465 4 2    785 1 3
124 4 1    481 3 2    786 3 3
164 4 1    482 0 2    787 0 3
177 4 1    483 0 2    789 0 3
178 0 1    484 0 2    790 2 3
179 1 1    485 0 2    791 0 3
184 0 1    486 1 2    793 3 3
185 0 1    487 0 2    794 2 3
186 3 1    489 0 2    795 1 3
187 0 1    490 1 2    796 4 3
188 1 1    491 0 2    797 2 3
189 3 1    493 2 2    798 1 3
190 3 1    494 1 2    799 2 3
191 2 1    495 0 2    800 2 3
192 3 1    496 2 2    822 1 3
193 4 1    498 0 2    841 1 3
194 4 1    499 2 2    842 1 3
195 0 1    500 2 2    847 2 3
196 4 1    521 1 2    863 1 3
197 1 1    522 1 2    881 2 3
198 4 1    541 1 2    966 1 3
199 3 1    542 0 2    967 0 3
100 4 1    561 3 2    968 0 3
121 2 1    562 2 2    981 1 3
122 2 1    581 2 2    982 1 3
123 4 1    561 1 2    985 0 3
124 2 1    564 1 2    986 0 3
141 3 1    566 1 2    987 0 3
142 2 1    567 2 2    989 2 3
143 2 1    568 2 2    990 3 3
147 4 1    569 0 2    991 0 3
161 4 1    581 0 2    992 2 3
162 4 1    582 3 2    993 1 3
163 4 1    584 1 2    994 0 3
164 0 1    585 0 2    995 1 3
165 2 1    586 1 2    996 0 3
166 1 1    587 1 2    997 3 3
167 3 1    591 1 2    998 0 3
181 2 1    592 1 2    999 0 3
221 4 1    594 1 2    706 0 3
281 4 1    595 0 2    707 3 3
282 4 1    596 0 2    708 1 3
361 4 1    597 0 2    709 0 3
362 4 1    601 0 2    710 1 3
364 3 1    602 1 2    711 1 3
365 4 1    603 2 2    712 0 3
366 3 1    604 1 2    713 4 3
367 4 1    605 1 2    714 0 3
;



**** MAKE FORMATS FOR CHART.;
proc format;
   value trtpn
      1 = 'Placebo'
      2 = 'Old Drug'
      3 = 'New Drug' ;

   value avalcat
      0 = '0  '
      1 = '1-2'
      2 = '3-4'
      3 = '5-6'
      4 = '7-8';

   picture newpct (round) /*Important to note*/
      0 = " "
      0 < - < .5 = "<1%"
      .6 < - high = "000%";
run;
 
proc sort
   data = adpain;
      by trtpn;
run;


******GET FREQUENCY COUNTS FOR CHART AND PLACE IN FREQOUT DATA.- PROC FREQ TO CALCUALTE SUMAMRY STATISTICS THAT WILL BE USED IN THE BAR CHART;

proc freq data=adpain noprint;
  by trtpn;

  tables avalcat1 / out= freqout;
run;

******CLOSE ODS DESTINATIONS SO ONLY ONE GRAPH IS PRODUCED;
ods _all_  close;

*******CREATE;
ods html path="/home/smccawille1/Output" file="barchart.html"
image_dpi=300 style=htmlblue;

ods graphics on / reset imagename="bar_chart" outputfmt=png
attrpriority=color;

*******PRODUCE VERTICAL BAR CHART********;

proc sgpanel data=freqout cycleattrs noautolegend;

********PANEL BY TREATMENT;
panelby trtpn /layout=columnlattice novarname onepanel
                                  colheaderpos=bottom;
styleattrs datacolors=(white gray black);

*****CREATE VERTICAL BARS;
vbarparm category=avalcat1 response=percent / datalabel
                                              group=trtpn;
rowaxis values = (0 to 50 by 10)
              label="Percentage of Patients";
colaxis label="Pain Score" labelpos=right;
format percent newpct. trtpn trtpn. avalcat1 avalcat.; /*Picture format enables you to use format percentages of less than 0.5 percent as "<1%". Useful for P-values less than 0.05*/
title1 "Sumamry of Pain Score by Treatment";
run;

ods html close;              









  

