#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use Getopt::Std;

my %opts;
getopts('f:p:', \%opts);

my( $file, $pval ) = &parsecom(\%opts);

my $correction = 10000;

my $intp = $pval * $correction;

if( $intp < 1 ){
	die "The p-value you entered is < 0.0001.  compD only prints p-values to 4 decimal places.\nPlease enter a larger value.\n\n";
}elsif( $intp >= $correction ){
	die "The p-value you entered is > or = 1. Please enter a smaller value.\n\n";
}

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

# remove header
my $header = shift( @lines);

foreach my $line( @lines ){
	my @temp = split(/\t/, $line);
	#print $temp[9], "\t"; #chisqr p-val
	#print $temp[11], "\n"; #Z p-val
	my $chiresult = &lessthan($temp[9], $correction, $intp, "chisqr", \%hash );
	my $zresult = &lessthan( $temp[11], $correction, $intp, "Z", \%hash );
	#if($temp[11]*$correction < $intp){
	#	#print "yes\n";
	#	$hash{"Z"}+=1;
	#}
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
	my $pval = $opts{p} || "0.01";

	return( $file, $pval );

}

#####################################################################################################
# subroutine to test if value less than another

sub lessthan{

	my( $val, $correction, $p, $hashkey, $hash ) = @_;

	if( $val*$correction < $p ){
		$$hash{$hashkey}++;
		return 1;
	}else{
		return 0;
	}
}

