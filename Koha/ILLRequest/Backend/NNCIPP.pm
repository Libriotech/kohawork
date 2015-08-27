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
use C4::Items;
use HTTP::Tiny;
use MARC::Record;
use XML::Simple;
use Modern::Perl;
use Data::Dumper; # FIXME Debug
use base qw(Exporter);

our @EXPORT_OK = qw(
    SendLookupAgency
    send_ItemRequested

    GetILLPartners
);

=head1 NAME

Koha::ILLRequest::Backend::NNCIPP - Koha ILL Backend: NNCIPP (Norwegian NCIP Profile)

=head1 SYNOPSIS

=head1 DESCRIPTION

A first stub file to implement NNCIPP for Koha.

=head1 SUBROUTINES

=head2 SendLookupAgency

The argument to this function is a hashref with one of these keyes:

=over 4

=item * borrowernumber

=item * nncip_uri

=back

=cut

sub SendLookupAgency {

    my ( $args ) = @_;

    my $nncip_uri;
    if ( $args->{'nncip_uri'} ) {
        $nncip_uri = $args->{'nncip_uri'};
    } elsif ( $args->{'borrowernumber'} ) {
        $nncip_uri = GetBorrowerAttributeValue( $args->{'borrowernumber'}, 'nncip_uri' );
    }

    my $msg = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
    <ns1:NCIPMessage xmlns:ns1=\"http://www.niso.org/2008/ncip\"
    ns1:version=\"http://www.niso.org/schemas/ncip/v2_02/ncip_v2_02.xsd\"
    xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
    xsi:schemaLocation=\"http://www.niso.org/2008/ncip http://www.niso.org/schemas/ncip/v2_02/ncip_v2_02.xsd\">
	    <!-- Usage in NNCIPP 1.0 is in use-case 1, call #1:
    i) ask for the shipping address that shuld be used to fulfill a lending request
    ii) check what versions of NNCIPP the agency comply to -->
	    <ns1:LookupAgency>
		    <!-- The InitiationHeader, stating from- and to-agency, is mandatory. -->
		    <ns1:InitiationHeader>
			    <!-- A Library -->
			    <ns1:FromAgencyId>
				    <ns1:AgencyId>NO-" . C4::Context->preference('ILLISIL') . "</ns1:AgencyId>
			    </ns1:FromAgencyId>
			    <!-- A Library -->
			    <ns1:ToAgencyId>
				    <ns1:AgencyId>NO-" . $args->{'cardnumber'} . "</ns1:AgencyId>
			    </ns1:ToAgencyId>
		    </ns1:InitiationHeader>
		    <!-- State which Agency you are asking information about, normaly equal to ToAgency. -->
		    <ns1:AgencyId>NO-" . $args->{'cardnumber'} . "</ns1:AgencyId>
		    <!-- State what information element you are asking for-->
		    <!-- It is mandatory to support \"Application Profile Supported Type\" in NNCIP.  -->
		    <ns1:AgencyElementType>Application Profile Supported Type</ns1:AgencyElementType>
		    <!-- It is recomended to support \"Agency Address Information\" in NNCIPP. -->
		    <ns1:AgencyElementType>Agency Address Information</ns1:AgencyElementType>
	    </ns1:LookupAgency>
    </ns1:NCIPMessage>";

    logaction( 'ILL', 'LookupAgency', undef, $msg );
    return _send_message( $msg, $nncip_uri );

}

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

    # Pick out an item to tie the request to (we take the first one that has a barcode)
    my $barcode;
    my @items = GetItemsInfo( $bibliodata->{'biblionumber'} );
    foreach my $item ( @items ) {
        if ( $item->{'barcode'} ne '' ) {
            $barcode = $item->{'barcode'};
            last;
        }
    }

    # Pick out the language code from 008, position 35-37
    my $marcxml = $bibliodata->{'marcxml'};
    my $record = MARC::Record->new_from_xml( $marcxml, 'UTF-8' );
    my $f008 = $record->field( '008' )->data();
    my $lang_code = '   ';
    if ( $f008 ) {
        $lang_code = substr $f008, 35, 3;
    }

    my $msg = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
    <ns1:NCIPMessage xmlns:ns1=\"http://www.niso.org/2008/ncip\" ns1:version=\"http://www.niso.org/schemas/ncip/v2_02/ncip_v2_02.xsd\" 
    xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.niso.org/2008/ncip http://www.niso.org/schemas/ncip/v2_02/ncip_v2_02.xsd\">
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
		    <!-- The ToAgency may then mirror back this ItemId in a RequestItem-call to order it.-->
		    <!-- Note: NNCIPP do not support use of BibliographicId insted of ItemId, in this case. -->
		    <ns1:ItemId>
			    <!-- All Items must have a scannable Id either a RFID or a Barcode or Both. -->
			    <!-- In the case of both, start with the Barcode, use colon and no spaces as delimitor.-->
			    <ns1:ItemIdentifierType>Barcode</ns1:ItemIdentifierType>
			    <ns1:ItemIdentifierValue>" . $barcode . "</ns1:ItemIdentifierValue>
		    </ns1:ItemId>
		    <!-- The RequestType must be one of the following: -->
		    <!-- Physical, a loan (of a physical item, create a reservation if not available) -->
		    <!-- Non-Returnable, a copy of a physical item - that is not required to return -->
		    <!-- PhysicalNoReservation, a loan (of a physical item), do NOT create a reservation if not available -->
		    <!-- LII, a patron initialized physical loan request, threat as a physical loan request -->
		    <!-- LIINoReservation, a patron initialized physical loan request, do NOT create a reservation if not available -->
		    <!-- Depot, a border case; some librarys get a box of (foreign language) books from the national library -->
		    <!-- If your library dont recive 'Depot'-books; just respond with a \"Unknown Value From Known Scheme\"-ProblemType -->
		    <ns1:RequestType>Physical</ns1:RequestType>
		    <!-- RequestScopeType is mandatory and must be \"Title\", signaling that the request is on title-level -->
		    <!-- (and not Item-level - even though the request was on a Id that uniquely identify the requested Item) -->
		    <ns1:RequestScopeType>Title</ns1:RequestScopeType>
		    <!-- Include ItemOptionalFields.BibliographicDescription if you wish to recive Bibliographic data in the response -->
		    <ns1:ItemOptionalFields>
			    <!-- BibliographicDescription is used, as needed, to supplement the ItemId -->
			    <ns1:BibliographicDescription>
				    <ns1:Author>"             . $bibliodata->{'author'} . "</ns1:Author>
				    <ns1:PlaceOfPublication>" . $bibliodata->{'place'} . "</ns1:PlaceOfPublication>
				    <ns1:PublicationDate>"    . $bibliodata->{'copyrightdate'} . "</ns1:PublicationDate>
				    <ns1:Publisher>"          . $bibliodata->{'publishercode'} . "</ns1:Publisher>
				    <ns1:Title>"              . $bibliodata->{'title'} . "</ns1:Title>
				    <ns1:Language>"           . $lang_code . "</ns1:Language>
				    <ns1:MediumType>Book</ns1:MediumType> <!-- Map from " . $bibliodata->{'itemtype'} . "? -->
			    </ns1:BibliographicDescription>
		    </ns1:ItemOptionalFields>
	    </ns1:ItemRequested>
    </ns1:NCIPMessage>";

    logaction( 'ILL', 'ItemRequested', $bibliodata->{'biblionumber'}, $msg );
    return _send_message( $msg, $nncip_uri );

}

