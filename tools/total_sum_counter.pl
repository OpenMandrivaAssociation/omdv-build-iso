#!/usr/bin/perl
#
#  $Id:$
#
# This program is a part of installator DrakX. Program scans directory where 
# live system is prepared and calculates total size of the directory, which is placed
# into minimal requirements file 
#
# Usage example:
#		 ./total_sum_counter.pl -r 512 -h 8 -w /work/ext3 -o /work/etc/min_sys/requirements
#
# Return codes:
#
# 0 -- total size has been calculated 
# 1 -- missed command line' arguments
# 2 -- source directory with live filesystem doesn't exists
#
use Getopt::Std;
use File::Basename;

############### Check command line args ##################

getopts("r:h:w:o:");
if (!$opt_o || !$opt_w || !$opt_r || !$opt_h) {
	print "\n Usage:  total_sum_counter.pl -r <min RAM (MB)> -h <Min HDD (GB)> -w <work directory with live system> -o <configuration file>\n\n";
	exit 1;
}

if (! -d $opt_w)  {
	print  "Directory $opt_w is not found.\n";
	exit 2;
}

################################

  $cmd = "cd $opt_w; du -a -x -b -P . | tail -1";
  open (SCANSRC,"-|", $cmd) || die "Cannot run du utility to prepare data";
  open (SCANRES,"> $opt_o") || die "Cannot create output file $opt_o";


  print SCANRES "ram = $opt_r\n";
  print SCANRES "hdd = $opt_h\n"; 

  while (<SCANSRC>) {
    $tmp = $_;
    ($filesize, $filename ) = split;
    print SCANRES "imagesize = $filesize\n";
  }
  close SCANSRC;
  close SCANRES;

exit 0;
