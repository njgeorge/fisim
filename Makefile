all:
	yapp -m netlistparser 1-grammar.yp
	perl 2-parse.pl
	perl 3-backend.pl
	vi 4-intermediate.code
	perl 5-codegen.pl
	grep Found 6-sim.pl
	perl 9-makeiterator.pl

code: 
	vi 5-codegen.pl
	perl 5-codegen.pl
	vi 6-sim.pl
	#perl 6-sim.pl

clean:
	rm newnetlist
	rm netlistparser.pm
	rm 4-intermediate.code
	rm 6-sim.pl
	rm 8-results/stats*.txt
	rm 10-iterateall.pl
