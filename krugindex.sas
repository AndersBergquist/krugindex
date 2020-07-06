* Instruktioner *;
* Ändra sasuser till önskat lib och kör skriptet. Då är det installerat och klart att köra.;
***Nedan kommer ett exempel på hur skiptet kan användas.;
/* ** Byt till dina uppgifter för infil, utfil, varNamn, grpNamn och koncVar;
proc ds2;
	data _null_;
		declare package sasuser.krugindex ki();

		method run();

			declare varchar(250) infil utfil;
			declare varchar(50) varNamn grpNamn koncVar;

			infil='work.intest';
			utfil='work.ds2Kindex';
			varNamn='Sun2000Grp'; *Variablen som koncentereras, t.ex. bransch eller utbildning;
			grpNamn='ast_Lan'; *Variabeln som beskriver grupper, t.ex. län;
			antalPerVarNamn='antal';
	
			ki.kindex(infil, utfil, varNamn, grpNamn, antalPerVarNamn );
		end;
		
	enddata;
run;quit;
*/

proc ds2;
	package sasuser.krugindex / overwrite=yes;

	forward kindex_helper;

		method kindex(varchar(250) infil, varchar(250) utfil, varchar(50) varNamn, varchar(50) grpNamn, varchar(50) antalPerVarNamn);
			declare varchar(8) inbibl utbibl;
			declare varchar(250) infilB utfilB;

			if index(infil,'.')>0 then do;
				inbibl=scan(infil,1,'.');
				infilB=scan(infil,2,'.');
			end;
			else inbibl='work';
			if index(utfil,'.')>0 then do;
				utbibl=scan(utfil,1,'.');
				utfilB=scan(utfil,2,'.');
			end;
			else utbibl='work';
			kindex_helper(inbibl, infilB, utbibl, utfilB, varNamn, grpNamn, antalPerVarNamn);
		end;

		method kindex_helper(varchar(8) inbibl, varchar(250) infil, varchar(8) utbibl, varchar(250) utfil, varchar(50) varNamn, varchar(50) grpNamn, varchar(50) antalPerVarNamn);
			declare varchar(258) intabell uttabell;

			intabell=inbibl || '.' || infil;
			uttabell=utbibl || '.' || utfil;
			sqlExec('create table work.totGrpSum as select ' || varNamn || ' as varNamn, ' || grpNamn || ' as grpNamn, sum( ' || antalPerVarNamn || ') as grpKoncVar from ' || intabell || ' group by ' || varNamn || ', ' || grpNamn);
			sqlExec('create table work.totJmfSum as select ' || varNamn || ' as varNamn, sum( ' || antalPerVarNamn || ') as jmfKoncVar from ' || intabell || ' group by ' || varNamn);
			sqlExec('create table work.totGrpjmfSum as select t2.varNamn, t1.grpNamn, t1.grpKoncVar, sum(t2.jmfKoncVar,-t1.grpKoncVar) as jmfAntal
                     from work.totJmfSum t2 left join work.totGrpSum t1 on (t2.varNamn=t1.varNamn)');
			sqlExec('drop table work.totGrpSum');
			sqlExec('drop table work.totJmfSum');
			sqlExec('create table work.totAntal as select grpNamn, sum(grpKoncVar) as grpSumAntal, sum(jmfAntal)as jmfSumAndel from work.totGrpjmfSum group by grpNamn');
			sqlExec('create table work.totAndel as select t1.varNamn, t2.grpNamn, (t1.grpKoncVar/t2.grpSumAntal) as grpAndel, (t1.jmfAntal/t2.jmfSumAndel) as jmfAndel
                     from work.totGrpjmfSum t1 join work.totAntal t2 on (t1.grpNamn=t2.grpNamn)');
			sqlExec('drop table work.totGrpJmfSum');
			sqlExec('drop table work.totAntal');
			sqlExec('create table ' || uttabell || ' as select grpNamn as ' || grpNamn || ', (sum(abs(grpAndel-jmfAndel))) as k_index from work.totAndel group by ' || grpNamn);
			sqlExec('drop table work.totAndel'); 

		end;
	endpackage;
run;quit;


