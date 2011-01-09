#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use App::Spiritbutter::Parser;
use Test::More;
use Cwd qw(abs_path);
use File::Slurp;

plan tests => 6;

my $storing = 0;
$storing = 1 if $ENV{'STORING'};

my $path = abs_path(__FILE__);
# leaning toothpick syndrome because doing it with "!"
# confuses vim's syntax highlighter!
$path =~ s/[^\/]*$/data\//;

die "No data directory found" unless -d $path;

sub compare {
  my ($left, $right_filename, $name) = @_;

  if ($storing) {
    write_file($right_filename, $left);
    ok("$right_filename stored");
  } else {
    my $right = read_file($right_filename);

    is($left, $right, $name);
  }
}

sub run_test {
  my ($sbxml, $expect) = @_;

  my $asp = App::Spiritbutter::Parser->new($sbxml);
  
  compare(Dumper($asp), "$expect.parsed.pl", $sbxml);
  compare(Dumper($asp->toplinks()), "$expect.toplinks.pl", "$sbxml toplinks");
}

run_test("${path}404.sb.xml", "${path}404");
run_test("${path}410.sb.xml", "${path}410");
run_test($path, "${path}both");

