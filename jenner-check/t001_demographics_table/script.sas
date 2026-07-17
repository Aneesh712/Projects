/*---------------------------------------------
   IMPORTING DATA
   (adapted for Jenner: original script used
    PROC IMPORT datafile="C:\Users\ANUPAMA\Downloads\ADSL.xlsx" dbms=xlsx;
    replaced here with an inline sample ADSL-shaped dataset carrying
    the same columns the rest of the program reads)
---------------------------------------------*/

data adsl;
	length usubjid $10 ittfl $1 trt01a $10 sex $1 race $10 ethnic $15 agegr1 $5;
	input usubjid $ ittfl $ trt01a $ trt01an age pltcnt agegr1 $ sex $ race $ ethnic $;
	datalines;
001-001 Y Drug_A 1 45 220 <65 M White Hispanic
001-002 Y Drug_A 1 62 180 <65 F Black Non-Hispanic
001-003 Y Drug_A 1 71 260 >=65 M White Non-Hispanic
001-004 Y Placebo 2 55 300 <65 F Asian Non-Hispanic
001-005 Y Placebo 2 68 190 >=65 M White Hispanic
001-006 Y Placebo 2 49 210 <65 F Black Non-Hispanic
001-007 N Drug_A 1 58 240 <65 M Other Non-Hispanic
001-008 Y Drug_A 1 73 175 >=65 F White Non-Hispanic
001-009 Y Placebo 2 44 255 <65 M Asian Non-Hispanic
001-010 Y Placebo 2 66 205 >=65 F White Hispanic
001-011 Y Drug_A 1 52 230 <65 M Black Non-Hispanic
001-012 Y Drug_A 1 77 190 >=65 F White Non-Hispanic
001-013 Y Placebo 2 39 215 <65 M White Hispanic
001-014 Y Placebo 2 81 165 >=65 F Asian Non-Hispanic
001-015 Y Drug_A 1 60 245 <65 M White Non-Hispanic
001-016 Y Placebo 2 29 270 <65 F Black Hispanic
;
run;

data adsl;
	set adsl;
	trt01a = tranwrd(trt01a, 'Drug_A', 'Drug A');
run;

/*-------------------------------------------
    PREPARING THE DATASET FOR TABLE
-------------------------------------------*/

data adsl01;
	set adsl;
	where ittfl='Y';
	output;
	trt01a='Overall';
	trt01an=99;
	output;
run;

/*--------------------------------------------
    CREATING MACRO FOR MEANS
----------------------------------------------*/

%macro means (seq=,var=,statname=,prnt=);

proc sort data=adsl01;
	by trt01an;
run;

proc summary data=adsl01;
	by trt01an;
	var &var;
	output out= stat1_&seq n=n
                      mean=MEAN
                      median=MEDIAN
                      max=MAX
                      min=MIN
                      std=Std;
run;

data adsl02_&seq;
	length statname avalc $200;
	set stat1_&seq ;
	N_ = put(N,4.);
	MEAN_= put(MEAN,2.);
	MEDIAN_=put(MEDIAN,2.);
	x=put(min,2.)||' , '||put(max,2.);
	std_=put(std,5.2);
	statname=' N';statorder=1;avalc=strip(N_);output;
	statname=' MEAN';statorder=2;avalc=strip(MEAN_);output;
	statname=' MEDIAN';statorder=3;avalc=strip(MEDIAN_);output;
	statname=' MIN , MAX';statorder=4;avalc=strip(X);output;
	statname='STANDARD DEVIATION';statorder=5;avalc=strip(STD_);output;
	drop _type_ _freq_ n mean median std max min;
run;

proc sort data=adsl02_&seq out=sort1_&seq;
	by statorder statname trt01an;
run;

proc transpose data=sort1_&seq out=adsl03_&seq;
	by statorder statname ;
	var  avalc;
	id trt01an;
run;

data adsl04_&seq;
	set adsl03_&seq;
	prntorder=&prnt.;
	drop _name_;
run;

/********************************************************
       CREATING DUMMY
********************************************************/

data dummy01_&seq;
	statname=&statname;
	prntorder=&prnt.;
	statorder=0;
run;

/*----------------------------------------------------
     APPENDING DUMMY AND AGE DATA
-----------------------------------------------------*/


data final_&var;
	length statname $200;
	set dummy01_&seq adsl04_&seq;
	if _n_ ne 1 and _n_ ne 6 then statname= '  '||statname;
run;

%mend;

%means (seq=1,var=age,statname="AGE",prnt=1);
%means (seq=6,var=pltcnt,statname="PLATELET COUNT",prnt=6);

/*-----------------------------------------------------
           CALCULATING BIGN
-----------------------------------------------------*/

