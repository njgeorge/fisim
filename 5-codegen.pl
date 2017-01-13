use strict;

my $startexpressions = 0; my $verbose = 0;
my $genverbose = 0;
my $regioncount = 0;

my $expression; my $newexpression;
my $line; my $net; my $token;
my $outputfilename;

my %inputnets; my %outputnets;

my @expressions; my @readyexpressions;

open IN, "4-intermediate.code" or die "Cannot find intermediate.code, run backend.pl\n";
open OUT,">6-sim.pl" or die "Cannot open 6-sim.pl to write\n";

# Parse file to gather inputs, outputs and expressions
while($line = <IN>){
	if($startexpressions == 1){
		push @expressions, $line;
	}
	if($line =~ /^\# Inputs$/){
		$line = <IN>;
		while($line =~ /(\w+)\s*/g){
			$net = "$1";
			$inputnets{$net} = 1;
		}
	}
	if($line =~ /^\# Noninputs$/){
		$line = <IN>;
		while($line =~ /(\w+)\s*/g){
			$net = "$1";
			$outputnets{$net} = 1;
		}
	}
	if($line =~ /^\# Expressions$/){
		$startexpressions = 1;
	}
}

if($verbose){ print "Found inputs: "; for $net(sort keys %inputnets){ print "$net "; } print "\nFound outputs: "; for $net (sort keys %outputnets){ print "$net "; } print "\nFound expressions:\n"; for $expression (@expressions){ print $expression; } }

# Prepare expressions by prefixing identifiers with $
for $expression (@expressions){
	$newexpression = "";
	while($expression =~ /((\w+)|([\(\)\+\-\&\|\^=!]))/g){
		$token = $1;
		if($token =~ /^\w+$/){
			$newexpression .= "\$".$token." ";
		} else{
			$newexpression .= $token." ";
		}
		if($token eq "="){
			$newexpression .= "int( ";
		}
	}
	$newexpression .= ")\;\n";
	push @readyexpressions, $newexpression;
}

print OUT "\# Code generated by backend.pl\n\n"; # print "\# Code generated by backend.pl\n\n"; 

# For each input net, assign random input.
print OUT "\# Assign random inputs\n"; 
for $net (sort keys %inputnets){
	print OUT "\$$net = int(rand(2))\;\n";
}
if($genverbose){
	print OUT "\n\# Print input assignments\n";
	for $net (sort keys %inputnets){
 		print OUT "print \"$net=\$$net \"\;\n"; 
	}
	print OUT "print \"\\n\"\;\n";
}

# Output expressions
print OUT "\n\# Gold calculation\n";
$regioncount = 0;
for $expression (@readyexpressions){
	print OUT $expression;
	$regioncount++;
}

# Save golden outputs
print OUT "\n\# Save Gold outputs\n";
for $net (sort keys %outputnets){
	print OUT "\$gold_$net = \$$net\;\n";
}

# Print results
if($genverbose){
	print OUT "\n\# Print gold results\n"; 
	for $net(sort keys %outputnets){
		print OUT "print \"$net=\$gold_$net \"\;\n";
	}
	print OUT "print \" (gold)\\n\"\;\n"; 
}

# Generate code for fault injection pass
print OUT "\n\# Fault Injection Section: Found $regioncount possible regions to inject\n";
print OUT "if(\$ARGV[0] == -1){\n";
print OUT "\t\$regionselect = int(rand($regioncount));\n";
print OUT "} else{\n";
print OUT "\t\$regionselect = \$ARGV[0]\;\n";
print OUT "}\n\n";

$regioncount = 0;
for $expression (@readyexpressions){
	print OUT $expression;
	$expression =~ /^(\$.+)(\s+=.+)/;
	print OUT "if(\$regionselect == $regioncount){\n";
	print OUT "\t$1 = ($1 ^ 0x01)\;\n}\n\n";
	$regioncount++;
}

# Print results
if($genverbose){
	print OUT "\# Print results\n"; 
	for $net(sort keys %outputnets){
		print OUT "print \"$net=\$$net \"\;\n";
	}
	print OUT "print \"\\n\"\;\n"; 
}

# Generate code to compare and report mismatch
print OUT "\n\# Code to compare outputs with golden and to report mismatch\n";
print OUT "\$ACE = 0\;\n";

# Make sure to open this file in append mode.
$outputfilename = "8-results/stats-\$ARGV[0].txt";
print OUT "open OUT, \">>$outputfilename\" or die \"Cannot open $outputfilename to write\\n\"\;\n\n";

print OUT "\# print \"Mismatch: \"\;\n";
for $net (sort keys %outputnets){
	print OUT "if(\$gold_$net != \$$net){\n";
	print OUT "\t\$ACE = 1\;\n";
	print OUT "\t\# print \"$net \"\;\n"; 
	print OUT "\tprint OUT \"$net \"\;\n";
	print OUT "}\n\n";
}

print OUT "if(\$ACE == 0){\n";
if($genverbose){ print OUT "\tprint \"unACE\\n\"\;\n"; }
print OUT "\tprint OUT \"unACE\\n\"\;\n";
print OUT "} else{\n";
if($genverbose){ print OUT "\tprint \"\\n\"\;\n"; }
print OUT "\tprint OUT \"\\n\"\;\n";
print OUT "}\n";

close OUT;

print "Code generated into 6-sim.pl. Use 7-iterate.pl to run a campaign. Stats collected in 8-stats-<loc>.txt\n";
