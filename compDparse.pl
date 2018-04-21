#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use Getopt::Std;

# kill program and print help if no command line arguments were given
if( scalar( @ARGV ) == 0 ){
	&help;
	die "Exiting program because no command line options were used.\n\n";
}

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
my @abba;
my @baba;
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
	push( @abba, $temp[4] );
	push( @baba, $temp[5] );
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

my $avg = sprintf( "%.2f", &mean(\@loci) );
my $sd = sprintf( "%.2f", &stdev(\@loci, $avg) );
my $avg_abba = sprintf( "%.2f", &mean(\@abba) );
my $sd_abba = sprintf( "%.2f", &stdev(\@abba, $avg_abba) );
my $avg_baba = sprintf( "%.2f", &mean(\@baba) );
my $sd_baba = sprintf( "%.2f", &stdev(\@baba, $avg_baba) );



&printout("$out.chisq", \%chihash, $count, $avg, $sd, $avg_abba, $avg_baba, $sd_abba, $sd_baba );
&printout("$out.zscore", \%zhash, $count, $avg, $sd, $avg_abba, $avg_baba, $sd_abba, $sd_baba );

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

	my( $outfile, $hash, $count, $avg, $sd, $abba, $baba, $sdABBA, $sdBABA ) = @_;

	open( OUT, '>', $outfile ) or die "Can't open $outfile: $!\n\n";

	foreach my $key( sort keys %$hash ){
		print OUT $file, "\t", $key, "\t", $$hash{$key}, "\t", $count, "\t", $avg, "\t", $sd, "\t", $abba, "\t", $baba, "\t", $sdABBA, "\t", $sdBABA, "\n";
	}

	close OUT;

	print "file\tpair\tnum_sig\ttotal\tavg_loci\tsd_loci\tavg_abba\tavg_baba\tsd_abba\tsd_baba\n";
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
# subroutine to print help

sub help{

	print "\ncompDparse.pl is a perl script developed by Steven Michael Mussmann\n\n";
	print "To report bugs send an email to mussmann\@email.uark.edu\n";
	print "When submitting bugs please include all input files, options used for the program, and all error messages that were printed to the screen\n\n";
	print "Program Options:\n";
	print "\t\t[ -f | -h | -m | -o | -p  ]\n\n";
	print "\t-f:\tUsed to specify the input file.\n";
	print "\t\tThe program will die if no file is specified.\n\n";
	print "\t-h:\tDisplays this help message.\n";
	print "\t\tThe program will die after the help message is displayed.\n\n";
	print "\t-m:\tUse this flag to specify your population map text file.\n";
	print "\t\tThis is a tab delimited file specifying the sample name in the first column and population name in the second.\n";
	print "\t\tThe program will die if no file is specified.\n\n";
	print "\t-o:\tSpecify the output file prefix.\n";
	print "\t\tIf no name is provided, the file extensions \".sig.chisq\" and \".sig.zscore\" will be appended to the input file name.\n\n";
	print "\t-p:\tSpecify a p-value for testing significance.\n";
	print "\t\tValue must be less than 1 and greater than .0001. Default = 0.01.\n\n";

}

#####################################################################################################
