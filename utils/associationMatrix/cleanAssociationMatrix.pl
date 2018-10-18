#Cleans the association matrix by removing 0's, and/or -1's
# Takes as input an association matrix file of the form:
#         VECTOR_CUI<>CUI,VALUE<>CUI,VALUE<>...\n
# and outputs an association matrix file of the same form, but
# with zero and/or negative 1 elements removed.
#
# Reads $asssocMatrixFile and outputs to $outFile with specified 
#   elements removed
# Removes zero elements if $removeZero > 0
# Removes negative one elements if $removeNegativeOne > 0
use strict;
use warnings;


#user input
my $assocMatrixFile = '/home/henryst/assocMatrix_x2_1975_2015_window8_ordered_threshold1_noZeros';
my $outFile = '/home/henryst/assocMatrix_x2_1975_2015_window8_ordered_threshold1_clean';
my $removeZero = 1;
my $removeNegativeOne = 1;



###############################################
#                Begin Code
###############################################

#open input and output
open IN, $assocMatrixFile or die ("ERROR: cannot open assocMatrixFile: $assocMatrixFile\n");
open OUT, ">$outFile" or die ("ERROR: cannot open outFile: $outFile\n");

#read the input and copy to output line by line (vector by vector)
# at each line, copy the row vector and any non-zero and/or non-negative_1 values
#The input and output files are both of the form: VECTOR_CUI<>CUI,VALUE<>CUI,VALUE<>...\n
#read in the first line of the matrix
my $line = <IN>;
$line or die ("ERROR: input matrix is empty: $assocMatrixFile\n");

#iterate over all lines (set up as a do while so that there is no empty line 
#   at the end of the file)
do {
    #seperate the line into value pairs
    chomp $line;
    my @vals = split('<>',$line);

    #the first value of the line the cui that the vector is for
    # create that vector and add to the vectorsHash
    my $vectorCui = shift @vals;
 
    #output the vector CUI to a new line
    print OUT $vectorCui;

    #Check each element to see if you should keep it
    foreach my $valPair (@vals) {
	# split the cui, val pair
	(my $cui, my $val) = split(',',$valPair);

	#if > 0 then always keep
	if ($val > 0) {
	    print OUT '<>'.$valPair;
	}
	else {
	    #check if the value should be skipped (not copied over)
	    if ($val == 0 && $removeZero) {
		next; #skip, its a zero
	    }
	    elsif ($val == -1 && $removeNegativeOne) {
		next; #skip, its a -1
	    }

	    #the value should not be skipped (even though it may
	    # be negative, and should be copied over
	    print OUT '<>'.$valPair;
	}
    }

    #end the line
    print OUT "\n";

} while ($line = <IN>);


#each line of matrix copied over with appropriate values removed
print "DONE!\n";
