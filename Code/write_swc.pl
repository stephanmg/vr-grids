#!/usr/bin/env perl
# writes (x,y,z);d CSV data to SWC file

use Getopt::Long qw(GetOptions);
 
my $filename;
my $in;
GetOptions('filename=s' => \$filename) or die "Usage: $0 --filename NAME\n";
if ($filename) {
    open $in, "<:encoding(utf8)", "$filename" or die $!;
} else {
    die "Usage: $0 --filename NAME\n";
}

my $index = 1;
while (my $line = <$in>) {
  chomp($line);
  $line =~ s/SWC: //;
  $line =~ s/\(//g;
  $line =~ s/\)/ /g;
  $line =~ s/,//g;
  if ($index == 1) {
     print "$index 2 $line -1\n";
} else {
    my $index2 = $index-1;
     print "$index 2 $line $index2\n";
    }
  $index++;
}
