
/*Importing the data*/


proc import datafile="C:\Users\ANUPAMA\Downloads\ADRS.xls"
		    out=adrs
            dbms=xls replace;
            range="sheet1$A1:k101"; 
run;

/*-----------------------------------------------------------------------
      Programming Start
------------------------------------------------------------------------*/


/*----------ITTFL not present and all PARAMCD ='BOR'------------------------*/

data adrs1;
	set adrs;
/*	where ITTFL='Y' and paramcd='BOR';*/
	output;
	trt01p='Overall';
	output;
run;


/*STEP-2*/

proc freq data=adrs1 noprint;
tables trt01p*paramcd*avalc/out=freq nopercent;
run;


/*step-3*/

proc sort data=freq;
	by paramcd avalc;
run;

proc transpose data=freq out=tran1;
	by paramcd avalc;
	id trt01p;
	var count ;
run;
 data tran1;
 	set tran1;
	drop _name_ _label_;
run;


proc sql noprint;
	select count(distinct usubjid) into: bign1 from adrs1 where trt01p='Placebo';
	select count(distinct usubjid) into: bign2 from adrs1 where trt01p='Drug A';
	select count(distinct usubjid) into: bign3 from adrs1 where trt01p='Overall';
run;

%put &bign1 &bign2 &bign3;

data tran2;
	length avalc $100;
	set tran1;	
	format avalc $100.;
	informat avalc $100.;
	if DRUG_A ^=. then pct_a = put(DRUG_A,best.)||'  ('||put((DRUG_A/&bign2)*100,4.1)||')';
	if Placebo ^= . then pct_p = put(Placebo,best.)||'  ('||put((Placebo/&bign1)*100,4.1)||')';
	if Overall ^= . then pct_o = put(Overall,best.)||'  ('||put((Overall/&bign3)*100,4.1)||')';
	
	if avalc='CR' then avalc='COMPLETE RESPONSE (CR)';
	else if avalc='PR' then avalc='PARTIAL RESPONSE (PR)';
	else if avalc='SD' then avalc='STABLE DISEASE (SD)';
	else if avalc='PD' then avalc='PROGRESSIVE DISEASE (PD)';
	drop paramcd drug_a placebo overall;
	where avalc ^= 'NE';/*removing as per shell*/
run;





data final;
	set  tran2;
	retain avalc pct_p pct_a Pct_o;
	run;
	data final3;
    set final;
    if order = 1 then header_group = 'Display Header';
    else header_group = 'Data';
run;

proc sort data=final3;
    by header_group order;
run;

data final4;
	set final3;
	drop order header_group;
	rename pct_a=TRT_A pct_p=TRT_B pct_o=Total;
run;

proc print data=final4;
	run;

	/*--------------------------------------------------------------
    proc report
--------------------------------------------------------------*/
ods rtf file="C:\Users\ANUPAMA\Desktop\SAS\BOR_Tab.rtf" style=journal;

title1 "Best Overall Response per Investigator";
title2 "All Treated Subjects";
proc report data=final3 headline nowindows spacing=1 split='~' ;
    columns header_group avalc ("Number of Subjects (%)" pct_a pct_p pct_o);

    define header_group / order noprint  ;

    define AVALC / " " style(column)={cellwidth=2.5in just=left};
    define pct_a / "Trt A~(N=50)" style(column)={cellwidth=1.2in just=center};
    define pct_p / "Trt B~(N=50)" style(column)={cellwidth=1.2in just=center};
    define pct_o / "Total~(N=100)" style(column)={cellwidth=1.2in just=center};
 break before header_group / skip ol;
    compute before header_group;
        if header_group = 'Display Header' then do;
            line "BEST OVERALL RESPONSE (RECIST 1.1, CONFIRMATION OF RESPONSE REQUIRED):";
            line " ";
        end;
    endcomp;
  

run;

ods rtf close;

