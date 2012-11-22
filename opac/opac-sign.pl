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

    $template->{VARS}->{'sign'}    = GetSign( $sign_id );
    $template->{VARS}->{'streams'} = GetStreamsAttachedToSignWithRecords( $sign_id );

  } else {

    $template->{VARS}->{'signs'}  = GetAllSigns();

  }

} else {
  $template->{VARS}->{'enabled'} = 0;
}

output_html_with_http_headers $query, $cookie, $template->output;
