******LINE PLOT THAT SHOWS THE CLINICAL RESPONSE OF A POPULATION OF PATIENTS TO 2 DIFFERNT THERAPIES OVER THE COURSE OF 10 DAYS**********;
**** PROGRAM 6.2;
**** INPUT SAMPLE MEAN CLINICAL RESPONSE VALUES AS ADEFF.;
data ADEFF;
label AVAL    = "Analysis Value"
      AVISITN = "Analysis Visit (N)"
      TRTPN   = "Planned Treatment (N)";
input TRTPN AVISITN AVAL @@;
datalines;
1  0 9.40    2  0 9.55
1  1 9.35    2  1 9.45
1  2 8.22    2  2 8.78
1  3 6.33    2  3 8.23
1  4 4.00    2  4 7.77
1  5 2.22    2  5 4.46
1  6 1.44    2  6 2.00
1  7 1.13    2  7 1.86
1  8 0.55    2  8 1.44
1  9 0.67    2  9 1.33
1 10 0.45    2 10 1.01
;
run;
 
**** CREATE FORMATS TO BE USED IN PLOT.;
proc format;
   value avisitn
      0 = "Baseline"
      1 = "Day 1"
      2 = "Day 2"
      3 = "Day 3"
      4 = "Day 4"
      5 = "Day 5"
      6 = "Day 6"
      7 = "Day 7"
      8 = "Day 8"
      9 = "Day 9"
      10 = "Day 10";
   value trtpn
      1 = "Super Drug"
      2 = "Old Drug";
run;


**** CLOSE ODS DESTINATIONS SO ONLY ONE GRAPH IS PRODUCED;
ods _all_ close;

********* MODIFY THE STYLE TEMPLATE TO GET DESIRED SYMBOLS/LINES;
ods path sashelp.tmplmst (read) work.templat;

proc template;
define style newblue / store = work.templat;
parent=styles.htmlblue;

class graph /attrpriority='none';

class GraphData1 / markersymbol = 'circlefilled'
                   linestyle = 1
                   contrastcolor=black;
class GraphData2 / markersymbol ='circle'
                   linestyle=2
                   contrastcolor=black;
end;
run;

                   


*****CREATE A LINE PLOT USING SGPLOT;

******CREATE THE PLOT DESIRED WITH PROC SGPLOT;
ods html path ="/home/smccawille1/Output" file="LinePlot.html"
image_dpi =300 style=newblue;

ods graphics on / reset imagename="Line_Plot" outputfmt=png;



*******PRODUCE LINE PLOT;
proc sgplot data= adeff;
series x=avisitn y=aval / group=trtpn markers
name= "customlegend" legendlabel="Treatment";

refline 1/ axis=x;

yaxis values=(0 to 10 by 1)
      display=(noticks)
      label='Mean Clinical Response';

xaxis values=(0to 10 by 1)
      label = 'Visit';
      
keylegend "customlegend" / location=inside  
                           position = topright;

format avisitn avisitn. trtpn trtpn.;

title1 "Mean Clinical Response By Visit";
run;

ods html close;  


                         
      


