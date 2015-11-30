#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use Mojo::Pg;
use Text::CSV;

my $pg = Mojo::Pg->new('postgresql://fucklips@/butter');
my $db = $pg->db;

my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute
                 or die "Cannot use CSV: ".Text::CSV->error_diag (); 

open my $xor_key, '<', 'xor_key.txt' or die $!;
my @nums;
while (<$xor_key>) {
  chomp;
  push @nums, $_;
}
close $xor_key;

open my $hex_key, '<', 'chars.txt' or die $!;
my %hex;
while (<$hex_key>) {
  chomp;
  my ($hexrep,$letter) = split ',';
  $hex{$hexrep} = $letter;
}
close $hex_key;

for ( 1 .. 13 ) {
  next if $_ == 8;

  my $table = 'table'.$_;
  my $r = $db->query("select * from $table");

  my @header;
  my $out;
  while ( my $next = $r->hash ) {

    my $num_key;
    if ( $table =~ /\Atable(?:1|2|5|12|13)\Z/ ) {
      $num_key = $next->{primaryid};
      @header = qw(primaryid expression recordid);
    }
    else {
      $num_key = $next->{secondaryid};
      if ( $table eq 'table10' ) {
        @header = qw(primaryid secondaryid expression);
      }
      else {
        @header = qw(primaryid secondaryid expression recordid);
      }
    }

    if ( !$next->{expression} ) {
      push @{$out}, $next;
      next;
    }

    if ( $num_key & 128 ) {
      $num_key = $num_key + 384;
    }

    my @vals;
    my $count = 0;
    while ( $count < length $next->{expression} ) {
      push @vals, ($num_key ^ $nums[$count]);
      $count++;
    }

    my $key = pack("C*", @vals);
    my $unencrypted_text = $key ^ $next->{expression};
    for (split '', $unencrypted_text) {
      if (ord($_) > 127) {
        if ( defined $hex{ord($_)} ) {
          $unencrypted_text =~ s/$_/$hex{ord($_)}/g;
        }
        else {
          say ord($_) . ",$_ from $unencrypted_text not represented in chars.txt";
        }
      }
    }
    $next->{expression} = $unencrypted_text;
    push @{$out}, $next;
  }
  $csv->eol ("\r\n");
  open my $out_fh, ">:encoding(utf8)", "$table.csv" or die "new.csv: $!";
  $csv->print( $out_fh, [ @$_{@header} ] ) for @{$out};
  close $out_fh or die "$table.csv: $!";
}
