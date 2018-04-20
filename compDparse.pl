#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use Getopt::Std;

my %opts;
getopts('f:', \%opts);

my( $file ) = &parsecom(\%opts);
my @lines;
my %hash;
$hash{"chisqr"}=0;
$hash{"Z"}=0;

print( $file, "\n");

open( F, $file ) or die "Can't open $file: $!\n\n";

while( my $line = <F> ){
	chomp( $line );
	push( @lines, $line );
}

close F;

foreach my $line( @lines ){
	#print $line, "\n";
	if( $line !~ /pval$/ ){
		my @temp = split(/\t/, $line);
		#print $temp[9], "\t"; #chisqr p-val
		#print $temp[11], "\n"; #Z p-val
		if( $temp[9] < 0.01){
			#print "yes\n";
			$hash{"chisqr"}+=1
		}
		if($temp[11] < 0.01){
			#print "yes\n";
			$hash{"Z"}+=1;
		}
	}
}

print Dumper(\%hash);

exit;

#####################################################################################################
# subroutine to parse the command line options

sub parsecom{ 

	my( $params ) =  @_;

	my %opts = %$params;

	# set default values for command line arguments
	my $file = $opts{f} or die "\nMust specify an input file\n\n";

	return( $file );

}

#####################################################################################################
