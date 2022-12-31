/***  Count Code Snippet. Sorts then uses the FIRST method from sas to add a 1 to the first instance of Var_to_Count  ***/

%Let Table_in = SAMPLE_DATA;
%Let Table_out = Count_Items;
%Let Var_To_Count = Items;

proc sort data= &Table_in.;
	by &Var_To_Count.;
run;

data &Table_out.;
	set &Table_in.;
	by &Var_To_Count.;
	if FIRST.&Var_To_Count. then
		Count = 1;
	else Count = 0;
run;
