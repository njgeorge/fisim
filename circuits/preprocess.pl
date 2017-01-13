if(not defined $ARGV[1]){
	print "Usage: perl preprocess.pl <infile> <outfile>\n";
	exit(0);
}

open IN, $ARGV[0] or die "Cannot open $ARGV[0]\n";
open OUT, ">$ARGV[1]" or die "Cannope open $ARGV[1] to write\n";

while($line = <IN>){
	$line =~ s/GND\!/GND/g;
	$line =~ s/VDD\!/VDD/g;
	$line =~ s/vdd\!/vdd/g;
	$line =~ s/\s0\s/ gnd /g;
	$line =~ s/\\\#0//;
	$line =~ s/global.*\n//;
	print $line;
	print  OUT $line;
}
