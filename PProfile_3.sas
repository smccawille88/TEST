/** Reset **/
ods escapechar="~";
title;
footnote;
ods listing close;

/** Setup General titles and footnotes **/
** J= means justify, L for left, C for center, R for right;
** ~ is the ODS escape character defined above;
** {THISPAGE} and {LASTPAGE} are RTF-specific codes for producing pagination
** fields in Word;
title1 j=l "&COMPANY" j=r "Page ~{thispage} of ~{lastpage}";
title2 j=l "&protocol";
title4 j=c "Information for Subjects with Markedly Abnormal LFT Values";
footnote1 j=r "~S={protectspecialchars=off pretext='\brdrt\brdrs\brdrw11 '}";
footnote2 j=l "&RUNINFO";

/** Cover Page **/
filename _cover_ "&OUTPATH/phsugi/coverpage.rtf";
ods rtf file=_cover_ style=panrtf;
title5 j=c "Cover Page";

proc report data=AE1 nowd split='^' nocenter;
	column SITE SUBJID TRTC1 PT_NAME AERELN2C;
	define SITE /order style(column)={just=left cellwidth=1 in} '~R"\ul Site " ';
	define SUBJID /order style(column)={just=left cellwidth=1 in} 
		'~R"\ul Subject " ';
	define TRTC1 /order style(column)={just=left cellwidth=2 in} 
		'~R"\ul Initial Treatment " ';
	define PT_NAME /display style(column)={just=left cellwidth=3 in 
		cellspacing=0.3 in pretext='pnhang\fi-200\li220'} 
		'~R"\ul MedDRA Preferred Term " ';
	define AERELN2C /display style(column)={just=left cellwidth=1.5 in} 
		'~R"\ul Relationship to Study drug" ';
run;

title5;

/** End of Cover Page **/
*** MACRO RUNTAB(x) will generate one output file for each subject ***;

