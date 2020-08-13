#!/usr/bin/env perl
#
#open my $in, "<:encoding(utf8)", "new_geom.swc" or die $!;
#open my $in, "<:encoding(utf8)", "blubb.swc" or die $!;
#open my $in, "<:encoding(utf8)", "foo2.swc" or die $!;
#open my $in, "<:encoding(utf8)", "new_james.swc" or die $!;
#open my $in, "<:encoding(utf8)", "new_james.swc" or die $!;


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
