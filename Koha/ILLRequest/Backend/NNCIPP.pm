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

use C4::Members;
use C4::Members::Attributes qw ( GetBorrowerAttributeValue );
use C4::Log;
use C4::Items;
use Koha::Borrowers;
use HTTP::Tiny;
use MARC::Record;
use XML::Simple;
use Modern::Perl;
use Data::Dumper; # FIXME Debug
use base qw(Exporter);

our @EXPORT_OK = qw(
    SendLookupAgency
    SendRequestItem
    send_ItemRequested
    SendItemShipped
    SendItemShippedAsHome
    SendItemReceived
    SendItemReceivedAsOwner
    SendRenewItem
    SendCancelRequestItem
    SendCancelRequestItemAsOwner

    GetILLPartners
    quickfix_requestbib
    quickfix_set_ordered_from
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
                    <ns1:AgencyId>NO-" . $args->{'to_agency'} . "</ns1:AgencyId>
                </ns1:ToAgencyId>
            </ns1:InitiationHeader>
            <!-- State which Agency you are asking information about, normaly equal to ToAgency. -->
            <ns1:AgencyId>NO-" . $args->{'to_agency'} . "</ns1:AgencyId>
            <!-- State what information element you are asking for-->
            <!-- It is mandatory to support \"Application Profile Supported Type\" in NNCIP.  -->
            <ns1:AgencyElementType>Application Profile Supported Type</ns1:AgencyElementType>
            <!-- It is recomended to support \"Agency Address Information\" in NNCIPP. -->
            <ns1:AgencyElementType>Agency Address Information</ns1:AgencyElementType>
        </ns1:LookupAgency>
    </ns1:NCIPMessage>";

    return _send_message( 'LookupAgency', $msg, $nncip_uri );

}

=head2 SendRequestItem

Send a RequestItem to another library.

=cut

