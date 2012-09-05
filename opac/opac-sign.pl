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

use strict;
use warnings;

use CGI;
use C4::Auth;
use C4::Biblio;
use C4::Output;
use Koha::Signs;

my $query = new CGI;
my $deck_id      = $query->param('deck')         || '';
my $biblionumber = $query->param('biblionumber') || '' || $query->param('bib');

my ( $template, $borrowernumber, $cookie ) = get_template_and_user(
  {
    template_name   => "opac-sign.tt",
    query           => $query,
    type            => "opac",
    authnotrequired => ( C4::Context->preference("OpacPublic") ? 1 : 0 ),
    flagsrequired => { borrow => 1 },
  }
);

if ( C4::Context->preference("OPACDigitalSigns") ) {

  # Display a deck of signs
  if ( $deck_id ne '' ) {

    my $signs = GetSignsAttachedToDeck( $deck_id );
    my @changedsigns;
    my %uniquerecords;

    # Add records to the signs
    foreach my $sign ( @{$signs} ) {
      my $records = RunSQL( $sign->{'savedsql'} );
      $sign->{'records'} = $records;
      push(@changedsigns, $sign);
      # Create a hash of unique records
      foreach my $rec ( @{$records} ) {
        if ( !$uniquerecords{$rec->{'biblionumber'}} ) {
          # This would be the place to add expensive processing of each record
          $uniquerecords{$rec->{'biblionumber'}} = $rec;
        }
      }
    }

    $template->{VARS}->{'deck'}  = GetDeck( $deck_id );
    $template->{VARS}->{'signs'} = \@changedsigns;
    $template->{VARS}->{'records'} = \%uniquerecords;

  # Display a single record, for AJAXing into a sign
  } elsif ( $biblionumber ne '' ) {

    binmode STDOUT, ':encoding(UTF-8)'; # Non-ASCII is broken without this

    my $record = GetMarcBiblio($biblionumber);
    if ( ! $record ) {
      print $query->redirect("/cgi-bin/koha/errors/404.pl"); # escape early
      exit;
    }
    $template->{VARS}->{'record'} = $record;

    # Get the template from the syspref and make sure it is interpreted as a
    # template string, not a filename
    $template->filename( \C4::Context->preference("OPACDigitalSignsRecordTemplate") );

  # As a default, display a list of all decks
  } else {

    $template->{VARS}->{'decks'}  = GetAllDecks();

  }

} else {
  $template->{VARS}->{'enabled'} = 0;
}

output_html_with_http_headers $query, $cookie, $template->output;
