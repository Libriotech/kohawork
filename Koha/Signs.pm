package Koha::Signs;

use C4::Context;
use Modern::Perl;

use base qw( Exporter );

# set the version for version checking
our @EXPORT = qw(
AddSign
EditSign
GetSign
GetAllSigns
DeleteSign
);

my $dbh = C4::Context->dbh;

sub AddSign {

  my ( $branchcode, $name ) = @_;

  my $sth=$dbh->prepare("INSERT INTO shelfmaps SET branchcode = ?, name = ?");
  return $sth->execute( $branchcode, $name );

}

sub EditSign {

  my ( $branchcode, $name, $sign_id ) = @_;

  my $sth = $dbh->prepare("UPDATE shelfmaps SET branchcode = ?, name = ? WHERE sign_id = ?");
  return $sth->execute( $branchcode, $name, $sign_id );

}

sub GetSign {

  my ( $sign_id ) = @_;

  return unless $sign_id;

  my $query = "SELECT s.*, b.branchname
               FROM signs as s LEFT JOIN branches as b
               ON s.branchcode = b.branchcode
               WHERE s.sign_id = ?";
  my $sth = $dbh->prepare($query);
  $sth->execute($sign_id);
  return $sth->fetchrow_hashref();

}

sub GetAllSigns {

  my $query = "SELECT s.*, b.branchname
               FROM signs as s LEFT JOIN branches as b
               ON s.branchcode = b.branchcode
               ORDER BY b.branchname, s.name";
  my $sth = $dbh->prepare($query);
  $sth->execute();
  return $sth->fetchall_arrayref({});

}

sub DeleteSign {

  my ( $sign_id ) = @_;

  return unless $sign_id;

  my $sth = $dbh->prepare('DELETE FROM signs WHERE sign_id = ?');
  return $sth->execute($sign_id);

}

1;
