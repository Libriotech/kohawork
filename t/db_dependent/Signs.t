use Modern::Perl;
use Test::More qw(no_plan); # TODO Set the number
use Test::Exception;
use C4::Context;

BEGIN {use_ok('Koha::Signs') }
use Koha::Signs;

my $dbh = C4::Context->dbh;

my $name1   = 'some unlikely name';
my $name2   = 'some other name';
my $name3   = 'a changed name';
my $report1 = 1;

# AddSign
ok( AddSign( $name1, $report1 ), "AddSign" );

# Find the sign_id of the sign we just added, for use in further tests
my $query = "SELECT sign_id FROM signs WHERE saved_sql_id = '$report1' AND name = '$name1'";
my $sth = $dbh->prepare($query);
$sth->execute();
my ( $sign_id ) = $sth->fetchrow_array();

# GetSign
my $sign;
ok( $sign = GetSign( $sign_id ), "GetSign (sign_id = $sign_id) ok" );
like( $sign->{'saved_sql_id'}, qr/$report1/, "GetSign saved_sql_id ok" );
like( $sign->{'name'},         qr/$name1/,   "GetSign name ok" );

# GetAllSigns
my $signs;
ok( $signs = GetAllSigns, "GetAllSigns ok" );
my $num_of_signs = @{$signs};
cmp_ok( $num_of_signs, ">", 0, "GetAllSigns found at least one map" );
foreach my $sign ( @{$signs} ) {
  if ( $sign->{'sign_id'} == $sign_id ) {
    like( $sign->{'saved_sql_id'}, qr/$report1/, "GetAllSigns found a sign with our saved_sql_id" );
    like( $sign->{'name'},         qr/$name1/,   "GetAllSigns found a sign with our name" );
  }
}

# EditSign
my $editedsign;
ok( EditSign( $name3, $report1, $sign_id ), "EditSign ok" );
ok( $editedsign = GetSign( $sign_id ), "GetSign on edited sign ok" );
like( $editedsign->{'saved_sql_id'}, qr/$report1/, "saved_sql_id from GetSign on edited sign ok" );
like( $editedsign->{'name'},         qr/$name3/,   "name from GetSign on edited sign ok" );

# DeleteSign
ok( DeleteSign( $sign_id ), "DeleteSign ok" );
