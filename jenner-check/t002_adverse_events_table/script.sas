/*------------------------------------------------------------
                  IMPORTING DATA
   (adapted for Jenner: original script used
    PROC IMPORT datafile="C:\Users\ANUPAMA\Downloads\ADAE.xls"
    dbms=xls range="ADAE$A1:O410"; replaced here with an inline
    sample ADAE-shaped dataset carrying the columns the rest of
    the program reads)
-------------------------------------------------------------*/

data adae;
	length usubjid $10 trta $15 aedecod $30 aebodsys $30 saffl $1;
	input usubjid $ trta $ trtan aedecod $ aebodsys $ aetoxgr saffl $;
	datalines;
001-001 Active_Drug_A 1 Headache Nervous_system_disorders 1 Y
001-001 Active_Drug_A 1 Nausea GI_disorders 2 Y
001-002 Active_Drug_A 1 Headache Nervous_system_disorders 2 Y
001-003 Active_Drug_A 1 Fatigue General_disorders 1 Y
001-004 Placebo 2 Nausea GI_disorders 1 Y
001-005 Placebo 2 Headache Nervous_system_disorders 1 Y
001-006 Placebo 2 Fatigue General_disorders 2 Y
001-007 Active_Drug_A 1 Rash Skin_disorders 1 Y
001-008 Active_Drug_A 1 Nausea GI_disorders 1 Y
001-009 Placebo 2 Rash Skin_disorders 2 Y
001-010 Placebo 2 Fatigue General_disorders 1 Y
001-011 Active_Drug_A 1 Diarrhea GI_disorders 1 Y
001-012 Active_Drug_A 1 Headache Nervous_system_disorders 1 Y
001-013 Placebo 2 Diarrhea GI_disorders 2 Y
001-014 Placebo 2 Headache Nervous_system_disorders 1 Y
001-015 Active_Drug_A 1 Fatigue General_disorders 1 N
;
run;

data adae;
	set adae;
	trta = tranwrd(trta, 'Active_Drug_A', 'Active Drug A');
	aedecod = tranwrd(aedecod, '_', ' ');
	aebodsys = tranwrd(aebodsys, '_', ' ');
run;

/*----------------------------------------------------------
               PROGRAMMING START
----------------------------------------------------------*/

/******STEP1*******/

data adae1;
	set adae;
	keep usubjid trta trtan aedecod aebodsys aetoxgr;
	where saffl='Y';
run;

/******STEP2******/

proc sort data=adae1 out=sort1;
	by usubjid aebodsys descending aetoxgr;
run;

data waesys;
	set sort1;
	by usubjid aebodsys descending aetoxgr;
	if first.aebodsys;
run;

proc freq data=waesys noprint;
	tables trta *aebodsys/out=freq_aebodsys;
run;

proc sort data=freq_aebodsys;
	by aebodsys;
run;

proc transpose data=freq_aebodsys out=ds1;
	by aebodsys;
	id trta;
	var count;
run;

data ds1;
	set ds1;
	length aedecod $100;
	drop _name_ _label_;
run;

/******STEP3******/

proc sort data=adae1 out=sort2;
	by usubjid aebodsys aedecod descending aetoxgr;
run;

data waedecod;
	set sort2;
	by usubjid aebodsys aedecod descending aetoxgr;
	if first.aedecod;
run;

proc freq data=waesys noprint;
	tables trta*aedecod*aebodsys/out=freq_aedecod;
run;
proc sql;
	create table all as select distinct trta ,count( distinct usubjid) as n from adae group by trta;
quit;


proc sort data=freq_aedecod;
	by aedecod  aebodsys;
run;

proc transpose data=freq_aedecod out=ds2;
	by aedecod  aebodsys;
	id trta;
	var count;
run;
data ds2;
	set ds2;
	drop _name_ _label_;
run;

/* NOTE: the original script also had `proc sort data=freq_a;` here —
   freq_a is never created anywhere in the program (likely meant
   freq_aedecod, already sorted two blocks above) and its output is
   never read by anything downstream (stack/stack2/stack3/final all
   descend from ds1/ds2/all), so it is dead code in the source and
   is omitted here rather than invented. */


/*****STEP4*****/

data stack;
	set ds1 ds2;
	rename Active_Drug_A=DRUGA;
	aedecod='     '||aedecod;
run;

proc sort data=stack;
	by aebodsys aedecod;
run;

data stack2;
length aebodsys $100;
set stack;
by aebodsys aedecod;
if aedecod='' and aebodsys ^='' then aedecod=aebodsys;run;

run;

/**********STEP5******************/


proc sql noprint;
	select count(distinct usubjid) into: bign1 from adae where trta='Placebo';
	select count(distinct usubjid) into: bign2 from adae where trta='Active Drug A';
run;

%put &bign1 &bign2;

proc sql;
	create table all as select distinct trta ,count( distinct usubjid) as n from adae group by trta;
quit;

proc transpose data=all out=all1;
	id trta;
    var  n;
run;
data all1;
	length _name_ $100;
	set all1;
	rename Active_Drug_A=DRUGA _NAME_=aedecod;
	if _name_='n' then _name_='TOTAL SUBJECTS WITH AN EVENT';
run;
data stack3;
	set all1 stack2;
	if DRUGA ^=. then pct_a = put(DRUGA,best.)||'  ('||put((DRUGA/&bign2)*100,4.1)||')';
	if Placebo ^= . then pct_p = put(Placebo,best.)||'  ('||put((Placebo/&bign1)*100,4.1)||')';
	drop druga placebo aebodsys;
run;

data final;
    retain col1 col2 col3;
	set stack3 (rename= (aedecod=col1 pct_a=col3 Pct_p=col2));
run;

proc print data=final;
	run;


/*--------------------------------------------------------------
    proc report
    (adapted for Jenner: original ODS RTF destination was a
     hardcoded local path, "C:\Users\ANUPAMA\Desktop\SAS\rep2.rtf";
     redirected here to a relative path)
--------------------------------------------------------------*/
ods rtf file ="./rep2.rtf" ;

title1 "Safety Population";

proc report data=final split='~'  ;
  column col1 col2 col3 ;
  define col1 / 'System Organ Class (%)~  Preferred Term (%)' style=[cellwidth=2.5in ]  ;
  define col2 / "Placebo~ N=%cmpres(&BIGN1)"style=[cellwidth=2.5in ] ;
  define col3 / "Treatment Group A~N=%cmpres(&BIGN2)" style=[cellwidth=2.5in];

run;

footnote 'MedDRA Version18.0';
ods rtf close;
