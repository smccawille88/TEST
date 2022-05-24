****FOREST PLOTS OF ODDS RATIO. IT SHOWS THE ODDS RATIO FOR CLINICAL THERAPY,***************
******RACE, GENDER, AND BASELINE PAIN SCORE WITH REGARD TO THE OVERALL CLINICAL SUCCESS OF A PATIENT*/*******

/*NOTES- ODDS RATIO PROBABILITY OF EVENT/ PROBABILITY OF A NON-EVENT.THE MAGNITUDE OF THE ODDS RATIO IS CALLED THE “STRENGTH OF THE ASSOCIATION.” THE FURTHER AWAY AN ODDS RATIO IS FROM 1.0, THE MORE LIKELY IT IS THAT THE RELATIONSHIP BETWEEN THE EXPOSURE AND THE DISEASE IS CAUSAL. 
FOR EXAMPLE, AN ODDS RATIO OF 1.2 IS ABOVE 1.0, BUT IS NOT A STRONG ASSOCIATION.*/
           


**** PROGRAM 6.5;
**** INPUT SAMPLE PAIN DATA AS CDISC ADAM ADPAIN DATASET.;

data ADPAIN;
	label AVAL="Analysis Value" /* theraputic success */
	TRTPN="Planned Treatment (N)" SEXN="Male" RACEN="Race (N)" 
		BASEPAIN="Baseline Pain Score";
	input AVAL TRTPN SEXN RACEN BASEPAIN @@;
	datalines;
1 0 1 3 20   1 0 1 1 31   1 0 1 2 40   1 0 1 1 50   1 1 2 1 60   
1 1 2 1 22   0 0 1 2 23   1 1 2 1 20   0 0 2 2 20   0 0 2 1 23   
1 0 2 2 20   1 1 1 1 25   1 1 1 1 20   1 1 2 1 20   1 1 2 2 20   
1 1 1 1 10   1 0 2 1 25   0 0 1 3 40   1 0 1 1 20   1 0 1 1 20   
0 0 1 3 24   1 1 1 1 30   0 1 1 2 20   0 1 2 1 21   0 1 1 2 34   
0 0 2 1 20   1 0 1 2 20   1 0 1 1 20   1 0 1 2 20   1 1 2 1 55   
1 1 1 3 22   1 1 1 1 34   1 1 1 2 40   1 1 1 1 50   1 1 1 1 60   
0 0 2 1 20   0 0 2 2 20   0 0 2 1 20   0 0 2 2 20   0 0 1 1 20   
1 1 1 2 25   1 1 1 1 23   1 0 2 1 20   1 1 2 1 20   1 0 1 2 22   
1 0 1 1 11   1 0 1 1 33   0 0 2 3 40   1 0 1 1 20   0 1 1 1 21   
1 1 2 3 24   1 0 2 1 30   1 1 1 2 20   1 1 2 1 21   0 1 1 2 33   
0 0 2 1 20   1 1 1 2 22   1 1 2 1 20   1 1 1 2 20   1 0 1 1 50   
0 0 1 1 55   0 0 1 2 12   0 1 1 1 20   1 1 1 2 22   1 1 1 1 12   
;
	****** GET ADJUSTED ODDS RATIO FROM PROC LOGISTIC AND PLACE
****** THEM IN DAAT SET WALD;

	/*We use PROC LOGISTIC to obtain our adjusted odds ratio and 95% Confidence limits.
	ODS is used to send the statistics to the "odds" data set. Note that we set "event=1" in PROC LOGISTIC to model for the probability that AVAL=1*/
	ods output CLoddsWald=odds;

proc logistic data=adpain;
	model aval(event='1')=basepain sexn racen trtpn / clodds=wald;
run;

ods output close;

******RECATEGORISE EFFECT FOR Y AXIS FORMATTING PURPOSES. 
IN ORDER TO MAKE THE PLOT LOOK THE WAY THAT WE WANT IT, THE "EFFECT" VARAIBLE IN THE ODDS DATA SET 
IS TRANSLATED TO A NUMERIC VALUE. THE SUBSEQUENT PROC FORMAT creates the format "effect"
which is sued in the PROC SGPLOT;

data odds;
set odds;

select(effect);
   when ("BASEPAIN") Y = 1;
   WHEN ("SEXN")     Y = 2;
   WHEN ("RACEN")    Y= 3;
   WHEN ("TRTPN")    Y=4;
   otherwise;
  end;
run;

ods listing;

*****FORMAT FOR EFFECT ON Y AXIS;
proc format;
  value effect
  1 = "Baseline pain (continuous)"
  2=  "Male vs Female"
  3 = "White vs Black"
  4 = "Active Therapy vs Placebo"
  ;
run;

*****CLOSE ALL DESTINATIONS SO ONLY ONE GRAPH IS PRODUCED;
ods _all_ close;


ods html path ="/home/smccawille1/Output" file="Odds_ratio.html"
image_dpi=300 style=htmlblue;

ods graphics on / reset imagename="odds_ratio_forest" outputfmt=png;

*****PRODUCE ODDS RATIO PLOT;
proc sgplot data=odds noautolegend;

scatter y=y x=oddsratioest /
            xerrorupper = uppercl
            xerrorlower=lowercl
            errorbarattrs=(thickness=2.5 color=black)
            markerattrs=graphdata1(size=0);
scatter y=y x=oddsratioest /
        markerattrs= graphdata1 (symbol=circlefilled
                                 color=black size= 8);
refline 1 /axis =x;

yaxis values = (1 to 4 by 1)
      display= (noticks nolabel);
xaxis type=log logbase= 2 values=(0.125 0.25 0.5 1 2 4 8 16)
               label='Odds Ratios and 95% Confidence Interval';

format y effect.;

title1 "Odds Ratio for Clinical Success";
run;

ods html close;               

