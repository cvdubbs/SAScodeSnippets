/*** Send an Email notification ***/
%macro sendit(to,subj);
filename mymail email "&to" subject="&subj" type="text/html" CT= "text/html" lrecl=256;
data _null_;
	file mymail;
	put 'Put your message here!';
	put 'Second line here, before link:';
	put '<a href="C:\File_To_Share">Click to go to shared file</a>';
RUN;
%mend;

%sendit(You@gmail.com, EmailTitle)

/*** Used to verify that the number of observations in two tables matches after a join ***/

%let Library = LibraryName;
%let Table_List = Table_1 Table_2 Table_3;

%macro append;
%local i next_table_on;
%let i=1;
%do %while (%scan(&Table_List, &i) ne );
   %let next_table = %scan(&Table_List, &i);

proc sql;
create table &next_table._ct as
select "&next_table." as table,
        count(*) as count_rows
from &Library..&next_table.;
quit;

%let i = %eval(&i + 1);
%end;
run;
%mend append;
%append;


%macro append2;
%local i next_table_on;
%let i=1;
DATA Count_Checks;
length table $50;
SET
%do %while (%scan(&Table_List, &i) ne );
   %let next_table = %scan(&Table_List, &i);
  &next_table._ct
%let i = %eval(&i + 1);
%end;
;
run;
%mend append2;

%append2;


/*** Delete Tables ***/
PROC Datasets library=WORK NODETAILS NOLIST;
	delete TABLE1;
	delete TABLE2;
	delete TABLE3;
	delete TABLE4;
RUN;


/*** DROP FIELDS ***/
DATA WORK.TABLE1;
DROP FIELD_TO_DROP1 FIELD_TO_DROP2;
RUN;


/*** SORT and MERGE ***/
PROC SORT DATA=INPUT_TABLE_1;
BY VAR1;
RUN;

PROC SORT DATA=INPUT_TABLE_2;
BY VAR1;
RUN;

DATA OUTPUT_TABLE;
MERGE INPUT_TABLE_1 INPUT_TABLE_2;
BY VAR1;
RUN;


/*** SORT AND PULL DIFFERENCES ***/

proc sort data=INPUT_TABLE_1;
   by VAR1 VAR2;
run;
proc sort data=INPUT_TABLE_2;
   by VAR1 VAR2;
run;

Data OUTPUT_TABLE;
merge INPUT_TABLE_1 (in=a) INPUT_TABLE_2(in=b);
by VAR1 VAR2;
if a and not b;
run;

%LET run_dt = JUN2019;

/*** use ODS to create and export Excel Report ***/
ods _all_ close;
  ods tagsets.excelxp
  file="/Location/FileName.xls"
           style=fancyprinter
                options(orientation="landscape"
                        embedded_titles='yes'
                           wraptext="no"
                         suppress_bylines='yes'
                           autofit_height="yes"
                        frozen_headers="6"
                         row_repeat="5");
title1 justify=left color=black height=10pt font=arial bold "Workbook Title";
title2 justify=left color=black height=10pt font=arial bold "Sheet Title";

ods tagsets.ExcelXP options (absolute_column_width="10,10" sheet_label= ' ' sheet_name="First_Sheet");
PROC REPORT DATA=TABLE_TO_LOAD_IN style (header /*column*/)={background =LIGB font_face=arial foreground=black font_size=1 fontweight=bold};           
column VAR1 VAR2;
define VAR1/"VAR1";
define VAR2/"VAR2";
RUN;

ods tagsets.excelxp close;

/*** Query a Table Server Side ***/
proc sql;
CONNECT TO SERVER (user=USERNAME password=PASSWORD DSN=SERVER_DSN schema=SERVER_SCHEMA );	
create table WORK.SERVER_SIDE_PULL_TABLE as 
select DISTINCT *,
	"Y" AS CREATED_CHECK
FROM connection to SERVER(
	SELECT	
	a.FIELD1,
	a.FIELD2
	FROM DSN.SCHEMA.TABLE a			
	where (a.FIELD3 = 'TAG'));
DISCONNECT FROM SERVER;	
quit;

/*** Simply combine tables ***/
DATA NEW_TBL_NAME;
SET TABLE1 TABLE2;
RUN;

/*** Pull YEAR from Datetime ***/
(INTNX("YEAR",DATEPART(A.PRIMARY_SVC_DATE),0,"B")) FORMAT=YEAR4. AS YEAR;


/*** Set Date Automatically ***/
%LET ENDDATE = "%sysfunc(intnx(month, %sysfunc(today()),-2,e), date9.)"D;

/*** A simple left join using Hash. Incredible increased speed when dealing with large tables ***/

data OUTPUT_TABLE(drop = rc);
LENGTH VAR_ADDED $2;

 declare Hash groupz(dataset:'TABLE_JOINING_FROM');
 	groupz.definekey('VAR_MATCH_ON_ONE','VAR_MATCH_ON_TWO');
 	groupz.definedata('VAR_ADDED');
 	groupz.definedone();
 do until(eof1);
 	set TABLE_JOINING_TO=eof1;
 		rc = groupz.FIND();
		IF rc ne 0 THEN DO;
			VAR_ADDED = '';
		END;
OUTPUT;
END;
STOP;
RUN;

/*** Hash Inner Join ***/

data TABLE_OUT(drop=rc:);
   if 0 then set TABLE_TWO TABLE_THREE;
   if _N_ = 1 then do;
      declare hash h1(dataset:"TABLE_TWO");
      h1.defineKey('VAR_JOIN_ON');
      h1.defineData('VAR_BRING_IN', 'VAR_BRING_IN_TWO');
      h1.defineDone();
   end;
   
   set TABLE_ONE();
   rc1=h1.find();

   if rc1=0;
run;

/*** Hash Inner Join three tables ***/

data TABLE_OUT(drop=rc:);
   if 0 then set TABLE_TWO TABLE_THREE;
   if _N_ = 1 then do;
      declare hash h1(dataset:"TABLE_TWO");
      h1.defineKey('VAR_JOIN_ON');
      h1.defineData('VAR_BRING_IN', 'VAR_BRING_IN_TWO');
      h1.defineDone();
      declare hash h2(dataset:"TABLE_THREE");
      h2.defineKey('VAR_JOIN_ON');
      h2.defineData('VAR_BRING_IN_TABTHREE');
      h2.defineDone();
   end;
   
   set TABLE_ONE(keep=name Salary);

   rc1=h1.find();
   rc2=h2.find();

   if rc1=0 & rc2=0;
run;

