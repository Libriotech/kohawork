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

  my ( $name, $report ) = @_;

  my $sth=$dbh->prepare("INSERT INTO signs SET name = ?, saved_sql_id = ?");
  return $sth->execute( $name, $report );

}

sub EditSign {

  my ( $name, $report, $sign_id ) = @_;

  my $sth = $dbh->prepare("UPDATE signs SET name = ?, saved_sql_id = ? WHERE sign_id = ?");
  return $sth->execute( $name, $report, $sign_id );

}

sub GetSign {

  my ( $sign_id ) = @_;

  return unless $sign_id;

  my $query = "SELECT s.*
               FROM signs as s
               WHERE s.sign_id = ?";
  my $sth = $dbh->prepare($query);
  $sth->execute($sign_id);
  return $sth->fetchrow_hashref();

}

sub GetAllSigns {

  my $query = "SELECT s.*, sq.report_name as report_name
               FROM signs AS s, saved_sql AS sq
               WHERE s.saved_sql_id = sq.id
               ORDER BY s.name";
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
