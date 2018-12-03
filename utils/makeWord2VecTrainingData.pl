#Combines metamapped files that have been indexed by year into a single
# abstract seperated CUI file.
#In this new file, each line contains the ordered CUIs of each abstract.
#
#The indexed by year files are generated from Literature Based Discovery's
# indexer. This creates a folder for each year of data, in this folder is a
# cuiData.txt file, which contains on each line the pmid.[ti|ab].\d+:C\d{7},
# So, each line then contains the ordered cuis of a title (ti) or abstract
# sentence ab.1, ab.2, etc... the last line of each pmid is indicated by *pmid.
# This line contains the ordered CUIs of that PMIDs abstract (title not 
# included). This script therefore finds all *pmid lines in each 
# year/cuiData.txt file in the dataFolder, and outputs them on each line of the
# output file.
#
# The start year and end year define the years to combine, inclusive (e.g. 
# 1983-1985 will combine years 1983, 1984, and 1985 into a single file.
# That file will therefore contain the ordered CUIs of abstracts from January
# 1, 1983 to December 31, 1985.
#
use strict;
use warnings;

#user input
my $dataFolder = 'indexedAll';
my $outFile = '1975_2009_cuiAbstracts_testTake';
my $startYear = 1975;
my $endYear = 2009;
&_createData($dataFolder, $outFile, $startYear, $endYear);

############################################################
#                   Begin Code
#############################################################
sub _createData {
    #grab user input
    my $dataFolder = shift;
    my $outFile = shift;
    my $startYear = shift;
    my $endYear = shift;

    #create output file
    open OUT, ">$outFile" or die ("ERROR: unable to open outFile: $outFile\n");

    #read each year's data
    for (my $year = $startYear; $year <= $endYear; $year++) {
	#open the year's cuiData file
	my $success = open IN, "$dataFolder/$year/cuiData.txt";
	if (!$success) {
	    print "WARNING: unable to open $dataFolder/$year/cuiData.txt\n";
	    next;
	}
	
	#read each *PMID line of the file, and combine to a single file
	while (my $line = <IN>) {
	    #check if abstracts in cui line
	    if ($line =~ /\*\d+:/) {
		#remove the cui header, replace commas with spaces and output
	        $line =~ s/\*\d+://;
		$line =~ s/,/ /g;
		print OUT $line;
	    }
	}
	#done reading this file
    }
    #done combining files

    print "Done!\n";
}
