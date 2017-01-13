use strict;

if(not defined $ARGV[1]){
	print "Usage: perl iterate.pl <#FI> <regionselect>\n";
	exit(0);
}

my $i; my $line; my $net; my $filename;
my $unacecount = 0; my $totalcount = 0;
my $starttime; my $endtime;

my %distribution;

$filename = "8-results/stats-$ARGV[1].txt";

system "rm $filename";

$starttime = time();

for ($i = 0; $i < $ARGV[0]; $i++){
	system "perl 6-sim.pl $ARGV[1]";
	#print "Completed fault injection \#".($i+1)."\n";
}
$endtime = time();
print "Done in ".($endtime-$starttime)." seconds.\n";

print "Campaign done, output written to $filename\n";
exit(0);
open IN, $filename or die "Cannot find $filename\n";

while($line = <IN>){
	if($line =~ /unACE/){
		$unacecount ++;
	} else{
		while($line =~ /(\w+)\s*/g){
			if(defined $distribution{$1}){
				$distribution{$1} ++;
			} else{
				$distribution{$1} = 1;
			}
		}
	}
	$totalcount ++;
}

print "AVF = (($totalcount - $unacecount)/$totalcount) * 100 = ".((($totalcount - $unacecount)/$totalcount) * 100)."\n";

print "Distribution of affected outputs\n";

for $net (sort keys %distribution){
	print "$net: $distribution{$net} (".($distribution{$net}/$totalcount*100)."\%)\n";
}

close IN;
