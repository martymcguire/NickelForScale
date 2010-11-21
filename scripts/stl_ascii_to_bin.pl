#!/usr/bin/env perl
require CAD::Format::STL;

if($#ARGV != 1){
  print "Usage: stl_ascii_to_bin.pl <INFILE> <OUTFILE>";
  exit;
}

my $stl = CAD::Format::STL->new->load($ARGV[0]);
$stl->save(binary => $ARGV[1]);
