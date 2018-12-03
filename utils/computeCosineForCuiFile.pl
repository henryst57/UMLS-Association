# Computes the cosine distance between a file of cuis and every cui
# in the vocabulary. It outputs this as a file with a row for each
# cui and its cosine distance between it and every other cui.
# Output is the form:
#    rowCui<>cui,cosine<>cui,cosine<>...<>cui,cosine\n
# Input is a cui file containing line seperated cuis:
#    cui\n
# and a vector file containing the vectors for every
# cui in the vocabulary of the form:
#    rowCui<>cui,value<>cui,value<>...<>cui,value<>
# Input can be a matrix file instead, which contains values of the
# form:
#    $cui1\t$cui2\t$value\n
# Input can be word2vec format instead, which contains:
#    first line of file is number of vectors space vector length
#    subsequent lines are of the form:
#    term value value value ... value\n
# Both input and output are sparse format, so only cuis for which
# a non-zero value has a value are stored.
#
# The vector file format must be specified as:
#    'matrix', 'word2vec', 'vector' 
#
# This is used to compare cosine distances as an indirect evaluation
# measure using the indirectEval graphs
use strict;
use warnings;

#Compute Direct Cosines
my $cuiFile = '../../../startCuis/randomCuis_T047';
my $vectorFile = '../../../rawData/1975_1999_window8_ordered_threshold1';
my $vectorFileFormat = 'matrix';
my $outputFile = '../../../preprocessedData/vectors_explicitCosine_1975_1999_window8_ordered_threshold1_randomCuis_T047';
&computeCosineForAll($vectorFile, $cuiFile, $outputFile, $vectorFileFormat);


#######################################################
#                     Begin Code
#######################################################

#computes the cosine distances for a set of cui pairs
sub computeCosineForAll {
    my $vectorFile = shift;
    my $cuiFile = shift;
    my $outputFile = shift;
    my $vectorFileFormat = shift;

    #read input
    my $cuisArrayRef = &readCuiFile($cuiFile);
    my $vectorsHashRef;
    if ($vectorFileFormat eq 'matrix') {
	$vectorsHashRef = &readMatrixFile($vectorFile);
    }
    elsif ($vectorFileFormat eq 'word2vec') {
	$vectorsHashRef = &readWord2VecFile($vectorFile);
    } 
    elsif ($vectorFileFormat eq 'vector') {
	$vectorsHashRef = &readVectorFile($vectorFile);
    }
    else {
	die ("ERROR: vectorFileFormat must be specified as vector, matrix, or word2vec: $vectorFileFormat\n");
    }
    

    #compute cosine for each cui against all cuis in the vocabulary
    open OUT, ">$outputFile" or die ("ERROR: error opening outputFile: $outputFile\n");
    foreach my $cui1 (@{$cuisArrayRef}) {
        
	#get each vector
	my $vector1Ref = ${$vectorsHashRef}{$cui1};
	(defined $vector1Ref) or print("WARNING: no vector for cui1: $cui1**\n");

	#output results as they are found
	print OUT "$cui1";
	#only need to loop thru the matrix if there is a vector for cui1
	if (defined $vector1Ref) {
	    #compute this vector against every vector in the vocabulary
	    foreach my $cui2 (keys %{$vectorsHashRef}) {
	        #grab the vector 2
		my $vector2Ref = ${$vectorsHashRef}{$cui2};
		(defined $vector2Ref) or die("ERROR: no vector for cui2: $cui2**\n");

		######################
		#compute cosine (not in a function because function calls are expensive)
		#####################
		#compute the numerator, which is the sum of x_i * y_i values
		my $numerator = 0;
		foreach my $key (keys %{$vector1Ref}) {
		    if (exists ${$vector2Ref}{$key}) {
			$numerator += (${$vector1Ref}{$key} * ${$vector2Ref}{$key});
		    }
		}
		
		#find the denominator, which is the product of x and y lengths
		#find sum of x squared
		my $vector1Sum = 0;
		foreach my $key (keys %{$vector1Ref}) {
		    $vector1Sum += (${$vector1Ref}{$key} * ${$vector1Ref}{$key});
		}

		#find sum of y squared
		my $vector2Sum = 0;
		foreach my $key (keys %{$vector2Ref}) {
		    $vector2Sum += (${$vector2Ref}{$key} * ${$vector2Ref}{$key});
		}

		#find the denominator
		my $denominator = sqrt($vector1Sum) * sqrt($vector2Sum);
		
		#calcualte the score (with error checking)
		my $cosine = -1;  
		if ($denominator != 0) { 
		    $cosine = $numerator/$denominator;
		}
		##########################
		# END compute cosine
		##########################

		#output the results
		if ($cosine != -1 && $cosine != 0) {		
		    print OUT "<>$cui2,$cosine";
		}
	    }
	}
	print OUT "\n";

    }
    close OUT;
}


