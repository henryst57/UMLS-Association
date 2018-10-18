#Creates an association matrix of every word vs every word
use strict;
use warnings;

use lib '/home/henryst/UMLS-Association/lib';
use UMLS::Association;

#user input
my $cooccurrenceFile = '/home/henryst/data/1975_2015_window8_threshold1';
my $outputFile = '/home/henryst/assocMatrix_x2_1975_2015_window8_ordered_threshold1_clean';
my $measure = 'x2';
my $noOrder = 0;
my $skipZero = 1;
my $skipNegOne = 1;


###################################
#   Begin Code
###################################

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


#####################################
#   Initalize UMLS::Association
#####################################
my %params = ();
$params{'matrix'}=$cooccurrenceFile;
my $association = UMLS::Association->new(\%params);


#####################################
#   Compute the association matrix 
#####################################
# Compute the associaiton between every unique cui and every other unique cui
# output the results as they are computed
open OUT, ">$outputFile" or die ("ERROR: cannot open outputFile: $outputFile\n");
my $cuiCount = 0;
my $totalCuiCount = scalar keys %uniqueCuis;

#iterate over all possible cui pairs
foreach my $cui1 (sort keys %uniqueCuis) {
    print OUT "$cui1";
    foreach my $cui2 (sort keys %uniqueCuis) {
	#calculate and output pair association
	my $pairN11 = ${$n11{$cui1}}{$cui2};
	my $pairN1P = $n1p{$cui1};
	my $pairNP1 = $np1{$cui2};
	
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
    if ($cuiCount%100000 == 0) {
        print STDERR "computed $cuiCount / $totalCuiCount rows\n";
    }

}
close OUT;

print STDERR "Done!\n";


