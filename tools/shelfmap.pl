#!/usr/bin/perl
#
# Copyright 2012 Magnus Enger Libriotech
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#
#

=head1 NAME

shelfmap.pl - Script for handling uploading and administration of shelf maps.

=head1 SYNOPSIS

shelfmap.pl

=head1 DESCRIPTION

This script allows the uploading of shelf maps as image files, as well
as adding points of interest to the maps.

=cut

use strict;
use warnings;

use File::Temp;
use CGI;
use GD;
use Data::Dumper; # DEBUG
use C4::Context;
use C4::Auth;
use C4::Output;
use C4::Images;
use C4::UploadedFile;
use C4::Branch;

my $cgi = new CGI;
my $dbh = C4::Context->dbh;
my $script_name = 'shelfmap.pl';

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => "tools/shelfmap.tmpl",
        query           => $cgi,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { tools => 'edit_shelf_maps' },
        debug           => 0,
    }
);

my $op         = $cgi->param('op') || '';
my $shelfmapid = $cgi->param('shelfmapid') || '';

if ( $op eq 'add_map' ) {

  # FIXME Is it possible to avoid duplicating this code?
	my $branches = GetBranches();
  my @branchloop;
  for my $thisbranch (sort { $branches->{$a}->{branchname} cmp $branches->{$b}->{branchname} } keys %$branches) {
    push @branchloop, {
        value      => $thisbranch,
        branchname => $branches->{$thisbranch}->{'branchname'},
    };
  }

  $template->param(
    'branchloop' => \@branchloop,
    'op' => 'map_form',
  );

} elsif ( $op eq 'edit_map' && $shelfmapid ne '') {

	my $shelfmap = GetShelfmap( $shelfmapid );

	my $branches = GetBranches();
  my @branchloop;
  for my $thisbranch (sort { $branches->{$a}->{branchname} cmp $branches->{$b}->{branchname} } keys %$branches) {
    push @branchloop, {
        value      => $thisbranch,
        selected   => $thisbranch eq $shelfmap->{'branchcode'},
        branchname => $branches->{$thisbranch}->{'branchname'},
    };
  }

	$template->param(
	  'shelfmap' => $shelfmap,
	  'branchloop' => \@branchloop,
    'op' => 'map_form'
  );

} elsif ( $op eq 'save_map' ) {

  if ($cgi->param('shelfmapid')) {
    my $sth=$dbh->prepare("UPDATE shelfmaps SET branchcode = ?, floor = ? WHERE shelfmapid = ?");
    $sth->execute( $cgi->param('branchcode'), $cgi->param('floor'), $cgi->param('shelfmapid') );
  } else {
    my $sth=$dbh->prepare("INSERT INTO shelfmaps SET branchcode = ?, floor = ?");
    $sth->execute( $cgi->param('branchcode'), $cgi->param('floor') );
  }

  print $cgi->redirect($script_name);

} elsif ( $op eq 'del_map' ) {

  my $shelfmap = GetShelfmap( $shelfmapid );

	$template->param(
    'op'          => 'del_map',
    'shelfmap'    => $shelfmap,
    'script_name' => $script_name,
  );

} elsif ( $op eq 'del_map_ok' ) {

  DeleteShelfmap( $shelfmapid );
  
  $template->param(
    'op'          => 'del_map_ok',
    'script_name' => $script_name,
  );
  
} else {

  my $shelfmaps = GetAllShelfmaps();

	$template->param(
	  'shelfmaps' => $shelfmaps,
	  'else'      => 1
	);

}

output_html_with_http_headers $cgi, $cookie, $template->output;

exit 0;

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

=head1 AUTHORS

Written by Magnus Enger of Libriotech, in part based on code by Jared
Camins-Esakov of C & P Bibliography Services, Koustubha Kale of Anant
Corporation and Chris Nighswonger of Foundation Bible College.

=cut
