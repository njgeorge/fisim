use strict;

my $verbose = 0;

if($ARGV[0] eq "verbose"){
	$verbose = 1;
}

my $i; my $j; my $k; my $uuid;

my $line; my $subckttype; my $subcktnetlist; my $net;
my $compname; my $comptype; my $compnetlist;
my $expression; my $newexpression; my $token;
my $lhstoken;

my $within; my $allowelaborate; my $completed;
my $ordered; my $afterequals; my $allinputsready;
my $compexpressed;

my %componentlines; my %expressions; my %exprnets;
my %newnets; my %tempcomponentlines; 
my %inputnets; my %noninputnets;
my %computednets;

my @tempexpressions; my @readyexpressions;

open NETIN, "newnetlist" or die "Cannot open newnetlist to read\n";
open EXPIN, "explist" or die "Cannot open explist to read\n";

# Open expressions list and populate exprnets and expressions data structures
while($line = <EXPIN>){					
	if($line =~ /^ends $subckttype$/){
		$within = 0;
		next;
	}
	if($within == 1){
		#print "Found for $subckttype, expression: $line";
		push @{$expressions{$subckttype}}, $line;
	}
	if($line =~ /^subckt\s(\w+)\s(.+)$/){
		$subckttype = $1;
		$subcktnetlist = $2;
		while($subcktnetlist =~ /(\w+)\s*/g){
			push @{$exprnets{$subckttype}}, $1;
		}
		$within = 1;
	}
}

