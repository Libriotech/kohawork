package Koha::Shelfmaps;

use C4::Context;
use Modern::Perl;

use base qw( Exporter );

# set the version for version checking
our @EXPORT = qw(
  AddShelfmap
  EditShelfmap
  GetShelfmap
  GetAllShelfmaps
  DeleteShelfmap
);

my $dbh = C4::Context->dbh;

sub AddShelfmap {

  my ( $branchcode, $floor ) = @_;

  my $sth=$dbh->prepare("INSERT INTO shelfmaps SET branchcode = ?, floor = ?");
  return $sth->execute( $branchcode, $floor );

}

sub EditShelfmap {

  my ( $branchcode, $floor, $shelfmapid ) = @_;

  my $sth = $dbh->prepare("UPDATE shelfmaps SET branchcode = ?, floor = ? WHERE shelfmapid = ?");
  return $sth->execute( $branchcode, $floor, $shelfmapid );

}

sub GetShelfmap {

  my ( $shelfmapid ) = @_;
  
  return unless $shelfmapid;

  my $query = "SELECT shelfmapid, branchcode, floor FROM shelfmaps WHERE shelfmapid = ?";
	my $sth = $dbh->prepare($query);
	$sth->execute($shelfmapid);
	return $sth->fetchrow_hashref();

}

sub GetAllShelfmaps {

	my $query = "SELECT s.*, b.branchname
	             FROM shelfmaps as s, branches as b
	             WHERE s.branchcode = b.branchcode";
	my $sth = $dbh->prepare($query);
	$sth->execute();
	return $sth->fetchall_arrayref({});

}

sub DeleteShelfmap {

  my ( $shelfmapid ) = @_;

  return unless $shelfmapid;

  my $sth = $dbh->prepare('DELETE FROM shelfmaps WHERE shelfmapid = ?');
  return $sth->execute($shelfmapid);

}

1;
