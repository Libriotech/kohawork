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
use Data::Dumper; # FIXME Debug only

binmode STDOUT, ':encoding(UTF-8)'; # FIXME Non-ASCII is broken without this

my $query   = CGI->new;
my $sign_id = $query->param('sign')         || '';

my ( $template, $borrowernumber, $cookie ) = get_template_and_user({
  'template_name'   => 'opac-sign.tt',
  'query'           => $query,
  'type'            => 'opac',
  'authnotrequired' => ( C4::Context->preference('OpacPublic') ? 1 : 0 ),
  'flagsrequired'   => { borrow => 1 },
});

if ( C4::Context->preference('OPACDigitalSigns') ) {

  $template->{VARS}->{'recordtemplate'}      = C4::Context->preference('OPACDigitalSignsRecordTemplate');
  $template->{VARS}->{'OPACDigitalSignsCSS'} = C4::Context->preference( 'OPACDigitalSignsCSS' );

  # Display a sign with streams
  if ( $sign_id ne '' ) {

    my $streams = GetStreamsAttachedToSign( $sign_id );
    my @changedstreams;

    # Add records to the streams
    foreach my $stream ( @{$streams} ) {

      my $records = RunSQL( ReplaceParamsInSQL( $stream->{'savedsql'}, $stream->{'params'} ) );
      my @processed_records;
      foreach my $rec ( @{$records} ) {
        my $marc = GetMarcBiblio( $rec->{'biblionumber'} );
        if ( ! $marc ) {
          next;
        }
        # FIXME Cache the processed records (more than one sign can have the same record)
        $rec->{'marc'} = $marc;
        push @processed_records, $rec;
      }
      $stream->{'records'} = \@processed_records;
      push @changedstreams, $stream;

    }

    $template->{VARS}->{'sign'}                = GetSign( $sign_id );
    $template->{VARS}->{'streams'}             = \@changedstreams;

  } else {

    $template->{VARS}->{'signs'}  = GetAllSigns();

  }

} else {
  $template->{VARS}->{'enabled'} = 0;
}

output_html_with_http_headers $query, $cookie, $template->output;