=head2 GetILLPartners

Return a list of all borrowers that have the nncip_uri extended attribute set.

=cut

sub GetILLPartners {

    my $dbh = C4::Context->dbh();
    my $sth = $dbh->prepare("SELECT *
                 FROM borrower_attributes AS ba, borrowers AS b
                 WHERE ba.code = 'nncip_uri'
                   AND attribute != ''
                   AND ba.borrowernumber = b.borrowernumber
                 ORDER BY b.surname ASC");
    $sth->execute();
    return $sth->fetchall_arrayref( {} );

}

=head1 INTERNAL SUBROUTINES

=head2 _send_message

Do the actual sending of XML messages to NCIP endpoints.

=cut

sub _send_message {

    my ( $msg, $endpoint ) = @_;

    my $response = HTTP::Tiny->new->request( 'POST', $endpoint, { 'content' => $msg } );

    if ( $response->{success} ){
        logaction( 'ILL', 'response_success', undef, $response->{'content'} );
        return {
            'success' => 1,
            'msg'     => $response->{'content'},
            'data'    => XMLin( $response->{'content'} ),
        };
    } else {
        my $msg = "ERROR: $response->{status} $response->{reason}";
        logaction( 'ILL', 'response_success', undef, $msg );
        return {
            'success' => 0,
            'msg' => $msg,
        };
    }

}

=head1 AUTHOR

Magnus Enger <magnus@libriotech.no>

=cut

1;