PROC SQL noprint;
	SELECT strip(put(count(usubjid), 8.)) INTO: bign1  FROM ADSL01 WHERE TRT01AN=1;
	SELECT strip(put(count(usubjid), 8.)) INTO: bign2  FROM ADSL01 WHERE TRT01AN=2;
	SELECT strip(put(count(usubjid), 8.)) INTO: bign3  FROM ADSL01 WHERE TRT01AN=3;
	SELECT strip(put(count(usubjid), 8.)) INTO: bign4  FROM ADSL01 WHERE TRT01AN=99;
quit;



 %put &bign1 &bign2 &bign3 &bign4;


/*------------------------------------------------------
         FREQUENCY CALCULATIONS FOR AGEGRP
------------------------------------------------------*/

proc freq data=adsl01 noprint;
	tables trt01an*AGegr1/out=frq1(drop=percentage);
run;

data frq2;
	set frq1;
	if trt01an=1 then pct=strip(put(count,4.))||' ( '||strip(put((count/&bign1)*100,4.1))||')';
	if trt01an=2 then pct=strip(put(count,4.))||' ( '||strip(put((count/&bign2)*100,4.1))||')';
	if trt01an=3 then pct=strip(put(count,4.))||' ( '||strip(put((count/&bign3)*100,4.1))||')';
	if trt01an=99 then pct=strip(put(count,4.))||' ( '||strip(put((count/&bign4)*100,4.1))||')';
	drop count percent;
run;

proc sort data=frq2;
	by AGegr1;
run;

proc transpose data=frq2 out=frq3(drop=_name_);
	by agegr1;
	id trt01an;
	var pct;
run;

data frq4;
	length statname $200;
	set frq3(rename=( AGegr1=statname));
	prntorder=2;
	if statname='<65' then statorder=1;
	else if statname='>=65' then statorder=2;
run;

/*-------------------------------------------------------
          CREATING DUMMY
-------------------------------------------------------*/


data dummyf1;
	length statname $200;
	statname='AGE CATEGORIZATION (%)';
	PRNTORDER=2;
	statorder=0;
run;

data dummyf2;
	length statname $200;
	statname='NOT RELATED';
	PRNTORDER=2;
	statorder=4;
run;

data final_agegrp;
	set dummyf1 frq4 dummyf2;
	length statname $200;
	format statname $200.;
	informat statname $200.;
	if _n_ ne 1  then statname= '  '||statname;
run;


/*------------------------------------------------------
         FREQUENCY CALCULATIONS FOR GENDER
------------------------------------------------------*/

proc freq data=adsl01 noprint;
	tables trt01an*SEX/out=frqsex1(drop=percentage);
run;

data frqsex2;
	set frqsex1;
	if trt01an=1 then pct=strip(put(count,4.))||' ( '||strip(put((count/&bign1)*100,4.1))||')';
	if trt01an=2 then pct=strip(put(count,4.))||' ( '||strip(put((count/&bign2)*100,4.1))||')';
	if trt01an=3 then pct=strip(put(count,4.))||' ( '||strip(put((count/&bign3)*100,4.1))||')';
	if trt01an=99 then pct=strip(put(count,4.))||' ( '||strip(put((count/&bign4)*100,4.1))||')';
	drop count percent;
run;

proc sort data=frqsex2;
	by sex;
run;

proc transpose data=frqsex2 out=frqsex3(drop=_name_);
	by sex;
	id trt01an;
	var pct;
run;

data frqsex4;
	length statname $200;
	format statname $200.;
	informat statname $200.;
	set frqsex3 (rename=(sex=statname));
	prntorder=3;
	if statname = 'M' then do;
		statname = 'MALE' ;
		statorder=1;
	end;
	else if statname = 'F' then do;
		statname = 'FEMALE';
		statorder=2;
	end;
run;

/*-------------------------------------------------------
          CREATING DUMMY
-------------------------------------------------------*/


data dummys1;
	length statname $200;
	statname='GENDER (%)';
	PRNTORDER=3;
	statorder=0;
run;

data dummyS2;
	length statname $200;
	statname='NOT RELATED';
	PRNTORDER=3;
	statorder=4;
run;

data final_SEX;
	set dummyS1 frqsex4 dummys2;
	length statname $200;
	format statname $200.;
	informat statname $200.;
	if _n_ ne 1 then statname= '  '||statname;
run;


/*------------------------------------------------------
         FREQUENCY CALCULATIONS FOR RACE
------------------------------------------------------*/

proc freq data=adsl01 noprint;
	tables trt01an*RACE/out=frqr1(drop=percentage);
run;

data frqr2;
	set frqr1;
	if trt01an=1 then pct=strip(put(count,4.))||' ( '||strip(put((count/&bign1)*100,4.1))||')';
	if trt01an=2 then pct=strip(put(count,4.))||' ( '||strip(put((count/&bign2)*100,4.1))||')';
	if trt01an=3 then pct=strip(put(count,4.))||' ( '||strip(put((count/&bign3)*100,4.1))||')';
	if trt01an=99 then pct=strip(put(count,4.))||' ( '||strip(put((count/&bign4)*100,4.1))||')';
	drop count percent;
run;

proc sort data=frqr2;
	by RACE;