sub SendRequestItem {

    my ( $args ) = @_;

    my %types = (
        'barcode' => 'Barcode',
        'isbn'    => 'ISBN',
        'issn'    => 'ISSN',
        'ean'     => 'EAN',
        'rfid'    => 'RFID',
    );

    # Construct ItemIdentifierType and ItemIdentifierValue
    my $itemidentifiertype  = $types{ $args->{'idtype'} };
    my $itemidentifiervalue = $args->{'id'};
#    if ( $args->{'barcode'} ne '' ) {
#        $itemidentifiertype  .= 'Barcode';
#        $itemidentifiervalue .= $args->{'barcode'};
#    }
#    if ( $args->{'barcode'} ne '' && $args->{'rfid'} ne '' ) {
#        $itemidentifiertype  .= ';';
#        $itemidentifiervalue .= ';';
#    }
#    if ( $args->{'rfid'} ne '' ) {
#        $itemidentifiertype  .= 'RFID';
#        $itemidentifiervalue .= $args->{'rfid'};
#    }

    my $msg = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
    <ns1:NCIPMessage xmlns:ns1=\"http://www.niso.org/2008/ncip\" ns1:version=\"http://www.niso.org/schemas/ncip/v2_02/ncip_v2_02.xsd\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.niso.org/2008/ncip http://www.niso.org/schemas/ncip/v2_02/ncip_v2_02.xsd\">
        <!-- Usage in NNCIPP 1.0 is in use-case 2: A user request a spesific uniqe item, from a external library.  -->
        <ns1:RequestItem>
            <!-- The InitiationHeader, stating from- and to-agency, is mandatory. -->
            <ns1:InitiationHeader>
                <!-- Home Library -->
                <ns1:FromAgencyId>
                    <ns1:AgencyId>NO-" . C4::Context->preference('ILLISIL') . "</ns1:AgencyId>
                </ns1:FromAgencyId>
                <!-- Owner Library -->
                <ns1:ToAgencyId>
                    <ns1:AgencyId>NO-" . $args->{'to_agency'} . "</ns1:AgencyId>
                </ns1:ToAgencyId>
            </ns1:InitiationHeader>
            <!-- The UserId must be a NLR-Id (National Patron Register) -->
            <ns1:UserId>
                <ns1:UserIdentifierValue>" . $args->{'userid'} . "</ns1:UserIdentifierValue>
            </ns1:UserId>";
    if ( $itemidentifiertype eq 'Barcode' ) {
            # Barcode or FIXME RFID
            $msg .= "<!-- The ItemId must uniquely identify the requested Item in the scope of the ToAgencyId -->
                    <ns1:ItemId>
                        <!-- All Items must have a scannable Id either a RFID or a Barcode or Both. -->
                        <!-- In the case of both, start with the Barcode, use colon and no spaces as delimitor.-->
                        <ns1:ItemIdentifierType>" . $itemidentifiertype . "</ns1:ItemIdentifierType>
                        <ns1:ItemIdentifierValue>" . $itemidentifiervalue . "</ns1:ItemIdentifierValue>
                    </ns1:ItemId>";
    } else {
            # ISBN, ISSN, EAN eller FIXME OwnerLocalRecordID
            $msg .= "<ns1:BibliographicId>
                        <ns1:BibliographicRecordId>
                            <ns1:BibliographicRecordIdentifier>" . $itemidentifiervalue . "</ns1:BibliographicRecordIdentifier>
                            <!-- Supported BibliographicRecordIdentifierCode is OwnerLocalRecordID, ISBN, ISSN and EAN -->
                            <!-- Supported values of OwnerLocalRecordID is simplyfied to 'LocalId' - each system know it's own values. -->
                            <ns1:BibliographicRecordIdentifierCode>" . $itemidentifiertype . "</ns1:BibliographicRecordIdentifierCode>
                        </ns1:BibliographicRecordId>
                    </ns1:BibliographicId>";
    }
    $msg .= "<!-- The RequestId must be created by the initializing AgencyId and it has to be globaly uniqe -->
            <ns1:RequestId>
                <!-- The initializing AgencyId must be part of the RequestId -->
                <ns1:AgencyId>NO-" . C4::Context->preference('ILLISIL') . "</ns1:AgencyId>
                <!-- The RequestIdentifierValue must be part of the RequestId-->
                <ns1:RequestIdentifierValue>" . $args->{'requestid'} . "</ns1:RequestIdentifierValue>
            </ns1:RequestId>
            <!-- The RequestType must be one of the following: -->
            <!-- Physical, a loan (of a physical item, create a reservation if not available) -->
            <!-- Non-Returnable, a copy of a physical item - that is not required to return -->
            <!-- PhysicalNoReservation, a loan (of a physical item), do NOT create a reservation if not available -->
            <!-- LII, a patron initialized physical loan request, threat as a physical loan request -->
            <!-- LIINoReservation, a patron initialized physical loan request, do NOT create a reservation if not available -->
            <!-- Depot, a border case; some librarys get a box of (foreign language) books from the national library -->
            <!-- If your library dont recive 'Depot'-books; just respond with a \"Unknown Value From Known Scheme\"-ProblemType -->
            <ns1:RequestType>" . $args->{'reqtype'} . "</ns1:RequestType>
            <!-- RequestScopeType is mandatory and must be \"Title\", signaling that the request is on title-level -->
            <!-- (and not Item-level - even though the request was on a Id that uniquely identify the requested Item) -->
            <ns1:RequestScopeType>Title</ns1:RequestScopeType>
            <!-- Include ItemOptionalFields.BibliographicDescription if you wish to recive Bibliographic data in the response -->
            <ns1:ItemOptionalFields>
                <ns1:BibliographicDescription/>
            </ns1:ItemOptionalFields>
        </ns1:RequestItem>
    </ns1:NCIPMessage>";

    return _send_message( 'RequestItem', $msg, $args->{'nncip_uri'} );

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
    my $lang_code = _get_langcode_from_bibliodata( $bibliodata );

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

    return _send_message( 'ItemRequested', $msg, $nncip_uri );

}

=head2 SendItemShipped

Send an ItemShipped message to another library as the Owner Library

See also SendItemShippedAsHome.

=cut

sub SendItemShipped {

    my ( $args ) = @_;

    my $request = $args->{'request'};
    my $borrower = $request->status->getProperty('borrower');

    my $dt = DateTime->now;
    $dt->set_time_zone( 'Europe/Oslo' );

    my $tmplbase = 'ill/nncipp/ItemShipped.xml';
    my $language = 'en'; # _get_template_language($query->cookie('KohaOpacLanguage'));
    my $path     = C4::Context->config('intrahtdocs'). "/prog/". $language;
    my $filename = "$path/modules/" . $tmplbase;
    my $template = C4::Templates->new( 'intranet', $filename, $tmplbase );

    my ( $remote_id_agency, $remote_id_id ) = split /:/, $request->status->getProperty('remote_id');

    $template->param(
        'FromAgency'        => C4::Context->preference('ILLISIL'),
        'RequestIdentifier' => $remote_id_id,
        'ItemIdentifier'    => $args->{'barcode'},
        'DateShipped'       => $dt->iso8601(),
        'borrower'          => $borrower,
        'remote_user'       => $request->status->getProperty('remote_user'),
    );
    my $msg = $template->output();

    my $nncip_uri = GetBorrowerAttributeValue( $borrower->borrowernumber, 'nncip_uri' );
    return _send_message( 'ItemShipped', $msg, $nncip_uri );

}

