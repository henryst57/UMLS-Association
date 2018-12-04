#Creates an association matrix of every word vs every word
use strict;
use warnings;
use lib '/home/henryst/UMLS-Association/lib';
use UMLS::Association;

#user input
my $cooccurrenceFile = 'data/1975_2015_window1';
my $outputFile = '/home/henryst/assocMatrix_lf_1975_2015_window1_noOrder';
my $measure = 'leftFisher';
my $noOrder = 1;
my $skipZero = 1;
my $skipNegOne = 1;

&computeAssociationMatrix($cooccurrenceFile, $outputFile, $measure, $noOrder, $skipZero, $skipNegOne);



###################################
#   Begin Code
###################################
#Routine to compute the association matrix
sub computeAssociationMatrix {
    my $cooccurrenceFile = shift;
    my $outputFile = shift;
    my $measure = shift;
    my $noOrder = shift;
    my $skipZero = shift;
    my $skipNegOne = shift;

    #read in the co-occurrence matrix
    my($n11Ref, $n1pRef, $np1Ref, $npp, $uniqueCuisRef) = &readMatrix($cooccurrenceFile, $noOrder);

    #compute and output the association matrix
    &computeAllAssociations($n11Ref, $n1pRef, $np1Ref, $npp, $uniqueCuisRef, $cooccurrenceFile, $outputFile, $measure, $noOrder, $skipZero, $skipNegOne); 
}


#Reads a co-occurrence matrix from file
# Input:  $cooccurrenceFile - filename of the co-occurrence matrix
#         $noOrder - 0 if word order is ignored, 1 if it is enforced
# Output: \%n11 - ref to n11 matrix stored as ${$n11{$cui2}}{$cui1} = $value;    
#         \%n1p - ref to n1p matrix stored as $n1p{$cui} = $value;    
#         \%np1 - ref to np1 matrix stored as $np1{$cui} = $value;    
#         $npp - npp of the file (total co-occurrence count)
#         \%uniqueCuis - vocabulary of the file, stored as $uniqueCuis{$cui}=1;
sub readMatrix {
    my $cooccurrenceFile = shift;
    my $noOrder = shift;

    # Read the matrix into a sparse matrix format                                                      
    open IN, $cooccurrenceFile or die ("ERROR: cannot open cooccurrenceFile: $cooccurrenceFile\n");
    my %n11= ();
    my %np1 = ();
    my %n1p = ();
    my $npp = 0;
    my $lineCount = 0;
    my %uniqueCuis = ();
    while (my $line = <IN>) {
	chomp $line;
	my @vals = split (/\t/,$line);
	#line is cui cui cooccurrence count
	my $cui1 = $vals[0];
	my $cui2 = $vals[1];
	my $value = $vals[2];
	
	#add to the sparse n11 matrix                                                                 
	if (!defined $n11{$vals[0]}) {                                                             
	    my %emptyHash = ();                                                                       
	    $n11{$vals[0]} = \%emptyHash;                                                             
	}                                                                                             
	${$n11{$cui1}}{$cui2} += $value;                                                              
	if ($noOrder) {                                                                               
	    ${$n11{$cui2}}{$cui1} += $value;                                                          
	}                                                                         

	#update unique cuis                                                                           
	$uniqueCuis{$cui1}=1;
	$uniqueCuis{$cui2}=1;
	
	#update n1p and np1                                                                           
	$n1p{$cui1} += $value;                                                                        
	$np1{$cui2} += $value;                                                                        
	if ($noOrder > 0) {                                                                           
	    $n1p{$cui2} += $value;                                                                    
	    $np1{$cui1} += $value;                                                                    
	}                                                                                             
	
	#update $npp                                                                                  
	$npp += $value;                                                                               
	if ($noOrder) {                                                                               
	    $npp += $value;                                                                           
	}                                                                                             

	#output status                                                                                
	$lineCount++;
	if ($lineCount%1000000 == 0) {
	    my $numMillion = $lineCount/1000000;
	    print STDERR "Read in $numMillion million lines\n";
        }
    }
    close IN;
    print STDERR "Read in Co-occurrence Matrix\n";

    #return the read in and computed stats
    return \%n11, \%n1p, \%np1, $npp, \%uniqueCuis;
}


