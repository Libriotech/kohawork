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
use C4::Items qw { AddItem };
use C4::Koha;
use C4::Members;
use C4::Members::Attributes qw( GetBorrowerAttributeValue );
use C4::Output;
use C4::Context;
use Koha::ILLRequests;
use Koha::ILLRequest::Backend::NNCIPP qw( SendRequestItem GetILLPartners quickfix_requestbib quickfix_set_ordered_from );
use URI::Escape;

my $input = CGI->new;
my $illpartner = $input->param('illpartner');

my ( $template, $borrowernumber, $cookie ) = get_template_and_user( {
    template_name => 'ill/ill-request.tt',
    query         => $input,
    type          => 'intranet',
    flagsrequired => { ill => '*' },
} );

# Make an actual request
if ( $illpartner ) {

    my $partner   = GetMemberDetails( $illpartner ); # Lookup on borrowernumber
    my $borrower  = GetMemberDetails( undef, $input->param('cardnumber') ); # Lookup on cardnumber
    my $nncip_uri = GetBorrowerAttributeValue( $illpartner, 'nncip_uri' );

    # Create a completely dummy record
    my $xml = '<record>
    <datafield tag="245" ind1=" " ind2=" ">
        <subfield code="a">Dummy ILL record</subfield>
    </datafield>
    </record>';
    my $record = MARC::Record->new_from_xml( $xml, 'UTF-8' );
    my ( $biblionumber, $biblioitemnumber ) = AddBiblio( $record, 'FA' );

    # Add an item
    my $item = {
        'homebranch'    => 'ILL',
        'holdingbranch' => 'ILL',
        'itype'         => 'ILL',
    };
    my ( $x_biblionumber, $x_biblioitemnumber, $itemnumber ) = AddItem( $item, $biblionumber );

    # Save the request locally
    # We need to save the request before we send it to the remote library,
    # because the request should contain the locally created RequestId
    my $illRequest   = Koha::ILLRequests->new;
    my $request = $illRequest->request({
        'biblionumber'   => $biblionumber,
        'branch'         => 'ILL',
        'borrower'       => $borrower->{'borrowernumber'}, # borrowernumber
        'reqtype'        => $input->param('reqtype'),
    });
    if ( $request ) {
        my $requestid = $request->{'status'}->{'id'};
        # Make sure the status is ORDERED. FIXME Do this after confirmation is returned?
        $request->editStatus({
            'ordered_from' => $illpartner,
            'status' => 'ORDERED',
            'remote_id' => 'NO-' . C4::Context->preference('ILLISIL') . ':' . $requestid,
            'remote_barcode' => $input->param('id'), # FIXME This field should be renamed
        });
        # Send the request to the remote library
        my $response = SendRequestItem({
            'nncip_uri' => $nncip_uri,
            'to_agency' => $partner->{ 'cardnumber' },
            'userid'    => $borrower->{'cardnumber'},
            'idtype'    => $input->param('idtype'),
            'id'        => $input->param('id'),
            'requestid' => $requestid,
            'reqtype'   => $input->param('reqtype'),
        });
        # Update the dummy MARC record with bibliographic data from the response
        my $bibdata = $response->{data}->{'ns1:RequestItemResponse'}->{'ns1:ItemOptionalFields'}->{'ns1:BibliographicDescription'};
        my $xml = '<record>
        <datafield tag="100" ind1=" " ind2=" ">
            <subfield code="a">' . $bibdata->{'ns1:Author'} . '</subfield>
        </datafield>
        <datafield tag="245" ind1=" " ind2=" ">
            <subfield code="a">' . $bibdata->{'ns1:Title'} . '</subfield>
        </datafield>
        <datafield tag="260" ind1=" " ind2=" ">
            <subfield code="a">' . $bibdata->{'ns1:PlaceOfPublication'} . '</subfield>
            <subfield code="b">' . $bibdata->{'ns1:Publisher'} .          '</subfield>
            <subfield code="c">' . $bibdata->{'ns1:PublicationDate'} .    '</subfield>
        </datafield>
        </record>';
        my $record = MARC::Record->new_from_xml( $xml, 'UTF-8' );
        ModBiblio( $record, $biblionumber, 'FA' );

        # FIXME Update the ILL Request with the bibliographic data
        quickfix_requestbib ({
            requestid => $requestid,
            title     => $bibdata->{'ns1:Title'},
            author    => $bibdata->{'ns1:Author'},
        });
  
        $template->param(
            'partner'   => $partner,
            'response'  => $response,
            'requestid' => $requestid,
        );
    } else {
        # FIXME
    }


} else {

    $template->param(
        'illpartners' => GetILLPartners(),
        'reqtypes'    => GetAuthorisedValues( 'ILLREQTYPE' ),
    );

}

output_html_with_http_headers( $input, $cookie, $template->output );
