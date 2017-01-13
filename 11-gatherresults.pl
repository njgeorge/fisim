opendir DIR, "./8-results" or die "Cannot open folder ./8-results\n";

while($filename = readdir(DIR)){
	if($filename =~ /stats\-(\d+).txt/){
		$id = $1;
		$net = sprintf("%04d",$id);
		open IN, "8-results/$filename" or die "Cannot find 8-results/$filename\n";

		$totalcount = 0;
		$unacecount = 0;
		%distributions = ();
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

		$AVF = ((($totalcount - $unacecount)/$totalcount) * 100);
		#print "$filename: AVF = (($totalcount - $unacecount)/$totalcount) * 100 = $AVF\n";
		$AVFs{$net} = $AVF;
	
		#print "Distribution of affected outputs\n";
	
		#for $net (sort keys %distribution){
        		#print "$net: $distribution{$net} (".($distribution{$net}/$totalcount*100)."\%)\n";
		#}
	
		close IN;
	}
}

for $net (sort keys %AVFs){
	print "$net $AVFs{$net}\n";
}