#Computes the association between all term pairs in the vocabulary
sub computeAllAssociations {
    my $n11Ref = shift;
    my $n1pRef = shift;
    my $np1Ref = shift;
    my $npp = shift;
    my $uniqueCuisRef = shift;
    my $cooccurrenceFile = shift;
    my $outputFile = shift;
    my $measure = shift; 
    my $noOrder = shift;
    my $skipZero = shift;
    my $skipNegOne = shift;

    #determine if fast method can be used
    my $fastMethod = 0;
    if ($skipZero && $skipNegOne) {
	#If both zero and negative one are skipped 
	# on matrix output, then only the matrix keys need
	# to be iterated over, which saves a ton of time
	$fastMethod = 1;
	print STDERR "Using Fast Method\n";
    }
    #Else, n11=0 and/or n11=-1 need to be output, meaning 
    # that the association cannot be calculated are output
    # and we need to iterate over all possible matrix pairs

    # Initalize UMLS::Association
    my %params = ();
    $params{'matrix'}=$cooccurrenceFile;
    my $association = UMLS::Association->new(\%params);

    #### Compute the association matrix 
    # Compute the associaiton between every unique cui and every other unique cui
    # output the results as they are computed
    open OUT, ">$outputFile" or die ("ERROR: cannot open outputFile: $outputFile\n");
    my $cuiCount = 0;
    my $totalCuiCount = scalar keys %{$uniqueCuisRef};
    
    #get the output loop keys to iterate over (whole vocab, or just n11 keys)
    my @cui1Keys = ();
    if ($fastMethod) {
	@cui1Keys = sort keys %{$n11Ref};
    }
    else {
	@cui1Keys = sort keys %{$uniqueCuisRef};
    }

    #generate association scores for all pairs needed)
    foreach my $cui1 (@cui1Keys) {
	print OUT "$cui1";

	#get the inner loop keys to iterate over (whole vocab, or just n11{$cui1} keys)
	my @cui2Keys = ();
	if ($fastMethod) {
	    @cui2Keys =  sort keys %{${$n11Ref}{$cui1}};
	}
	else {
	    @cui2Keys = sort keys %{$uniqueCuisRef};
	}

	#iterate over cui1, cui2 pairs
	foreach my $cui2 (sort keys %{$uniqueCuisRef}) {
	    #calculate and output pair association
	    my $pairN11 = ${${$n11Ref}{$cui1}}{$cui2};
	    my $pairN1P = ${$n1pRef}{$cui1};
	    my $pairNP1 = ${$np1Ref}{$cui2};
	    
	    #check for and correct non-existant values
	    if (!defined $pairN11) {
		$pairN11 = 0;
	    }
	    if (!defined $pairN1P) {
		$pairN1P = -1;
	    }
	    if (!defined $pairNP1) {
		$pairNP1 = -1;
	    }
	    
	    #calculate the association
	    my $value = $association->_calculateAssociation_fromObservedCounts(
		$pairN11, $pairN1P, $pairNP1, $npp, $measure);

	    #output the value (but also check if it should be skipped)
	    if ($skipZero && $value == 0) {
		next;
	    }
	    if ($skipNegOne && $value == -1) {
		next;
	    }
	    #skipping tests failed, so output the value
	    print OUT "<>$cui2,$value"
	}
	print OUT "\n";

	#update and output progress
	$cuiCount++;
	if ($cuiCount%10000 == 0) {
	    print STDERR "computed $cuiCount / $totalCuiCount rows\n";
	}

    }
    close OUT;

    print STDERR "Done!\n";
}
