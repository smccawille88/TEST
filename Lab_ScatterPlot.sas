**** PROGRAM 6.1;
**** INPUT SAMPLE HEMATOCRIT LAB DATA AS ADLB.;
data ADLB;
label USUBJID = "Unique Subject Identifier"
      PARAMCD = "Parameter Code"
      BASE    = "Baseline Value"
      AVAL    = "Analysis Value"
      TRTP    = "Planned Treatment";
input USUBJID $ PARAMCD $ AVAL BASE TRTP $ @@;
datalines;
101 HCT 35.0 31.0 a    102 HCT 40.2 30.0 a 
103 HCT 42.0 42.4 b    104 HCT 41.2 41.4 b 
105 HCT 35.0 33.3 a    106 HCT 34.3 34.3 a 
107 HCT 30.3 44.0 b    108 HCT 34.2 42.0 b 
109 HCT 40.0 41.1 b    110 HCT 41.0 42.1 b 
111 HCT 33.3 33.8 a    112 HCT 34.0 31.0 a 
113 HCT 34.0 41.0 b    114 HCT 34.0 40.0 b 
115 HCT 37.2 35.2 a    116 HCT 39.3 36.2 a 
117 HCT 36.3 38.3 b    118 HCT 37.4 37.3 b 
119 HCT 44.2 34.3 a    120 HCT 42.2 36.5 a 
;
run;


********* CLOSE ODS DESTINATIONS SO ONLY ONE GRAPH IS PRODUCED;
ods _all_ close; /*cLOSED SO WE ONLY GET ONE GRAPHICS FILE FROM TEH CODE BELOW*/

********MODIFY THE STYLE TEMPLATE TO GET DESIRED SYMBOLS;
ods path sashelp.tmplmst(read) work.templat;

proc template;
define style newblue /store =work.templat;
parent= styles.htmlblue;

class graph /attrpriority= 'none';

class GraphData1 / markersymbol ='circle'
                   contrastcolor=black;
class GraphData2 / markersymbol='plus'
                   contrastcolor=black;
  end;
run;

******CREATE THE PLOT DESIRED WITH PROC SGPLOT;
ods html path ="/home/smccawille1/Output" file="Lab_ScatterPlot"
image_dpi =300 style=newblue;

ods graphics on / reset imagename="Lab_ScatterPlot" outputfmt=png;


******CREATE SCATTER PLOT;
proc sgplot data=adlb;
scatter x = aval
        y = base /group=trtp;
xaxis values = (30 35 40 45) minorcount=4; 
yaxis values = (30 35 40 45) minorcount=4;
lineparm x=30 y=30 slope=1;
title1 "Hematocrit (%) Scatter Plot";
title2 "At Visit 3";
run;

ods graphics off;
ods html close;      




