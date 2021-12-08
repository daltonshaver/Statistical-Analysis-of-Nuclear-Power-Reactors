libname NPP '/home/u59781300/STAT 3010 NPP';

proc format;
	value Generation	1 = "Low Capacity"
						2 = "Medium Capacity"
						3 = "High Capacity"
						4 = "Very High Capacity";

********************************** Dataset Import & Setup;

proc import datafile='/home/u59781300/STAT 3010 NPP/NPP Dataset Import.xlsx'
	dbms=xlsx
	out=work.dataframe replace;
	getnames=yes;
	
data NPP.dataframe;
	set work.dataframe;
	rename 'Construction Start'n=CSY 'Grid Connection'n=GCY
	'Reactor Type'n=Type 'Gross Electrical Capacity [MW]'n='Gross Electrical Capacity'n
	'Total Net Capacity [MW]'n='Reference Unit Power'n;
	drop model operator 'nsss supplier'n 'Thermal Capacity [MW]'n 'Commercial Operation'n;
run;

data NPP.dataframe;
	set NPP.dataframe;
	label CSY="Construction Start Year" GCY="Grid Connection Year" Type="Reactor Type"
	'EAF %'n="Energy Availability Factor" 
	'Gross Electrical Capacity'n="Gross Electrical Power Generation (MW)"
	'Reference Unit Power'n="Net Electrical Power Generation (MW)"; 			
run;

data NPP.dataframe;
	set NPP.dataframe;
	if Country='USA' or Country='CANADA' or Country='MEXICO' 
	then Region='America - Northern';
	if Country='ARGENTINA' or Country='BRAZIL' 
	then Region='America - Latin';
	if  Country='CHINA' or Country='JAPAN' or Country='KOREA,REP.OF' or 
	Country='TAIWAN,CHINA' 
	then Region='Asia - Far East';
	if Country='BANGLADESH' or Country='INDIA' or Country='IRAN,ISL.REP' or 
	Country='KAZAKHSTAN' or Country='PAKISTAN' or Country='UAE'  
	then Region='Asia - Middle East and South';
	if Country='BELGIUM' or Country='BULGARIA' or Country='CZECH REP.' or 
	Country='FINLAND' or Country='FRANCE' or Country='GERMANY' or 
	Country='HUNGARY' or Country='ITALY' or Country='LITHUANIA' or 
	Country='NETHERLANDS' or Country='ROMANIA' or Country='SLOVAKIA' or 
	Country='SLOVENIA' or Country='SPAIN' or Country='SWEDEN' or 
	Country='SWITZERLAND' or Country='UK'
	then Region='Europe - Western';
	if Country='ARMENIA' or Country='BELARUS' or Country='TURKEY' or 
	Country='RUSSIA' or Country='UKRAINE' 
	then Region='Europe - Central and Eastern';
	if Country='SOUTH AFRICA'
	then Region='Africa';
run;

****************************** 5) Descriptive Statistics;
*Variable Information;
proc contents data=NPP.dataframe;

*Descriptive Statistics for Quantitative Variables;
proc means data=NPP.dataframe
	 min q1 median mean q3 max std qrange maxdec=2;

*Frequency Tables for Categorical Variables;
proc freq data=NPP.dataframe;
	tables country region status type;
	
	
************************** Histograms and Boxplots for Quantitative Variables;
%macro desc_stat(var=, name=, col=, num1=, num2=, lab=);
	proc sgplot data=NPP.dataframe;
		histogram &var/ scale=count fillattrs=(color=&col) dataskin=crisp;	
		title "Figure &num1: Histogram of &name";
		xaxis label="&lab";
	
	proc sgplot data=NPP.dataframe;				
		hbox &var/ fillattrs=(color=&col) lineattrs=(color='black') dataskin=crisp;
		title "Figure &num2: Boxplot of &name";
		xaxis label="&lab";
%mend;  

