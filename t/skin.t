#!/usr/bin/perl

use Test::More;
use File::Slurp;
use App::Spiritbutter::Skin;

plan tests => 1;

my $content = eval(read_file('t/data/404.parsed.pl'));

my $skin = App::Spiritbutter::Skin->new('t/data/skin.tt');

print $skin->skin($content);


