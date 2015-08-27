#!/usr/bin/perl

# Copyright 2015 Magnus Enger Libriotech
#
# This file is part of Koha.
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use Modern::Perl;
use CGI;
use C4::Auth;
use C4::Branch;
use C4::Members;
use C4::Members::Attributes qw( GetBorrowerAttributeValue );
use C4::Output;
use C4::Context;
use Koha::ILLRequest::Backend::NNCIPP qw( SendLookupAgency GetILLPartners );
use URI::Escape;

my $input = CGI->new;
my $illpartner = $input->param('illpartner');

my ( $template, $borrowernumber, $cookie ) = get_template_and_user( {
    template_name => 'ill/ill-handshake.tt',
    query         => $input,
    type          => 'intranet',
    flagsrequired => { ill => '*' },
} );

# Check a single partner
if ( $illpartner ) {

    my $partner = GetMemberDetails( $illpartner );
    my $nncip_uri = GetBorrowerAttributeValue( $illpartner, 'nncip_uri' );
    my $response = SendLookupAgency({
        'nncip_uri' => $nncip_uri,
        'to_agency' => $partner->{ 'cardnumber' },
    });
    
    $template->param(
      'partner'   => $partner,
      'nncip_uri' => $nncip_uri,
      'response'  => $response,
    );

}

$template->param(
    'illpartners' => GetILLPartners(),
);

output_html_with_http_headers( $input, $cookie, $template->output );