=head2 SendItemShippedAsHome

Send an ItemShipped message from the Home Library to the Owner Library

See also SendItemShipped.

=cut

sub SendItemShippedAsHome {

    my ( $args ) = @_;

    my $request = $args->{'request'};
    my $remote_library_id = $request->status->getProperty('ordered_from');
    my $remote_library = GetMemberDetails( $remote_library_id );

    my $borrower_id = $request->status->getProperty('borrowernumber');
    my $borrower    = GetMemberDetails( $borrower_id );

    my $dt = DateTime->now;
    $dt->set_time_zone( 'Europe/Oslo' );

    my $tmplbase = 'ill/nncipp/ItemShippedAsHome.xml';
    my $language = 'en'; # _get_template_language($query->cookie('KohaOpacLanguage'));
    my $path     = C4::Context->config('intrahtdocs'). "/prog/". $language;
    my $filename = "$path/modules/" . $tmplbase;
    my $template = C4::Templates->new( 'intranet', $filename, $tmplbase );

    my ( $remote_id_agency, $remote_id_id ) = split /:/, $request->status->getProperty('remote_id');

    $template->param(
        'FromAgency'        => C4::Context->preference('ILLISIL'),
        'RequestIdentifier' => $remote_id_id,
        'ItemIdentifier'    => $args->{'barcode'},
        'DateShipped'       => $dt->iso8601(),
        'borrower'          => $remote_library,
        'UserId'            => $borrower->{'cardnumber'},
    );
    my $msg = $template->output();

    my $nncip_uri = GetBorrowerAttributeValue( $remote_library_id, 'nncip_uri' );
    return _send_message( 'ItemShipped', $msg, $nncip_uri );

}

=head2 SendItemReceived

Send an ItemReceived message to a library that has sent us an item

=cut

sub SendItemReceived {

    my ( $args ) = @_;

    my $request = $args->{'request'};
    my $remote_library_id = $request->status->getProperty('ordered_from');
    my $remote_library = GetMemberDetails( $remote_library_id );

    my $dt = DateTime->now;
    $dt->set_time_zone( 'Europe/Oslo' );

    my $tmplbase = 'ill/nncipp/ItemReceived.xml';
    my $language = 'en'; # _get_template_language($query->cookie('KohaOpacLanguage'));
    my $path     = C4::Context->config('intrahtdocs'). "/prog/". $language;
    my $filename = "$path/modules/" . $tmplbase;
    my $template = C4::Templates->new( 'intranet', $filename, $tmplbase );

    $template->param(
        'FromAgency'        => C4::Context->preference('ILLISIL'),
        'ToAgency'          => $remote_library->{'cardnumber'},
        'ItemIdentifier'    => $args->{'barcode'},
        'DateReceived'      => $dt->iso8601(),
        'RequestIdentifierValue' => $request->{status}->{id},
        'barcode'           => $args->{'barcode'},
    );
    my $msg = $template->output();

    my $nncip_uri = GetBorrowerAttributeValue( $remote_library_id, 'nncip_uri' );
    return _send_message( 'ItemReceived', $msg, $nncip_uri );

}

=head2 SendItemReceivedAsOwner

Send an ItemReceived message to a library that has returned one of our items to us

=cut

sub SendItemReceivedAsOwner {

    my ( $args ) = @_;

    my $request = $args->{'request'};
    my $remote_library_id = $request->status->getProperty('borrowernumber');
    warn "remote_library_id: $remote_library_id";
    my $remote_library = GetMemberDetails( $remote_library_id );

    my ( $remote_id_agency, $remote_id_id ) = split /:/, $request->status->getProperty('remote_id');

    my $dt = DateTime->now;
    $dt->set_time_zone( 'Europe/Oslo' );

    my $tmplbase = 'ill/nncipp/ItemReceivedAsOwner.xml';
    my $language = 'en'; # _get_template_language($query->cookie('KohaOpacLanguage'));
    my $path     = C4::Context->config('intrahtdocs'). "/prog/". $language;
    my $filename = "$path/modules/" . $tmplbase;
    my $template = C4::Templates->new( 'intranet', $filename, $tmplbase );

    $template->param(
        'FromAgency'        => C4::Context->preference('ILLISIL'),
        'ToAgency'          => $remote_library->{'cardnumber'},
        'ItemIdentifier'    => $args->{'barcode'},
        'DateReceived'      => $dt->iso8601(),
        'AgencyId'          => $remote_id_agency,
        'RequestIdentifierValue' => $remote_id_id,
        'barcode'           => $args->{'barcode'},
    );
    my $msg = $template->output();

    my $nncip_uri = GetBorrowerAttributeValue( $remote_library_id, 'nncip_uri' );
    warn "nncip_uri: $nncip_uri";
    return _send_message( 'ItemReceived', $msg, $nncip_uri );

}