%desc_stat(var="Gross Electrical Capacity"n, name=Gross Electrical Capacity, col=mogy, 
	num1=1.1, num2=1.2, lab=Megawatts (MW));
%desc_stat(var="Reference Unit Power"n, name=Reference Unit Power, col=vlibg, 
	num1=2.1, num2=2.2, lab=Megawatts (MW));
%desc_stat(var="EAF %"n, name=Energy Availability Factor, col=librgr, 
	num1=3.1, num2=3.2, lab=Percentage);
%desc_stat(var=CSY, name=Construction Start Year, col=stpk, 
	num1=4.1, num2=4.2, lab=Number of Years);
%desc_stat(var=GCY, name=Grid Connection Year, col=lirp, 
	num1=5.1, num2=5.2, lab=Number of Years);
%desc_stat(var="Shutdown Date"n, name=Shutdown Date, col=bigb, 
	num1=6.1, num2=6.2, lab=Number of Years);
%desc_stat(var=age, name=Age of Reactor, col=bilg, num1=7.1, 
	num2=7.2, lab=Number of Years);


************************* 6) Creation of Categorical Variable;

*Examined percentiles of variable;
proc univariate data=NPP.dataframe;
	var 'Reference Unit Power'n;
	
*Creation of Categorical Variable from Quantitative Variable;
data NPP.dataframe;
	set NPP.dataframe;
	if 'Reference Unit Power'n < 479 then 'Power Generation'n = 1;
	if 479 <= 'Reference Unit Power'n < 1067 then 'Power Generation'n = 2;
	if 1067 <= 'Reference Unit Power'n < 1277 then 'Power Generation'n = 3;
	if 'Reference Unit Power'n >= 1277 then 'Power Generation'n = 4;	

data NPP.dataframe;
	set NPP.dataframe;
	format 'Power Generation'n Generation.;

proc freq data=NPP.dataframe;
	tables 'Power Generation'n;

proc sgplot data=NPP.dataframe;
	hbar 'Power Generation'n/ fillattrs=(color='lioy') dataskin=crisp;
	title Figure 8.1: Bar Chart of Power Generation;	
	

******************************* 7) Multivariate Analyses;

****Analysis 1: Region & Status;
*Contingency Table;
proc freq data=NPP.dataframe;
	tables region*status;
	ods output CrossTabFreqs=ConTable;
	
*100% Stacked Bar Chart;                                                                    
proc sgplot data=ConTable;					
	vbar region / group=status response=frequency dataskin=crisp;	
	title Figure 9.1: Stacked Bar Chart of Region by Status;

****Analysis 2: Type & EAF %;
*Creation of Operation dataframe;
data NPP.operational_df;
	set NPP.dataframe;
	where Status='Operational';
	
*Stratified Analysis;
proc means data=NPP.operational_df 
min q1 median mean q3 max std qrange maxdec=2;
	var 'EAF %'n;
	class type;
	title ; 
	
*Side-by-side boxplots;
proc sgplot data=NPP.operational_df;
	hbox 'EAF %'n / category=type group=type;
	title Figure 10.1: Side-by-Side Boxplots of Energy Availability Factor by Reactor Type;
	
**Sampled Stratified Confidence Intervals;
*Sample using SQL;
proc sql outobs=80;
	CREATE TABLE NPP.sample_df AS 
	SELECT *
	FROM NPP.operational_df
	ORDER BY ranuni(25578);
quit;	

*Stratified Confidence Intervals;	
proc means data=NPP.sample_df mean lclm uclm alpha=0.05 maxdec=2;                             
	var 'EAF %'n;
	class type;
	title ;

****Analysis 3: GCY & Gross Electrical Capacity;
*Scatterplot;
proc sgplot data=NPP.dataframe;
	reg x = GCY y = 'Gross Electrical Capacity'n/ markerattrs=(symbol=circle size=5 color='darkgreen');
	title Figure 11.1: Scatterplot of Gross Electrical Capacity by Grid Connection Year;                   


	