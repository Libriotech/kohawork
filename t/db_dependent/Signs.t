use Modern::Perl;
use Test::More qw(no_plan); # TODO Set the number
use Test::Exception;
use C4::Context;

BEGIN {use_ok('Koha::Signs') }
use Koha::Signs;

my $dbh = C4::Context->dbh;

# TODO Check that CPL is a valid branchcode, or choose a random one from
# the branches table
my $library1 = 'CPL';
my $name1    = 'some unlikely name';

ok( AddSign( $library1, $name1 ), "AddSign" );
ok( AddSign( '', $name1 ), "AddSign, no branchcode" );