=head2 SendRenewItem

Send an RenewItem message to the library that has sent us an item, informing
them that we want to renew the loan.

=cut

sub SendRenewItem {

    my ( $args ) = @_;

    my $request = $args->{'request'};
    my $remote_library_id = $request->status->getProperty('ordered_from');
    my $remote_library = GetMemberDetails( $remote_library_id );

    # Get data about the person who has the item in hand and wants it longer
    my $borrower_id = $request->status->getProperty('borrowernumber');
    my $borrower    = GetMemberDetails( $borrower_id );

    # Set up the template for the message
    my $tmplbase = 'ill/nncipp/RenewItem.xml';
    my $language = 'en'; # _get_template_language($query->cookie('KohaOpacLanguage'));
    my $path     = C4::Context->config('intrahtdocs'). "/prog/". $language;
    my $filename = "$path/modules/" . $tmplbase;
    my $template = C4::Templates->new( 'intranet', $filename, $tmplbase );
    $template->param(
        'FromAgency'        => C4::Context->preference('ILLISIL'),
        'ToAgency'          => $remote_library->{'cardnumber'},
        'UserId'            => $borrower->{'cardnumber'},
        'barcode'           => $args->{'barcode'},
    );
    my $msg = $template->output();

    my $nncip_uri = GetBorrowerAttributeValue( $remote_library_id, 'nncip_uri' );
    return _send_message( 'RenewItem', $msg, $nncip_uri );

}

=head2 SendCancelRequestItem

Send a CancelRequestItem to the library that we sent a RequestItem to, informing
them we are no longer interested in the requested item.

The home library sends this to the owner library.

=cut

sub SendCancelRequestItem{

    my ( $args ) = @_;

    # Get data about the "other" library, from which we have requested the loan
    my $request = $args->{'request'};
    my $remote_library_id = $request->status->getProperty('ordered_from');
    my $remote_library = GetMemberDetails( $remote_library_id );

    # Get data about the person for whom the initial request was made
    my $borrower_id = $request->status->getProperty('borrowernumber');
    my $borrower    = GetMemberDetails( $borrower_id );

    my ( $remote_id_agency, $remote_id_id ) = split /:/, $request->status->getProperty('remote_id');

    # Set up the template for the message
    my $tmplbase = 'ill/nncipp/CancelRequestItem.xml';
    my $language = 'en'; # _get_template_language($query->cookie('KohaOpacLanguage'));
    my $path     = C4::Context->config('intrahtdocs'). "/prog/". $language;
    my $filename = "$path/modules/" . $tmplbase;
    my $template = C4::Templates->new( 'intranet', $filename, $tmplbase );
    $template->param(
        'FromAgency'        => C4::Context->preference('ILLISIL'),
        'ToAgency'          => $remote_library->{'cardnumber'},
        'UserId'            => $borrower->{'cardnumber'},
        'AgencyId'          => $remote_id_agency,
        'RequestId'         => $remote_id_id,
        'ItemIdentifier'    => $request->status->getProperty('remote_barcode'),
        'RequestType'       => $request->status->getProperty('reqtype'),
    );
    my $msg = $template->output();

    my $nncip_uri = GetBorrowerAttributeValue( $remote_library_id, 'nncip_uri' );
    return _send_message( 'CancelRequestItem', $msg, $nncip_uri );

}

=head2 SendCancelRequestItemAsOwner

Send a CancelRequestItem to a library that we got a RequestItem from, informing
them that we can not fullfill the loan request.

The owner library sends this to the home library.

=cut

