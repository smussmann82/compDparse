#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use Getopt::Std;

my %opts;
getopts('f:m:o:p:', \%opts);

my( $file, $map, $pval, $out ) = &parsecom(\%opts);

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
my %chihash;
my %zhash;
my @loci;
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
my $count = scalar(@lines);

foreach my $line( @lines ){
	my @temp = split(/\t/, $line);
	my $chiresult = &lessthan($temp[9], $correction, $intp, "chisqr", \%hash );
	my $zresult = &lessthan( $temp[11], $correction, $intp, "Z", \%hash );
	push( @loci, $temp[6] );
	if( $chiresult == 1 or $zresult == 1 ){
		my $result = &introgress( $temp[4], $temp[5], $temp[1], $temp[2], $temp[3], \%pophash );
		$chihash{$result}+=0;
		$zhash{$result}+=0;
		if( $chiresult == 1 ){
			$chihash{$result}++;
		}
		if( $zresult == 1 ){
			$zhash{$result}++;
		}
	}
}

my $avg = &mean(\@loci);
my $sd = &stdev(\@loci, $avg);

&printout("$out.chisq", \%chihash, $count, $avg, $sd);
&printout("$out.zscore", \%zhash, $count, $avg, $sd );

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
	my $out = $opts{o} || "$file.sig";

	return( $file, $map, $pval, $out );

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
# subroutine to print output file

sub printout{

	my( $outfile, $hash, $count, $avg, $sd ) = @_;

	open( OUT, '>', $outfile ) or die "Can't open $outfile: $!\n\n";

	foreach my $key( sort keys %$hash ){
		print OUT $file, "\t", $key, "\t", $$hash{$key}, "\t", $count, "\t", $avg, "\t", $sd, "\n";
	}

	close OUT;
}
#####################################################################################################
# subroutine to calculate mean of an array

sub mean{

	my( $data ) = @_;

	if( not @$data ){
		die( "Empty array\n" );
	}

	my $total = 0;

	foreach my $item( @$data ){
		$total+=$item;
	}

	my $length = scalar( @$data );
	my $average = $total / $length;
	return $average;

}
#####################################################################################################
# subroutine to calculate standard deviation

sub stdev{

	my( $data, $avg ) = @_;

	if( not @$data ){
		die( "Empty array\n" );
	}

	my $total = 0;
	foreach my $item( @$data ){
		my $temp = $item - $avg;
		$temp = $temp**2;
		$total+=$temp;
	}
	
	my $length = scalar( @$data );
	my $variance = $total / $length;

	my $sd = sqrt($variance);

	return $sd;

}

#####################################################################################################
