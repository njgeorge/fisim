if(not defined $ARGV[1]){
	print "Usage: perl 9-makeiterator.pl <number of iterations> <number of FI locations>.\nUse grep Found 6-sim.pl to determine second argument\n";
	exit(0);
}

open OUT, ">10-iterateall.pl" or "Cannot open 10-iterateall.pl to write\n";

$numfi = $ARGV[0];
$numfilocs = $ARGV[1];

for($i = 0; $i < $numfilocs; $i++){
	print OUT "system \"perl 7-iterate.pl $numfi $i\"\;\n";
}

print "Iterator written to 10-iterateall.pl. $numfi fault injections for each of $numfilocs locations will be performed.\n";
print "Use 'perl 10-iterateall.pl' to run fault injections on each individual fault injection location\n";