sub SendCancelRequestItemAsOwner{

    my ( $args ) = @_;

    # Get data about the "other" library, from which we got the loan request
    my $request = $args->{'request'};
    my $remote_library_id = $request->status->getProperty('borrowernumber');
    my $remote_library = GetMemberDetails( $remote_library_id );

    # Get data about the person for whom the initial request was made
    my $borrower_id = $request->status->getProperty('borrowernumber');
    my $borrower    = GetMemberDetails( $borrower_id );

    my ( $remote_id_agency, $remote_id_id );
    if ( $request->status->getProperty('remote_id') ) {
        # If the request was initiated by another library, we find the RequestId
        # value thusly:
        ( $remote_id_agency, $remote_id_id ) = split /:/, $request->status->getProperty('remote_id');
    } else {
        # If it was created by us, we use our ISIL and the ID from the
        # ill_requests db table.
        $remote_id_agency = C4::Context->preference('ILLISIL');
        $remote_id_id     = $request->status->getProperty('id');
    }

    # Set up the template for the message
    my $tmplbase = 'ill/nncipp/CancelRequestItemAsOwner.xml';
    my $language = 'en'; # _get_template_language($query->cookie('KohaOpacLanguage'));
    my $path     = C4::Context->config('intrahtdocs'). "/prog/". $language;
    my $filename = "$path/modules/" . $tmplbase;
    my $template = C4::Templates->new( 'intranet', $filename, $tmplbase );
    $template->param(
        'FromAgency'        => C4::Context->preference('ILLISIL'),
        'ToAgency'          => $remote_library->{'cardnumber'},
        'UserId'            => $borrower->{'cardnumber'},
        'AgencyId'          => $remote_id_agency,
        'RequestId'         => $remote_id_id,
        'ItemIdentifier'    => $request->status->getProperty('remote_barcode'),
        'ItemNote'          => $args->{'reject_reason'},
        'RequestType'       => $request->status->getProperty('reqtype'),
    );
    my $msg = $template->output();

    my $nncip_uri = GetBorrowerAttributeValue( $remote_library_id, 'nncip_uri' );
    return _send_message( 'CancelRequestItem', $msg, $nncip_uri );

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

=head1 QUICK AND DIRTY SUBROUTINES

Here be monsters.

=head2 quickfix_requestbib

Just fix the title and author of a placeholder IllRequest

=cut

sub quickfix_requestbib {

    my ( $args ) = @_;

    my $dbh = C4::Context->dbh();
    my $sth = $dbh->prepare("UPDATE ill_request_attributes SET value = ? WHERE req_id = ? AND type = 'm./metadata/titleLevel/title';");
    $sth->execute( $args->{title}, $args->{requestid} );
    $sth = $dbh->prepare("UPDATE ill_request_attributes SET value = ? WHERE req_id = ? AND type = 'm./metadata/titleLevel/author';");
    $sth->execute( $args->{author}, $args->{requestid} );

}

=head2 quickfix_set_ordered_from

Just set the ordered_from on an IllRequest

=cut

sub quickfix_set_ordered_from {

    my ( $args ) = @_;

    my $dbh = C4::Context->dbh();
    my $sth = $dbh->prepare("UPDATE ill_requests SET ordered_from = ? WHERE id = ?;");
    $sth->execute( $args->{illpartner}, $args->{requestid} );

}

=head1 INTERNAL SUBROUTINES

=head2 _send_message

Do the actual sending of XML messages to NCIP endpoints.

=cut

sub _send_message {

    my ( $req, $msg, $endpoint ) = @_;

    warn "talking to $endpoint";

    logaction( 'ILL', $req, undef, $msg );
    my $response = HTTP::Tiny->new->request( 'POST', $endpoint, { 'content' => $msg } );

    if ( $response->{success} ){
        # We got a 200 response from the server, but it could still contain a Problem element
        logaction( 'ILL', $req . 'Response', undef, $response->{'content'} );
        # Check if we got a Problem response
        my $problem = 0;
        if ( $response->{'content'} =~ m/ns1:Problem/g ) {
            $problem = 1;
        }
        return {
            'success' => 1,
            'problem' => $problem,
            'msg'     => $response->{'content'},
            'data'    => XMLin( $response->{'content'} ),
        };
    } else {
        my $msg = "ERROR: $response->{status} $response->{reason}";
        logaction( 'ILL', $req . 'Response', undef, $msg );
        return {
            'success' => 0,
            'msg' => $msg,
        };
    }

}

=head2 _get_langcode_from_bibliodata

Take a record and pick ut the language code in controlfield 008, position 35-37.

=cut

sub _get_langcode_from_bibliodata {

    my ( $bibliodata ) = @_;

    my $marcxml = $bibliodata->{'marcxml'};
    my $record = MARC::Record->new_from_xml( $marcxml, 'UTF-8' );
    my $f008 = $record->field( '008' )->data();
    my $lang_code = '   ';
    if ( $f008 ) {
        $lang_code = substr $f008, 35, 3;
    }
    return $lang_code;

}

=head1 AUTHOR

Magnus Enger <magnus@libriotech.no>

=cut

1;