if($verbose){ print "Expressions read from file explist\n"; for $subckttype(keys %exprnets){ print "$subckttype nets\n"; for($i = 0; $i <= $#{$exprnets{$subckttype}}; $i ++){ print "$exprnets{$subckttype}[$i] "; } print "\n$subckttype expressions\n"; for($i = 0; $i <= $#{$expressions{$subckttype}}; $i ++){ print "$expressions{$subckttype}[$i]"; } print "\n"; } }

# Open newnetlist and populate componentlines and componenttypes
if($verbose){ print "Beginning read of newnetlist file\n\n"; }
while($line = <NETIN>){
	if($line =~ /^ends $subckttype$/){
		$within = 0;
		next;
	}
	if($within == 1){
		push @{$componentlines{$subckttype}}, $line;
		#$line =~ /^(\w+)\s(\w+)\s(.+)$/;
		#$compname = $1; $comptype = $2; $compnetlist = $3;
		#if(defined $componenttypes{$subckttype}{$comptype}){ $componenttypes{$subckttype}{$comptype}++; 
		#} else { $componenttypes{$subckttype}{$comptype} = 1; }
	}
	if($line =~ /^subckt\s(\w+)\s?(.*)$/){
		$subckttype = $1;
		$subcktnetlist = $2;
		while($subcktnetlist =~ /(\w+)\s*/g){
			push @{$exprnets{$subckttype}}, $1;
		}
		if(not defined $expressions{$subckttype}){
			if($verbose){ print "Expressions for $subckttype not found, will attempt to decompose\n"; }
			$within = 1;
		}
	}
}

if($verbose){ print "\nComponent lines read and populated from newnetlist file\n"; for $subckttype(keys %componentlines){ print "$subckttype\n"; for($i = 0; $i <= $#{$componentlines{$subckttype}}; $i++){ print $componentlines{$subckttype}[$i]; } print "\n"; } print "End of componentlines from newnetlist file\n"; }

$uuid = 0;
%tempcomponentlines = %componentlines;
$completed = 0;
while(!$completed){
	#print "Starting/Starting over\n";
	$completed = 1;
	for $subckttype(keys %tempcomponentlines){
		#print "$subckttype\n";
		$compexpressed = 1;
		@tempexpressions = ();
		for($i = 0; $i <= $#{$tempcomponentlines{$subckttype}}; $i++){
			$line = $tempcomponentlines{$subckttype}[$i];
			$line =~ /(\w+) (\w+) (.+)/;
			$compname = $1; $comptype = $2; $compnetlist = $3; # print "$line";

			$j = 0; %newnets =();
			while($compnetlist =~ /(\w+)\s*/g){
				$newnets{$exprnets{$comptype}[$j]} = $1; #print "$exprnets{$comptype}[$j]($1) ";
				$j ++;
			} #print "\n";

			if(defined $expressions{$comptype}){
				#print "$compname ($comptype) can be expressed now\n";
				#delete $tempcomponentlines{$subckttype}[$i];
				for $expression(@{$expressions{$comptype}}){
					$newexpression = "";
					while($expression =~ /((\w+)|([\(\)\&\|\!\^=]))/g){
						$token = $1;
						if($token =~ /^\w+$/){
							if(defined $newnets{$token}){
								$token = $newnets{$token};
							} else{
								$token .= "_$compname";
								#print "Renamed\n";
							}
						}
						$newexpression .= $token." ";
					}
					$newexpression .= "\n";
					push @tempexpressions, $newexpression;
					#print "$newexpression";
				} #print "\n";
			} else{
				#print "!!! $compname cannot be expressed now\n";
				$compexpressed = 0;
				$completed = 0;
			}
		}
		if($compexpressed){
			$uuid ++;
			@{$expressions{$subckttype}} = @tempexpressions;
			#print "All components of $subckttype expressed\n";
			delete $tempcomponentlines{$subckttype};
		}
		#print "\n";
	}
}

if($verbose){
	print "Expressions converted from componentlines for top level\n";
	$subckttype = "main";
	#for $subckttype(keys %componentlines){
		print "$subckttype\n";
		if(defined $expressions{$subckttype}){
			for($i = 0; $i <= $#{$expressions{$subckttype}}; $i++){
				print $expressions{$subckttype}[$i];
			}
		} else{
			for($i = 0; $i <= $#{$componentlines{$subckttype}}; $i++){
				print $componentlines{$subckttype}[$i];
			}
		}
		print "\n";
	#}
}

# Identify input nets and non-input nets of main circuit
$subckttype = "main";
for $expression (@{$expressions{$subckttype}}){
	#print "$expression";
	$afterequals = 0;
	while($expression =~ /((\w+)|([=]))/g){
		$token = $1;
		if($afterequals){
			if((not defined $inputnets{$subckttype}{$token}) && (not defined $noninputnets{$subckttype}{$token})){
				$inputnets{$subckttype}{$token} = 1;
			}
		}
		if($token eq "="){
			$afterequals = 1;
		}
		if(!$afterequals){
			delete $inputnets{$subckttype}{$token};
			$noninputnets{$subckttype}{$token} = 1;
		}
	}
}

if($verbose){ print "Inputs: "; for $net (keys %{$inputnets{"main"}}){ print "$net "; } print "\n"; }

# Perform ordering so that there are no hazards because of sequentialization for the top level circuit.
$subckttype = "main";
$ordered = 0;
while($ordered == 0){
	$ordered = 1;
	for($i = 0; $i<= $#{$expressions{$subckttype}}; $i++){
		#print $expressions{$subckttype}[$i];
		if($expressions{$subckttype}[$i] eq "XXXX\n"){ next; }
		$ordered = 0;
		$afterequals = 0;
		$allinputsready = 1;
		while($expressions{$subckttype}[$i] =~ /((\w+)|([=]))/g){
			$token = $1;
			if($afterequals){ #print "$token "; #if(defined $inputnets{$subckttype}{$token}){ print "(input) "; }
				if(defined $noninputnets{$subckttype}{$token}){ #print "(non-input) "; 
					if(not defined $computednets{$subckttype}{$token}){
						$allinputsready = 0;
					}# else{ print "(ready) "; }
				}
			}
			if($token eq "="){ $afterequals = 1; }
			if(!$afterequals){ $lhstoken = $token; }
		}
		if($allinputsready){
			$computednets{$subckttype}{$lhstoken} = 1;		# Record that lhs token has been computed
			push @readyexpressions, $expressions{$subckttype}[$i];	# 
			$expressions{$subckttype}[$i] = "XXXX\n";
		}# else{ print "\n"; }
	}
}
@{$expressions{$subckttype}} = @readyexpressions;
if($verbose){ 
	print "\n$subckttype: $#{$expressions{$subckttype}} lines after ordering\n"; 
	for $expression (@{$expressions{$subckttype}}){ 
		print $expression; 
	} 
}

# At this point, main circuit expressions have been created and ordered to avoid hazards from sequentialization.
# Write input nets, non-input nets, and main expressions into intermediate code file.

open OUT, ">4-intermediate.code" or die "Cannot open 4-intermediate.code to write\n";

print OUT "\# Intermediate code generated by backend.pl, forms intput for codegen.pl\n\n";

print OUT "# Inputs\n";
for $net (sort keys %{$inputnets{"main"}}){
	print OUT "$net ";
} print OUT "\n\n";
print OUT "\# Please remove nets in the following line\n";
print OUT "\# that are not considered output nets.\n";
print OUT "\# Separate nets with whitespace. If none are removed,\n";
print OUT "\# all non-input nets will be considered as output nets\n\n";
print OUT "\# Noninputs\n"; 
for $net (sort keys %{$noninputnets{"main"}}){
	print OUT "$net ";
}
print OUT "\n\n\# Expressions\n";

for $expression (@{$expressions{"main"}}){
	print OUT $expression;
}

print "Intermediate code written into 4-intermediate.code\n";
close OUT;
exit(0);

# Code Generate Section

# Prepare expressions by prefixing identifiers with $
for $expression (@{$expressions{"main"}}){
	#print "Going to perlify $expression";
	$newexpression = "";
	while($expression =~ /((\w+)|([\(\)\+\-\&\|\^=]))/g){
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

open OUT, ">sim.pl" or die "Cannot open sim.pl to write\n";
print OUT "\# Code generated by backend.pl\n\n"; print "\# Code generated by backend.pl\n\n"; 

# For each input net, assign random input.
print OUT "\# Assign random inputs\n"; print "\# Assign random inputs\n"; 
for $net (sort keys %{$inputnets{"main"}}){
	print OUT "\$$net = int(rand(2))\; "; print "\$$net = int(rand(2))\; "; 
	print OUT "print \"$net=\$$net \"\;\n"; print "print \"$net=\$$net \"\;\n"; 
}
print OUT "print \"\\n\"\;\n"; print "print \"\\n\"\;\n"; 

# Output expressions
print OUT "\n\# Equivalent circuit expressions\n"; print "\n\# Equivalent circuit expressions\n"; 
for $expression (@readyexpressions){
	print OUT $expression; print $expression; 
}

print OUT "\n\# Print results\n"; 
print "\n\# Print results\n"; 
for $net(sort keys %{$noninputnets{"main"}}){
	print OUT "print \"$net=\$$net \"\;\n";
	print "print \"$net=\$$net \"\;\n";
}
print OUT "print \"\\n\"\;\n"; 
print "print \"\\n\"\;\n"; 

close OUT;
