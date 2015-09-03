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
use C4::Biblio;
use C4::Branch;
use C4::Items qw { GetItemnumberFromBarcode };
use C4::Koha;
use C4::Members;
use C4::Members::Attributes qw( GetBorrowerAttributeValue );
use C4::Output;
use C4::Context;
use Koha::ILLRequests;
use Koha::ILLRequest::Backend::NNCIPP qw( SendItemShipped );
use URI::Escape;

my $input   = CGI->new;
my $status  = $input->param('status');
my $barcode = $input->param('barcode');

my ( $template, $borrowernumber, $cookie ) = get_template_and_user( {
    template_name => 'ill/ill-status.tt',
    query         => $input,
    type          => 'intranet',
    flagsrequired => { ill => '*' },
} );

if ( $barcode && $status && $status eq 'SHIPPED' ) {

    # Find the right request, based on the barcode
    my $itemnumber = GetItemnumberFromBarcode( $barcode );
    my $biblionumber = GetBiblionumberFromItemnumber( $itemnumber );
    
    # Find all requests for the given biblionumber
    my $illRequests = Koha::ILLRequests->new;
    my $requests = $illRequests->search({
        'biblionumber' => $biblionumber,
        'status'       => 'NEW',
    });
    # We are looking for the oldest request for this biblionumber, so we use the zero'th one
    my $request = $requests->[0];
    # Change the status
    $request->editStatus({ 'status' => 'SHIPPED' });
    # Get the full details
    $request->getFullDetails( { brw => 1 } );
    
    # Send an ItemShipped message to the library that ordered the item
    my $response = SendItemShipped({
        'request' => $request,
        'barcode' => $barcode,
    });
    
    # Get full details for all NEW requests for the biblio in question
    my $requests_details;
    foreach my $rq ( @{$requests} ) {
        push @{$requests_details}, $rq->getFullDetails( { brw => 1 } );
    }

    $template->param(
        'status'   => $status,
        'request'  => $request,
        'requests' => $requests_details,
        'response' => $response,
        'barcode'  => $barcode,
        'itemnumber'   => $itemnumber,
        'biblionumber' => $biblionumber,
    );

}

$template->param(
    'statuses'    => GetAuthorisedValues( 'ILLSTATUS' ),
);

output_html_with_http_headers( $input, $cookie, $template->output );
