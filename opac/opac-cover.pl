#!/usr/bin/perl

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

use CGI;
use C4::Auth;
use C4::Biblio;
use C4::Images;
use C4::Koha;
use C4::Output;
use LWP::UserAgent;
use Modern::Perl;

use Data::Dumper; # FIXME Debug
my $debug = 0;

###############################################################################
# PLEASE NOTE!                                                                #
# This script is a placeholder, it will be broken out as a separate enh later #
###############################################################################

my $query = new CGI;
my $biblionumber = $query->param('biblionumber') || '' || $query->param('bib');

my ( $template, $borrowernumber, $cookie ) = get_template_and_user(
  {
    template_name   => \"",
    query           => $query,
    type            => "opac",
    authnotrequired => ( C4::Context->preference("OpacPublic") ? 1 : 0 ),
    flagsrequired => { borrow => 1 },
  }
);

if ( $biblionumber ne '' ) {

  # TODO Check the cache

  # TODO Check that OPACLocalCoverImages is activated
  my @covers = ListImagesForBiblio( $biblionumber );
  warn 'Local covers: ', Dumper @covers if $debug;
  if ( $covers[0] ) {
    # TODO Cache the result
    my $url = '/cgi-bin/koha/opac-image.pl?thumbnail=' . $covers[0] . '&biblionumber=' . $biblionumber;
    warn 'URL: ', $url if $debug;
    print $query->redirect( $url );
    exit;
  }

  my $record = GetMarcBiblio( $biblionumber );
  my $isbn   = GetNormalizedISBN( undef, $record, C4::Context->preference("marcflavor") ) || '';

  if ( $isbn ne '' ) {
    warn "ISBN: $isbn" if $debug;

    my $ua = LWP::UserAgent->new;

    # Open Library
    my $url = 'http://covers.openlibrary.org/b/isbn/' . $isbn . '-M.jpg';

    # Do a HEAD request and check the status of the response.
    # Adding ?default=false to the URL makes the service return 404 when an
    # image is not found instead of returning a blank 1x1 image
    # http://openlibrary.org/dev/docs/api/covers
    my $url2 .= '?default=false';
    # We don't actually need this logic at the moment, though, since it is the
    # last one we try
    # my $response = $ua->head( $url2 );
    # if ($response->is_success) {
    #   # TODO Cache the result
    #   print $query->redirect( $url2 );
    #   exit;
    # } else {
    #   warn $response->status_line, " for ", $url2 if $debug;
    # }

    print $query->redirect( $url );
  }

  # FIXME What to do when there is no ISBN?
  print $query->redirect( 'http://div.libriotech.no/files/2012/nicole.jpg' );

}
