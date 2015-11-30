#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';

open my $fh, '<', '/home/damaya/fucking_crazy/chars.txt' or die $!;
my %hex;
while (<$fh>) {
  chomp;
  my ($hexrep,$letter) = split ',';
  $hex{$hexrep} = $letter;
}

for my $file (glob('*.txt')) {
  say "processing $file\n";

  open my $in, '<', $file or die $!;
  open my $out, '>', "$file.fixed" or die $!;
  while ( my $line=<$in> ) {
    chomp $line;
    for (split '', $line) {
      if (ord($_) > 127) {
        if ( defined $hex{ord($_)} ) {
          $line =~ s/$_/$hex{ord($_)}/g;
          say "fixed $_";
        }
        else {
          say ord($_) . ",$_ $line from $file not represented in chars.txt";
        }
      }
    }
    print $out "$line\n";
  }
}
