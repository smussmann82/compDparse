#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use Getopt::Std;

my %opts;
getopts('f:m:p:', \%opts);

my( $file, $map, $pval ) = &parsecom(\%opts);

my $correction = 10000;

my $intp = $pval * $correction;

if( $intp < 1 ){
	die "The p-value you entered is < 0.0001.  compD only prints p-values to 4 decimal places.\nPlease enter a larger value.\n\n";
}elsif( $intp >= $correction ){
	die "The p-value you entered is > or = 1. Please enter a smaller value.\n\n";
}

my @lines;
my @maplines;
my %hash;
my %pophash;
$hash{"chisqr"}=0;
$hash{"Z"}=0;

# put files into arrays
&filetoarray( $file, \@lines );
&filetoarray( $map, \@maplines );

foreach my $line( @maplines ){
	my @temp = split(/\s+/, $line);
	$pophash{$temp[0]} = $temp[1];
}

# remove header
my $header = shift( @lines);

foreach my $line( @lines ){
	my @temp = split(/\t/, $line);
	my $chiresult = &lessthan($temp[9], $correction, $intp, "chisqr", \%hash );
	my $zresult = &lessthan( $temp[11], $correction, $intp, "Z", \%hash );
	if( $chiresult == 1 or $zresult == 1 ){
		my $result = &introgress( $temp[4], $temp[5], $temp[1], $temp[2], $temp[3], \%pophash );
	}
}

#print Dumper(\%hash);
print Dumper(\%pophash);

exit;

#####################################################################################################
# subroutine to parse the command line options

sub parsecom{ 

	my( $params ) =  @_;

	my %opts = %$params;

	# set default values for command line arguments
	my $file = $opts{f} or die "\nMust specify an input file\n\n";
	my $pval = $opts{p} || "0.01";
	my $map = $opts{m} or die "\nMust specify popmap file\n\n";

	return( $file, $map, $pval );

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

#####################################################################################################
# subroutine to get taxa involved in introgression

sub introgress{

	my( $abba, $baba, $p3, $p2, $p1, $hash ) = @_;

	my $string;

	if( $abba > $baba ){
		$string = join('-', $$hash{$p3}, $$hash{$p2});
	}else{
		$string = join('-', $$hash{$p3}, $$hash{$p1} );
	}

	return $string;

}

#####################################################################################################
# subroutine to put file into an array

sub filetoarray{

	my( $infile, $array ) = @_;

	#open the input file
	open( FILE, $infile ) or die "Can't open $infile: $!\n\n";

	# loop through input file, pushing lines onto array
	while( my $line = <FILE> ){
		chomp( $line );
		next if($line =~ /^\s*$/);
		push( @$array, $line );
	}

	close FILE;
}
#####################################################################################################