%macro runtab;
	proc sql;
		reset noprint;
		select compress(put(count(distinct &PT), 2.)) into :NTOT from PANPT;
	quit;

	data BYSUB;
		set PANPT;
		SUBJORD=_n_;
	run;

	%do i=1 %to &NTOT;
		** Output Unique Subject Identifiers into the macro variable [SUBJID};
		**(Used in defining patient-specific Filename below);

		data _null_;
			set BYSUB;
			where SUBJORD=&i;
			call symput('SUBJID', SUBJID);
			call symput("SITE", SITE);
		run;

		filename _rtf_ "&OUTPATH/phsugi/%sysfunc(compress(&SUBJID)).rtf";
		ods rtf file=_rtf_ newfile=none nokeepn startpage=no record_separator=none 
			style=panrtf;
		9 title6 j=l "Subject : &SUBJID Site: &SITE";

		/** Subject info - 1st Part of PAN **/
		proc report data=PT nowd split='^' nocenter;
			column STUDY AGESC RACETH WEIGHT D_BMI SMOKERC;
			define STUDY /display style(column)={just=left cellwidth=1.2 in} 
				'~R"\ul Study Number " ';
			define AGESC /display style(column)={just=left cellwidth=1.2 in} 
				'~R"\ul Age/Gender" ';
			define RACETH /display style(column)={just=left cellwidth=4 in} 
				'~R"\ul Race/Ethnicity" ';
			define WEIGHT /display style(column)={just=left cellwidth=1 in} format=5.1 
				'~R"\ul Weigth(kg)" ';
			define D_BMI /display style(column)={just=left cellwidth=1 in} format=5.1 
				'~R"\ul BMI(kg/m"~{super 2})';
			define SMOKERC /display style(column)={just=left cellwidth=1.5 in} 
				'~R"\ul Smoking History" ';
			where SUBJID=&SUBJID;
		run;

		proc report data=DOSE nowd split='^' nocenter;
			column PRDC SDT EDT DURC;
			define PRDC /display style(column)={just=left cellwidth=2 in} 
				'~R"\ul Study Drug Regimen " ';
			define SDT /display style(column)={just=left cellwidth=1.5 in} 
				'~R"\ul Start Date" ';
			define EDT /display style(column)={just=left cellwidth=1.5 in} 
				'~R"\ul End Date" ';
			define DURC /display style(column)={just=left cellwidth=2.5 in} 
				'~R"\ul Treatment Duration " ';
			where SUBJID=&SUBJID;
		run;

		proc report data=PT nowd split='^' nocenter;
			column D_LASVDT D_REASOC;
			define D_LASVDT /display style(column)={just=left cellwidth=2 in} 
				'~R"\ul Last Visit Date " ';
			define D_REASOC /display style(column)={just=left cellwidth=1.5 in} 
				'~R"\ul Reason(s) for withdrawal" ';
			where SUBJID=&SUBJID;
		run;

		proc report data=MEDHIS nowd split='^' nocenter;
			column ALLTERM;
			define ALLTERM /display style(column)={just=left cellwidth=100%} 
				'Medical History (Stop Date) ';
			where SUBJID=&SUBJID;
		run;

		proc report data=CONDIS nowd split='^' nocenter;
			column ALLTERM;
			define ALLTERM /display style(column)={just=left cellwidth=100%} 
				'Concurrent Conditions (Start Date) ';
			where SUBJID=&SUBJID;
		run;

		/** AE - 2nd part of PAN **/
		data AE;
			set AE1;
			where SUBJID=&SUBJID;
			CNT=_N_;
			MYPAGE=1;

			/** To avoid page overflow, only include 13 AE records in each page **/
			if CNT > 13 then
				do;
					CNT=1;
					MYPAGE + 1;
				end;
		run;

		title6 j=l "Subject : &SUBJID (Continued)";
		title7 j=l "Adverse Event:";
		ODS RTF startpage=now;

		proc report data=AE nowd split='^' nocenter;
			column MYPAGE PT_NAME AEVT AEFREQC AEINTEC AERELN2C AEACTC AESDAY AEEDAY 
				DURC AEOUTC AESERC;
			define MYPAGE /order order=data noprint;
			define PT_NAME /display style(column)={just=left cellwidth=3 in 
				cellspacing=0.3 in pretext='pnhang\fi-200\li220'} 
				'~R"\ul MedDRA Preferred Term " ';
			define AEVT /display style(column)={just=left cellwidth=3 in cellspacing=1 
				10 pretext='pnhang\fi-200\li220'} '~R"\ul Investigator Description" ';
			define AEFREQC /display style(column)={just=left cellwidth=1 in} 
				'~R"\ul Frequency " ';
			define AEINTEC /display style(column)={just=left cellwidth=1 in} 
				'~R"\ul Intensity" ';
			define AERELN2C /display style(column)={just=left cellwidth=1 in} 
				'~R"\ul Relationship to Study Drug " ';
			define AEACTC /display style(column)={just=left cellwidth=2 in} 
				'~R"\ul Action Taken" ';
			define AESDAY /display style(column)={just=left cellwidth=2 in} 
				'~R"\ul Event Onset Date"^ (Study Day) ';
			define AEEDAY /display style(column)={just=left cellwidth=2 in} 
				'~R"\ul Event Stop Date"^ (Study Day) ';
			define DURC /display style(column)={just=left cellwidth=1 in} 
				'~R"\ul Duration of Event" ';
			define AEOUTC /display style(column)={just=left cellwidth=2 in} 
				'~R"\ul Outcome" ';
			define AESERC /display style(column)={just=left cellwidth=1 in} 
				'~R"\ul Serious" ^Adverse Event?';
			break after MYPAGE /page;
		run;

		/** Concurrent Meds - 3rd Part of PAN **/
		title7 j=l 
			'~R"\ul Medications Taken Within 2 Weeks Prior to Adverse Event Onset:" ';
		ODS RTF startpage=now;

		proc report data=CONMED nowd split='^' nocenter;
			column PREFNAM OMSDAY OMEDAY CMAEC;
			define PREFNAM /display style(column)={just=left cellwidth=4 in} 
				'~R"\ul Medication Name " ';
			define OMSDAY /display style(column)={just=left cellwidth=2 in} 
				'~R"\ul Start Date (Study Day)" ';
			define OMEDAY /display style(column)={just=left cellwidth=2 in} 
				'~R"\ul Stop Date (Study Day)" ';
			define CMAEC /display style(column)={just=left cellwidth=1 in} 
				'~R"\ul Taken for AE?" ';
			where SUBJID=&SUBJID;
		run;

		ods rtf close;
		ods listing;
	%end;
%mend runtab;

%runtab;
APPENDIX B: SAS Code for Integrating Alphanumeric and Graphical Output

/** Reset **/
ods escapechar="~";
title;
footnote;
*************************************************
** Section 1: Create graphical output **
*************************************************
/** Create customized GTL template “labplot” **/
proc template;
define statgraph labplot;

/** Define macro variables for Demographic info **/
mvar MSUBJ MSITE MAGE MSEX MRACE MHT MWT MBMI;

/** Define macro variables for x and y axis range and ticks **/
nmvar XMIN XMAX YMAX YTCK;
begingraph;
entrytitle "LFT vs DOSE";
layout lattice / columns=1 rows=2 rowweights=(0.30 0.70) rowgutter=2;

/** row 1 table – Subject information **/
layout lattice / columns=3 columnweights=(0.2 0.2 0.6) autoalign=(topleft 
	topright) border=true opaque=true backgroundcolor=white;
entry halign=left textattrs=(weight=bold color=blue) "Subject: " 
	textattrs=(weight=normal) MSUBJ;
11 entry halign=left textattrs=(weight=bold color=blue) "Site: " 
	textattrs=(weight=normal) MSITE;
entry halign=left " ";
entry halign=left textattrs=(weight=bold color=blue) "Age (yr)";
entry halign=left textattrs=(weight=bold color=blue) "Gender";
entry halign=left textattrs=(weight=bold color=blue) "Race";
entry halign=left MAGE;
entry halign=left MSEX;
entry halign=left MRACE;
entry halign=left textattrs=(weight=bold color=blue) "Height (cm)";
entry halign=left textattrs=(weight=bold color=blue) "Weight (kg)";
entry halign=left textattrs=(weight=bold color=blue) "BMI (kg/m" {sup "2"} ")";
entry halign=left MHT;
entry halign=left MWT;
entry halign=left MBMI;
endlayout;