#reads the matrix file of the form: cui1\tcui2\tvalue...\n
# returns a ref to a hash of hashes, of the form: %vectors{$cui}=\%vector
#     where %vector is of the form: $vector{$cui} = $value
sub readMatrixFile {
    my $vectorFile = shift;
    
    #read each vector
    open IN, $vectorFile or die ("ERROR: unable to open vectorFile: $vectorFile\n");
    my %vectors = ();
    while (my $line = <IN>) {
	#seperate the line into value pairs
	chomp $line;
	my @vals = split(/\t/,$line);
        #cui1 = vals[0]
	#cui2 = vals[1]
	#val  = vals[2]

	#create the vector if needed
	if (!defined $vectors{$vals[0]}) {
	    my %emptyHash = ();
	    $vectors{$vals[0]} = \%emptyHash;
	}
	#add this value
	${$vectors{$vals[0]}}{$vals[1]} = $vals[2];
    }
    
    #return the vectors hash
    return \%vectors;
}

#reads the vector file of the form: VECTOR_CUI<>CUI,VALUE<>CUI,VALUE<>...\n
# returns a ref to a hash of hashes, of the form: %vectors{$cui}=\%vector
#     where %vector is of the form: $vector{$cui} = $value
sub readVectorFile {
    my $vectorFile = shift;
    
    #read each vector
    open IN, $vectorFile or die ("ERROR: unable to open vectorFile: $vectorFile\n");
    my %vectors = ();
    while (my $line = <IN>) {
	#seperate the line into value pairs
	chomp $line;
	my @vals = split('<>',$line);
        
	#the first value of the line the cui that the vector is for
	# create that vector and add to the vectorsHash
	my $vectorCui = shift @vals;
	my %vector = ();
	$vectors{$vectorCui} = \%vector;
        
        #populate the vector with the cui,value pairs
	foreach my $valPair (@vals) {
	    (my $cui, my $val) = split(',',$valPair);
	    $vector{$cui} = $val;
	}
    }
    
    #return the vectors hash
    return \%vectors;    
}

#reads the vector file of the form: 
#    first line of file is number of vectors space vector length
#    subsequent lines are of the form:
#    term value value value ... value\n
# returns a ref to a hash of hashes, of the form: %vectors{$cui}=\%vector
#     where %vector is of the form: $vector{$cui} = $value
sub readWord2VecFile {
    my $vectorFile = shift;
    
    #read each vector
    open IN, $vectorFile or die ("ERROR: unable to open vectorFile: $vectorFile\n");
    
    #skip the header line
    my $headLine = <IN>;

    #read each vector line
    my %vectors = ();
    while (my $line = <IN>) {
	#seperate the line into value pairs
	chomp $line;
	my @vals = split(' ',$line);
        
	#the first value of the line the cui that the vector is for
	# create that vector and add to the vectorsHash
	my $vectorCui = shift @vals;
	my %vector = ();
	$vectors{$vectorCui} = \%vector;

        #populate the vector values
	my $index = 0;
	foreach my $val (@vals) {
	    $vector{$index} = $val;
	}
    }
    
    #return the vectors hash
    return \%vectors;    
}



#reads the cui pair file of the form: cui\n
# and returns a ref to an array of each chomped line
sub readCuiFile {
    my $cuiFile = shift;

    #read each line
    my @cuis = ();
    open IN, $cuiFile or die ("ERROR: unable to open cuiFile: $cuiFile");
    while (my $line = <IN>) {
	chomp $line;
        push @cuis, $line;
    }

    return \@cuis
}

