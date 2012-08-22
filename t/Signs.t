#!/usr/bin/perl

use Modern::Perl;

use Test::More tests => 1;

BEGIN {
  use_ok('Koha::Signs');
}

# More tests are in t/db_dependent/Signs.t