/** row 2: graph **/
layout overlay /xaxisopts=(linearopts=(tickvaluelist=(-28 1 14 28 42 56 70 84 
	98 112 126) viewmin=XMIN viewmax=XMAX) offsetmin=0 offsetmax=0) 
	yaxisopts=(linearopts=(tickvaluelist=(0 2 3 5 10) viewmin=0 viewmax=YMAX) 
	offsetmin=0 offsetmax=0.1);
blockplot x=D_SDAYSP block=TRTC / valuevalign=top datatransparency=.3 
	valuefitpolicy=shrink name="TRTNAME";

/** AE terms **/
vectorplot x=D_EDAYSP y=YAE xorigin=D_SDAYSP yorigin=YAE / arrowheads=false 
	lineattrs=(color=green);
scatterplot x=XTM y=YAE / markercharacter=TERM 
	markercharacterattrs=(color=green SIZE=6);
scatterplot x=D_SDAYSP y=YAE / markerattrs=(color=green size=6px 
	symbol=trianglefilled);
scatterplot x=D_EDAYSP2 y=YAE / markerattrs=(color=green size=6px 
	symbol=trianglefilled);

/** OM terms **/
vectorplot x=D_EDAYSP y=YOM xorigin=D_SDAYSP yorigin=YOM / arrowheads=false 
	lineattrs=(color=red);
scatterplot x=XTM y=YOM / markercharacter=TERM markercharacterattrs=(color=red 
	SIZE=4);
scatterplot x=D_SDAYSP2 y=YOM / markerattrs=(color=red size=6px 
	symbol=trianglefilled);
scatterplot x=D_EDAYSP2 y=YOM / markerattrs=(color=red size=6px 
	symbol=trianglefilled);

/** lab **/
seriesplot x=D_SDAYSP y=VALUE /primary=true display=all markerattrs=(size=4px) 
	group=LTSTABR name="TEST";
referenceline y=2 / lineattrs=(pattern=dot thickness=2);
discretelegend "TRTNAME" / location=inside autoalign=(topleft) opaque=true 
	across=2 pad=(right=5);
discretelegend "TEST";
endlayout;
endlayout;
endgraph;
end;
run;

/** Output graphical portion PAN using SGRENDER **/
ods listing close;
filename _rtf_ "&OUTPATH/phsugi/&PROG..rtf";
options orientation=portrait;
ods rtf file=_rtf_ style=pan_grf startpage=never;
ods layout start columns=1 rows=2;
ods region width=6.5 in;
ods graphics on / width=6.5 in;

proc sgrender data=FINAL template=labplot;
run;

ods graphics off;

/** Section 2: Generate alphanumerical output **/
ods rtf style=intext startpage=never;
ods region width=8.5 in;

/** Lab table **/
proc report data=TBLRPT nowd nocenter split='^' style(report)={font_size=8 pt 
		leftmargin=1 in} 12;
	column D_SDAYSP DAY LAB104 LAB105 LAB106 LAB107 LAB108;
	define D_SDAYSP/ order noprint;
	define DAY / style(column)={just=left cellwidth=1.2 in} 
		"Sample Date^(Study Day)";
	define LAB104 / style(column)={just=left cellwidth=1.2 in} 
		"Total^Bilirubin^(3-21 umol/L)";
	define LAB105 / style(column)={just=left cellwidth=1 in} 
		"Alkaline^Phosphatase^(31-106 U/L)";
	define LAB106 / style(column)={just=left cellwidth=1 in} 
		"AST^(SGOT)^(9-34 U/L)";
	define LAB107 / style(column)={just=left cellwidth=1 in} 
		"ALT^(SGPT)^(9-34 U/L)";
	define LAB108 / style(column)={just=left cellwidth=1 in} "GGT^ (4-49 U/L)";
run;

/** AE table **/
proc report data=AETBL nowd nocenter split='^' style(report)={font_size=8 pt 
		leftmargin=1 in};
	column AEORD TERM AESDAY AEEDAY AEINTEC AERELN2C SAE AEACTC;
	define AEORD / order noprint;
	define TERM / style(column)={just=left cellwidth=2 in} "AE Preferred Term";
	define AESDAY / style(column)={just=left cellwidth=1 in} 
		"AE onset Date^(Study Day)";
	define AEEDAY / style(column)={just=left cellwidth=1 in} 
		"AE End Date^(Study Day)";
	define AEINTEC / style(column)={just=left cellwidth=0.5 in} "Intensity";
	define AERELN2C/ style(column)={just=left cellwidth=1 in} 
		"Relationship^to^Study Drug";
	define SAE / style(column)={just=left cellwidth=1 in} "Serious AE^/Death Date";
	define AEACTC / style(column)={just=left cellwidth=0.8 in} "Action Taken";
run;

ods layout end;
ods rtf close;
ods listing;