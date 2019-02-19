#Creates an association matrix of every word vs every word
use strict;
use warnings;
use lib '/home/henryst/UMLS-Association/lib';
use UMLS::Association;

#user input
my $cooccurrenceFile = '/home/henryst/data/1975_2015_window1';
my $outputFile = 'assocMatrix_x2_1975_2015_window1_noOrder';
my $measure = 'x2';
my $noOrder = 1;
my $skipZero = 1;
my $skipNegOne = 1;
&computeAssociationMatrix($cooccurrenceFile, $outputFile, $measure, $noOrder, $skipZero, $skipNegOne);

=comment
my $cooccurrenceFile = '/home/henryst/data/1975_2015_window1';
my $outputFile = 'assocMatrix_ll_1975_2015_window1_noOrder';
my $measure = 'll';
my $noOrder = 1;
my $skipZero = 1;
my $skipNegOne = 1;
&computeAssociationMatrix($cooccurrenceFile, $outputFile, $measure, $noOrder, $skipZero, $skipNegOne);

my $cooccurrenceFile = '/home/henryst/data/1975_2015_window1';
my $outputFile = 'assocMatrix_dice_1975_2015_window1_noOrder';
my $measure = 'dice';
my $noOrder = 1;
my $skipZero = 1;
my $skipNegOne = 1;
&computeAssociationMatrix($cooccurrenceFile, $outputFile, $measure, $noOrder, $skipZero, $skipNegOne);

my $cooccurrenceFile = '/home/henryst/data/1975_2015_window1';
my $outputFile = 'assocMatrix_odds_1975_2015_window1_noOrder';
my $measure = 'odds';
my $noOrder = 1;
my $skipZero = 1;
my $skipNegOne = 1;
&computeAssociationMatrix($cooccurrenceFile, $outputFile, $measure, $noOrder, $skipZero, $skipNegOne);


#########################################################
#   Ordered
#######################################################
my $cooccurrenceFile = '/home/henryst/data/1975_2015_window1';
my $outputFile = 'assocMatrix_x2_1975_2015_window1_ordered';
my $measure = 'x2';
my $noOrder = 0;
my $skipZero = 1;
my $skipNegOne = 1;
&computeAssociationMatrix($cooccurrenceFile, $outputFile, $measure, $noOrder, $skipZero, $skipNegOne);

my $cooccurrenceFile = '/home/henryst/data/1975_2015_window1';
my $outputFile = 'assocMatrix_ll_1975_2015_window1_ordered';
my $measure = 'll';
my $noOrder = 0;
my $skipZero = 1;
my $skipNegOne = 1;
&computeAssociationMatrix($cooccurrenceFile, $outputFile, $measure, $noOrder, $skipZero, $skipNegOne);

my $cooccurrenceFile = '/home/henryst/data/1975_2015_window1';
my $outputFile = 'assocMatrix_dice_1975_2015_window1_ordered';
my $measure = 'dice';
my $noOrder = 0;
my $skipZero = 1;
my $skipNegOne = 1;
&computeAssociationMatrix($cooccurrenceFile, $outputFile, $measure, $noOrder, $skipZero, $skipNegOne);

my $cooccurrenceFile = '/home/henryst/data/1975_2015_window1';
my $outputFile = 'TEST_assocMatrix_odds_1975_2015_window1_ordered';
my $measure = 'odds';
my $noOrder = 0;
my $skipZero = 1;
my $skipNegOne = 1;
&computeAssociationMatrix($cooccurrenceFile, $outputFile, $measure, $noOrder, $skipZero, $skipNegOne);
=cut






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
    &computeAllAssociations($n11Ref, $n1pRef, $np1Ref, $npp, $uniqueCuisRef, $cooccurrenceFile, $outputFile, $measure, $skipZero, $skipNegOne); 
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
	    #avoid double counting
	    if ($cui1 ne $cui2) {
		#increment other way
		${$n11{$cui2}}{$cui1} += $value; 
	    }                                                         
	}                                                                         

	#update unique cuis                                                                           
	$uniqueCuis{$cui1}=1;
	$uniqueCuis{$cui2}=1;
	
	#update n1p and np1                                                                           
	$n1p{$cui1} += $value;                                                                        
	$np1{$cui2} += $value;                                                                        
	if ($noOrder > 0) {     
	    #avoid double counting
	    if ($cui1 ne $cui2) {
		#increment other way
		$n1p{$cui2} += $value;                                                                    
		$np1{$cui1} += $value;
	    }                                                                    
	}                                                                                             
	
	#update $npp                                                                                  
	$npp += $value;                                                                               
	if ($noOrder) { 
	    #avoid double counting
	    if ($cui1 ne $cui2) {
		#increment other way
		$npp += $value;         
	    }                                                                  
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
    my $skipZero = shift;
    my $skipNegOne = shift;

    # Initalize UMLS::Association
    my %params = ();
    $params{'matrix'}=$cooccurrenceFile;
    my $association = UMLS::Association->new(\%params);

    #### Compute the association matrix 
    # Compute the associaiton between every unique cui and every other unique cui
    # output the results as they are computed
    open OUT, ">$outputFile" or die ("ERROR: cannot open outputFile: $outputFile\n");
    print "outputFile = $outputFile\n";
    my $cuiCount = 0;
    my $totalCuiCount = scalar keys %{$uniqueCuisRef};
    
    #get the output loop keys to iterate over (whole vocab, or just n11 keys)
    my @cuiKeys = sort keys %{$uniqueCuisRef};
   
    #generate association scores for all pairs needed)
    foreach my $cui1 (@cuiKeys) {
	print OUT "$cui1";
   
	#iterate over cui1, cui2 pairs
	foreach my $cui2 (@cuiKeys) {
	    #calculate and output pair association
	    my $pairN11 = ${${$n11Ref}{$cui1}}{$cui2};
	    my $pairN1P = ${$n1pRef}{$cui1};
	    my $pairNP1 = ${$np1Ref}{$cui2};
	    
	    #Only calculate if both CUIs are have n1p's and np1's
	    my $value = -1;
	    if (defined $pairN1P && defined $pairNP1) {
		if (!defined $pairN11) {
		    $pairN11 = 0;
		}
		#calculate the association
		$value = $association->_calculateAssociation_fromObservedCounts(
		    $pairN11, $pairN1P, $pairNP1, $npp, $measure);		
	    }
	
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
	#if ($cuiCount%10000 == 0) {
	    print STDERR "   computed $cuiCount / $totalCuiCount rows\n";
	#}

    }
    close OUT;

    print STDERR "Done!\n";
}
