/*------------------------------------------------------------
                  IMPORTING DATA
-------------------------------------------------------------*/

proc import datafile= "C:\Users\ANUPAMA\Downloads\ADAE.xls"
		    out=adae
            dbms=xls replace;
            range="ADAE$A1:O410"; 
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
proc sort data=freq_a;
	by aedecod;
run;




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

/*if first.aebodsys then aebodsys=upcase(aebodsys);*/
/*else if aebodsys='      '||upcase(aedecod);*/
/*/*if first.aebodsys then do;*/*/
/*druga=.; */
/*placebo=.;*/
/*end;*/
/*drop aedecod;*/
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
--------------------------------------------------------------*/
ods rtf file ="C:\Users\ANUPAMA\Desktop\SAS\rep2.rtf" ;

title1 "Safety Population";

proc report data=final split='~'  ;
  column col1 col2 col3 ;
  define col1 / 'System Organ Class (%)~  Preferred Term (%)' style=[cellwidth=2.5in ]  ;
  define col2 / "Placebo~ N=%cmpres(&BIGN1)"style=[cellwidth=2.5in ] ;
  define col3 / "Treatment Group A~N=%cmpres(&BIGN2)" style=[cellwidth=2.5in];

run;

footnote 'MedDRA Version18.0';
ods rtf close;



