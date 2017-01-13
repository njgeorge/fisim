use Parse::Lex;
use netlistparser;

#open IN, "circuits/64BitKSA-ready.netlist" or die "Cannot find netlist\n";
#open IN, "circuits/32BitKSA-ready.netlist" or die "Cannot find netlist\n";
#open IN, "circuits/16BitKSA-ready.netlist" or die "Cannot find netlist\n";
#open IN, "circuits/8BitKSA-ready.netlist" or die "Cannot find netlist\n";
open IN, "circuits/4BitKSA-ready.netlist" or die "Cannot find netlist\n";
#open IN, "circuits/16BitMul-ready.netlist" or die "Cannot find netlist\n";

my $verbose = 0;

@patterns = qw(
	comment		(\/\/.*[\n])|(Thru.*\n)
	quotedstring	[\"].+[\"]
	subcktkeyword 	subckt
	endskeyword 	ends
	langkeyword	lang
	globalkeyword	global
	includekeyword	include
	simulatoroptions	simulatorOptions
	simkeyword	simulator
	newline 	\n
	sci		1e-?\d+
	float		\-?\d+\.\d+[ul]?
	integer 	\-?\d+
	identifier 	(\w+)
	slashslash 	[\/\/]
	colon 		[\:]
	equals 		[\=]
	quote 		[\"]
	fslash 		[\/]
	bslash		\\\
	period 		[\.]
	leftp 		[\(]
	rightp		[\)]
);

my $lexer = Parse::Lex->new(@patterns);
$lexer->from(\*IN);


my $parser = new netlistparser;
$parser->YYParse(YYlex => \&lex);

sub lex{
	my $token = $lexer->next;
	while($token->name eq "comment"){
		#print "Found comment ".$token->text;
		$token = $lexer->next;
	}
	if($token->name eq "simulatoroptions"){
		while(not $lexer->eoi){
			$token = $lexer->next;
		}
	}
	return ('',undef) if $lexer->eoi;
	if($verbose){ print "Returning ".$token ->name." ".$token->text."\n"; }
	return ($token->name, $token->text);
}

