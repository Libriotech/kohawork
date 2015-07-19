package Koha::ILLRequest::Backend::NNCIPP;

# Copyright Magnus Enger Libriotech 2015
#
# This file is part of Koha.
#
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

use C4::Members::Attributes qw ( GetBorrowerAttributeValue );
use C4::Log;
use HTTP::Tiny;
use Modern::Perl;
use Data::Dumper; # FIXME Debug
use base qw(Exporter);

our @EXPORT_OK = qw( 
    send_ItemRequested
);

=head1 NAME

Koha::ILLRequest::Backend::NNCIPP - Koha ILL Backend: NNCIPP (Norwegian NCIP Profile)

=head1 SYNOPSIS

=head1 DESCRIPTION

A first stub file to implement NNCIPP for Koha. 

=head1 SUBROUTINES

=head2 send_ItemRequested 

Typically triggered when a library has logged into the OPAC and placed an ILL
request there. This message is sent back to the ILS of the library that made 
the request, so that they know what they have requested. 

=cut

sub send_ItemRequested {

    my ( $request_id, $bibliodata, $borrower ) = @_;
    
    # FIXME Return with an error if there is no nncip_uri
    my $nncip_uri = GetBorrowerAttributeValue( $borrower->borrowernumber, 'nncip_uri' );

    my $msg = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
<ns1:NCIPMessage ns1:version=\"http://www.niso.org/schemas/ncip/v2_02/ncip_v2_02.xsd\" xmlns:ns1=\"http://www.niso.org/2008/ncip\">
    <ns1:ItemRequested>
        <ns1:InitiationHeader>
            <ns1:FromAgencyId>
                <ns1:AgencyId>NO-" . C4::Context->preference('ILLISIL') . "</ns1:AgencyId>
            </ns1:FromAgencyId>
            <ns1:ToAgencyId>
                <ns1:AgencyId>NO-" . $borrower->cardnumber . "</ns1:AgencyId>
            </ns1:ToAgencyId>
        </ns1:InitiationHeader>
        <ns1:UserId>
            <ns1:UserIdentifierValue>" . $borrower->cardnumber . "</ns1:UserIdentifierValue>
        </ns1:UserId>
        <ns1:BibliographicId>
            <ns1:BibliographicItemId>
                <ns1:BibliographicItemIdentifier>" . $bibliodata->{'biblionumber'} . "</ns1:BibliographicItemIdentifier>
            </ns1:BibliographicItemId>
        </ns1:BibliographicId>
        <ns1:RequestId>
            <ns1:AgencyId>NO-" . C4::Context->preference('ILLISIL') . "</ns1:AgencyId>
            <ns1:RequestIdentifierValue>$request_id</ns1:RequestIdentifierValue>
        </ns1:RequestId>
        <ns1:RequestType>Loan</ns1:RequestType>
        <ns1:RequestScopeType>0</ns1:RequestScopeType>
        <ns1:ItemOptionalFields>
            <ns1:BibliographicDescription>
                <ns1:Author>"           . $bibliodata->{'author'} . "</ns1:Author>
                <ns1:Title>"            . $bibliodata->{'title'} . "</ns1:Title>
                <ns1:PublicationPlace>" . $bibliodata->{'place'} . "</ns1:PublicationPlace>
                <ns1:Publisher>"        . $bibliodata->{'publishercode'} . "</ns1:Publisher>
                <ns1:PublicationDate>"  . $bibliodata->{'copyrightdate'} . "</ns1:PublicationDate>
                <ns1:MediumType>"       . $bibliodata->{'itemtype'} . "</ns1:MediumType>
            </ns1:BibliographicDescription>
        </ns1:ItemOptionalFields>
    </ns1:ItemRequested>
</ns1:NCIPMessage>";

    logaction( 'ILL', 'ItemRequested', $bibliodata->{'biblionumber'}, $msg );
    _send_message( $msg, $nncip_uri );

}

=head1 INTERNAL SUBROUTINES

=head2 _send_message

Do the actual sending of XML messages to NCIP endpoints.

=cut

sub _send_message {

    my ( $msg, $endpoint ) = @_;
    
    my $http = HTTP::Tiny->new();
    my $response = $http->post( $endpoint, { 'content' => $msg } );
    
    if ( $response->{success} ){
        logaction( 'ILL', 'response_success', undef, $response->{'content'} );
        return { 'success' => 1, 'msg' => $response->{'content'} };
    } else {
        my $msg = "ERROR: $response->{status} $response->{reason}";
        logaction( 'ILL', 'response_success', undef, $msg );
        return { 'success' => 0, 'msg' => $msg };
    }

}

=head1 AUTHOR

Magnus Enger <magnus@libriotech.no>

=cut

1;
