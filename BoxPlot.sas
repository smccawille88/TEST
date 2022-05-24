/*Box plot of seizure dta by treatment at each of three visits. This box plot has boxes than span the interquartile range and whiskers that extend to the maximum nad minimum values.*/

**** PROGRAM 6.4;
**** INPUT SAMPLE PAIN SCALE DATA AS CDISC ADAM ADSEIZ DATA;
data ADSEIZ;
label AVAL    = 'Analysis Value' 
      /* where AVAL = "Seizures per Hour" */
      AVISITN = 'Analysis Visit (N)'
      TRTPN   = 'Planned Treatment (N)';
input TRTPN AVISITN AVAL @@;
datalines;
1 2 1.5    2 1 3      2 2 1.8
2 1 2.6    2 2 2      2 3 2
1 1 2.8    2 3 2.6    1 1 3
1 2 2.2    1 1 2.4    2 1 3.2
2 1 3.2    1 2 1.4    1 1 2.6
2 2 2.1    1 3 1.8    1 2 1.2
1 1 2.6    2 1 3      1 3 1.8
2 1 2.2    1 1 3.6    2 1 2.1
2 2 3.2    1 2 2      2 2 1
1 1 2.6    1 3 3.6    2 3 1.8
1 2 2.2    2 1 3.6    1 1 2.6
1 3 2.2    2 2 2.6    2 1 4
2 1 2.8    2 3 2      2 3 3.6
2 2 2.6    1 1 2.8    1 1 3.4
2 3 2.6    1 2 1.8    1 2 3
1 1 2.0    1 3 1.6    2 1 3.4
1 2 2.4    2 1 3.8    2 2 2
2 1 2.1    2 2 3      1 1 2.6
2 2 1.2    2 3 3.4    1 3 1.8
2 3 1      1 1 4      2 1 2.0
1 1 2.9    1 3 3.4    1 1 2.8
1 2 1.6    2 1 2.8    2 1 2.4
1 3 1.2    2 2 1.2    1 1 3.6
2 1 2.8    2 3 1.2    2 1 3.2
2 2 2.6    1 1 1.8    2 2 2.2
2 3 3.2    1 2 2      2 3 3.2
1 1 2.8    1 3 2.2    1 1 4
1 2 1.4    2 1 3      2 1 3.2
1 3 2      2 2 1.4    1 1 2.4
2 1 1.6    2 3 1.4    2 1 4
1 1 2.8    1 1 3.6    2 2 2.2
1 2 1.4    1 2 1.4    1 1 4
1 3 1.2    2 1 2.2
;
run;


**** FORMATS FOR THE PLOT;
proc format;
  value trtpn_
     1 = "Active"
     2 = "Placebo";
  value avisitn
     1 = 'Baseline'
     2 = '6 Months'
     3 = '9 Months';
run;


**** CLOSE ODS DESTINATIONS SO ONLY ONE GRAPH IS PRODUCED;
ods _all_ close;

**** MODIFY THE STYLE TEMPLATE TO GET DESIRED SYMBOLS AND LINES;
ods path sashelp.tmplmst(read) work.templat;


proc template;
define style newblue / store=work.templat;
parent=styles.htmlblue;

class graph / attrpriority = 'none';

class GraphData1 / markersymbol='Earthfilled'
                   contrastcolor=black
                   linestyle=2;
class GraphData1 / markersymbol='Earthfilled'
                   contrastcolor=black                   
                   linestyle=1;
 end;
run;

ods html path="/home/smccawille1/Output" file="BoxPlot.html"
image_dpi= 300 style=newblue;

ods graphics on /reset imagename="Box_Plot" outputfmt=png;

******CREATE A BOX PLOT****************;

proc sgplot data = adseiz;

vbox aval / category=avisitn group=trtpn
            nofill capshape=line connect=median
            grouporder=ascending extreme nooutliers;
xaxis label = 'Visit';
yaxis values = (1 to 4 by 1) minorcount=3
      label='Seizures per Hour';

format trtpn trtpn_. avisitn avisitn_.;
label trtpn = "Treatment";

title1 "Seizures Per Hour By Treatment";
footnote j=l 
"Box extends to 25th and 75th percentile. Whiskers extend to"
"minimum nad maximum values. Mean values are represented by"
"a dot while medians are connected by the line.";
run;

ods html close;     

                   