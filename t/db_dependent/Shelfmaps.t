use Modern::Perl;
use Test::More qw(no_plan); # TODO Set the number
use Test::Exception;
use C4::Context;

BEGIN {use_ok('Koha::Shelfmaps') }
use Koha::Shelfmaps;

my $dbh = C4::Context->dbh;
my $library1 = 'CPL';
my $library1_floor1 = 'first';
my $library1_floor1_2 = 'First';
my $big_number = 100000;
my $neg_number = -1;

ok(AddShelfmap( $library1, $library1_floor1 ), "AddShelfmap");

# Find the shelfmapid of the map we just added
my $query = "SELECT shelfmapid FROM shelfmaps WHERE branchcode = '$library1' AND floor = '$library1_floor1'";
my $sth = $dbh->prepare($query);
$sth->execute();
my ( $shelfmapid ) = $sth->fetchrow_array();

my $shelfmap;
ok( $shelfmap = GetShelfmap( $shelfmapid ), "GetShelfmap (id = $shelfmapid)" );
like( $shelfmap->{'branchcode'}, qr/$library1/, "GetShelfmap branchcode" );
like( $shelfmap->{'floor'}, qr/$library1_floor1/, "GetShelfmap floor" );
ok( !GetShelfmap( $big_number ), "GetShelfmap big number" );
ok( !GetShelfmap( $neg_number ), "GetShelfmap negative number" );

my $shelfmaps;
ok( $shelfmaps = GetAllShelfmaps(), "GetAllShelfmaps" );
my $num_of_maps = @{$shelfmaps};
cmp_ok( $num_of_maps, ">", 0, "At least one map" );
foreach my $map ( @{$shelfmaps} ) {
  if ( $map->{'shelfmapid'} == $shelfmapid ) {
    like( $map->{'branchcode'}, qr/$library1/, "GetAllShelfmaps branchcode" );
    like( $map->{'floor'}, qr/$library1_floor1/, "GetAllShelfmaps floor" );
  }
}

ok( EditShelfmap( $library1, $library1_floor1_2, $shelfmapid ), "EditShelfmap" );
# FIXME ok( !EditShelfmap( $library1, $library1_floor1_2, $big_number ), "EditShelfmap big number" );
# FIXME ok( !EditShelfmap( $library1, $library1_floor1_2, $neg_number ), "EditShelfmap negative number" );

ok( $shelfmap = GetShelfmap( $shelfmapid ), "GetShelfmap edited" );
like( $shelfmap->{'branchcode'}, qr/$library1/, "GetShelfmap branchcode edited" );
like( $shelfmap->{'floor'}, qr/$library1_floor1_2/, "GetShelfmap floor edited" );

ok( DeleteShelfmap( $shelfmapid ), "DeleteShelfmap" );

# like( AddShelfmap( 'someunlikelylibraryname', 'first' ), qr/a foreign key constraint fail/, "Add shelfmap for unknown library");