run;

proc transpose data=frqr2 out=frqr3(drop=_name_);
	by race;
	id trt01an;
	var pct;
run;

data frqr4;
	length statname $200;
	format statname $200.;
	informat statname $200.;
	set frqr3 (rename=(race=statname));
	prntorder=4;
	statname=upcase(statname);
	if statname = 'WHITE' THEN statorder=1;
	if statname = 'BLACK' THEN statorder=2;
	if statname = 'ASIAN' THEN statorder=3;
	if statname = 'OTHER' THEN statorder=4;
	if statname = 'BLACK' THEN statname='BLACK OR AFRICAN AMERICAN';
	if statorder ~=.;
run;

proc sort data=frqr4;
	by statorder;
run;

/*-------------------------------------------------------
          CREATING DUMMY
-------------------------------------------------------*/


data dummyr1;
	length statname $200;
	statname='RACE (%)';
	PRNTORDER=4;
	statorder=0;
run;

data dummyr2;
	length statname $200;
	statname='NOT RELATED';
	PRNTORDER=4;
	statorder=5;
run;

data final_race;
	set dummyr1 frqr4 dummyr2;
	length statname $200;
	format statname $200.;
	informat statname $200.;
	if _n_ ne 1 then statname= '  '||statname;
run;


/*------------------------------------------------------
         FREQUENCY CALCULATIONS FOR ETHINICITY
------------------------------------------------------*/

proc freq data=adsl01 noprint;
	tables trt01an*ethnic/out=frqe1(drop=percentage);
run;

data frqe2;
	set frqe1;
	if trt01an=1 then pct=strip(put(count,4.))||' ( '||strip(put((count/&bign1)*100,4.1))||')';
	if trt01an=2 then pct=strip(put(count,4.))||' ( '||strip(put((count/&bign2)*100,4.1))||')';
	if trt01an=3 then pct=strip(put(count,4.))||' ( '||strip(put((count/&bign3)*100,4.1))||')';
	if trt01an=99 then pct=strip(put(count,4.))||' ( '||strip(put((count/&bign4)*100,4.1))||')';
	drop count percent;
run;

proc sort data=frqe2;
	by ethnic;
run;

proc transpose data=frqe2 out=frqe3(drop=_name_);
	by ethnic;
	id trt01an;
	var pct;
run;

data frqe4;
	length statname $200;
	format statname $200.;
	informat statname $200.;
	set frqe3 (rename=(ethnic=statname));
	prntorder=5;
	statname=upcase(statname);
	if propcase(statname) = 'Hispanic' THEN statorder=1;
	if propcase(statname) = 'Non-Hispanic' THEN statorder=2;
	if propcase(statname) = 'Hispanic' THEN statname='HISPANIC/LATINO';
	if propcase(statname) = 'Non-Hispanic' THEN statname='NOT HISPANIC/LATINO';
	if _2='' then _2='0';
run;

proc sort data=frqe4;
	by statorder;
run;

/*-------------------------------------------------------
          CREATING DUMMY
-------------------------------------------------------*/


data dummye1;
	length statname $200;
	statname='ETINICITY (%)';
	PRNTORDER=5;
	statorder=0;
run;

data dummye2;
	length statname $200;
	statname='NOT RELATED';
	PRNTORDER=5;
	statorder=5;
run;

data final_ethnic;
	set dummye1 frqe4 dummye2;
	length statname $200;
	format statname $200.;
	informat statname $200.;
	if _n_ ne 1 then statname= '  '||statname;
run;


data finalset;
	set final_age final_agegrp final_ethnic final_race final_sex final_pltcnt;
run;


proc sort data=finalset;
	by prntorder statorder;
run;

data finalset1;
	retain statname _1 _2  _99;
	set finalset;
run;

data final;
    set finalset1;
    rename _1=DRUG_A _2=DRUG_B _99=TOTAL;
	drop prntorder statorder;
run;



proc print data= final;
run;



/*--------------------------------------------------------------
    proc report
    (adapted for Jenner: original ODS RTF destination was a
     hardcoded local path, "C:\Users\ANUPAMA\Desktop\SAS\re1.rtf";
     redirected here to a relative path)
--------------------------------------------------------------*/

ods _all_ close;

ods rtf file ="./re1.rtf" style=journal ;

title1 "Demographic and Baseline Characteristics Summary";
title2 "      All Randomized Subjects";

proc report data=finalset1 split='~'  headline headskip nowd; ;
  column statname _1 _2  _99 prntorder ;
  define statname / '' width=35  ;
  define _1 / "DRUG A~N=(50)" width=22 spacing=2 ;
  define _2 / "DRUG B~N=(50)" width=22 spacing=2 ;
/*  define _3 / "DRUG C~N=&BIGN3" width=20 spacing=4 ;*/
  define _99 / "TOTAL~N=(50)" width=21 spacing=2 ;
  define prntorder /  order noprint;
  break after prntorder / skip;

run;
ods rtf close;
