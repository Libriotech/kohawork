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

Arguments:

=over 4

=item * $bibliodata = the result of a call to GetBiblioData()

=item * $borrower = the result of a call to Koha::Borrowers->new->find( $borrowernumber )

=item * $userid = The userid/cardnumber of the user that the requested document is meant for, at the Home Library

=back

=cut

sub send_ItemRequested {

    my ( $bibliodata, $borrower, $userid ) = @_;

    # FIXME Return with an error if there is no nncip_uri
    my $nncip_uri = GetBorrowerAttributeValue( $borrower->borrowernumber, 'nncip_uri' );

    my $msg = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
    <ns1:NCIPMessage xmlns:ns1=\"http://www.niso.org/2008/ncip\" ns1:version=\"http://www.niso.org/schemas/ncip/v2_02/ncip_v2_02.xsd\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.niso.org/2008/ncip http://www.niso.org/schemas/ncip/v2_02/ncip_v2_02.xsd\">
	    <!-- Usage in NNCIPP 1.0 is in use-case 3, call #8: Owner library informs Home library that a user requests one Item -->
	    <ns1:ItemRequested>
		    <!-- The InitiationHeader, stating from- and to-agency, is mandatory. -->
		    <ns1:InitiationHeader>
			    <!-- Owner Library -->
			    <ns1:FromAgencyId>
				    <ns1:AgencyId>NO-" . C4::Context->preference('ILLISIL') . "</ns1:AgencyId>
			    </ns1:FromAgencyId>
			    <!-- Home Library -->
			    <ns1:ToAgencyId>
				    <ns1:AgencyId>NO-" . $borrower->cardnumber . "</ns1:AgencyId>
			    </ns1:ToAgencyId>
		    </ns1:InitiationHeader>
		    <!-- The UserId must be a NLR-Id (National Patron Register) -->
		    <ns1:UserId>
			    <ns1:UserIdentifierValue>" . $userid . "</ns1:UserIdentifierValue>
		    </ns1:UserId>
		    <!-- The ItemId must uniquely identify the requested Item in the scope of the FromAgencyId. -->
		    <!-- Use ItemOptimalFields.BibliographicDescription that is mandatory in NNCIPP 1.0, to describe the ItemId -->
		    <!-- NNCIPP 1.0 only support ItemId and not the alternativ use of Bibliographic and RequestId. -->
		    <ns1:ItemId>
			    <ns1:ItemIdentifierValue>" . "FIXME" . "</ns1:ItemIdentifierValue>
		    </ns1:ItemId>
		    <!-- The RequestType must be one of the following  {“Loan”|”Copy”|”LoanNoReservation”|”LII”|”LIINoReservation”|”Depot”}-->
		    <ns1:RequestType>Loan</ns1:RequestType>
		    <!-- RequestScopeType is mandatory and must be \"0\", signaling that the request is on title-level (and not Item-level - even though the request was on a Id that uniquely identify the requested Item) -->
		    <ns1:RequestScopeType>0</ns1:RequestScopeType>
		    <!-- Use of ItemOptimalFields is mandatory in NNCIPP 1.0 -->
		    <ns1:ItemOptionalFields>
			    <!-- BibliographicDescription is used, as needed, to supplement the ItemId -->
			    <ns1:BibliographicDescription>
				    <ns1:Author>"             . $bibliodata->{'author'} . "</ns1:Author>
				    <ns1:PlaceOfPublication>" . $bibliodata->{'place'} . "</ns1:PlaceOfPublication>
				    <ns1:PublicationDate>"    . $bibliodata->{'copyrightdate'} . "</ns1:PublicationDate>
				    <ns1:Publisher>"          . $bibliodata->{'publishercode'} . "</ns1:Publisher>
				    <ns1:Title>"              . $bibliodata->{'title'} . "</ns1:Title>
				    <ns1:Language>Use three letter codes (ISO-639-2)</ns1:Language>
				    <ns1:MediumType>Use values as defined in Implementation-part of NCIP on page 23.</ns1:MediumType> <!-- Map from " . $bibliodata->{'itemtype'} . "? -->
			    </ns1:BibliographicDescription>
		    </ns1:ItemOptionalFields>
	    </ns1:ItemRequested>
    </ns1:NCIPMessage>";

    logaction( 'ILL', 'ItemRequested', $bibliodata->{'biblionumber'}, $msg );
    return _send_message( $msg, $nncip_uri );

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
