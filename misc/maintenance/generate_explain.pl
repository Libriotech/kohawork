#!/usr/bin/perl

# Copyright 2017 Magnus Enger Libriotech
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

=head1 NAME

generate_explain.pl

=head1 SYNOPSIS

sudo koha-shell -c "perl generate_explain.pl -v" mykoha

sudo PERL5LIB=/usr/share/koha/lib KOHA_CONF=/etc/koha/sites/kohadev/koha-conf.xml perl generate_explain.pl -c /path/to/explain.yaml --overwrite -v

=head1 DESCRIPTION

Reads an optional config file, some of Koha's config files and generates an
Explain document that can be served by the Zebra SRU server.

By default, the generated Explain document will be written to STDOUT. Specify
the --overwrite command line option to actually overwrite the existing Explain
document.

=cut

use File::Slurp;
use YAML::Syck qw( LoadFile );
use CGI qw( utf8 ); # NOT a CGI script, this is just to keep C4::Templates::gettemplate happy
use XML::Simple;
use Modern::Perl;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper; # Debug

use C4::Context;
use C4::Templates;

=head1 OPTIONS

=over 8

=item B<-c | --configfile>

Path to a configfile that should be used to generate parts of the Explain
document.

=item B<-a | --authorities>

If this option is not specified, the script will assume we are dealing with
biblios.

=item B<-o | --overwrite>

Actually overwrite the existing explain document. If this is not specified, the
generated Explain document will be written to STDOUT and no files will be
overwritten.

=item B<-h | --help>

Print this usage statement.

=item B<-v | --verbose>

More verbose output.

=back

=cut

my ( $configfile, $authorities, $overwrite, $help, $verbose );
GetOptions(
    'c|configfile=s'  => \$configfile,
    'a|authorities'   => \$authorities,
    'o|overwrite'     => \$overwrite,
    'h|help'          => \$help,
    'v|verbose'       => \$verbose,
);

if ( $help ) {
    pod2usage( -verbose => 2 );
    exit;
}

=head1 CONFIG FILE

The config file should be in YAML format. Here is an example config that shows
all the available options. See http://zeerex.z3950.org/dtd/commentary.html for
further details about the options.

    ---
    # Protocol
    # Default: SRW/SRU/Z39.50
    protocol: "SRU"

    # Transport
    # Default: http
    transport: "https"

    # Title
    # Should have a two letter language code.
    # One title can be marked as primary
    title:
        - text: This is some title
          lang: en
          primary: true
        - text: Dette er en tittel
          lang: nb

    # Description
    # Should have a two letter language code.
    # One description can be marked as primary
    description:
        - text: This is some description
          lang: en
          primary: true
        - text: Dette er en beskrivelse
          lang: nb

    # Author
    # If author is not set in the config, the LibraryName syspref will be used. If
    # that is not set, the string "Koha" will be used.
    author: "The librarian"

    # Contact
    # If the contact is not set in the config, the KohaAdminEmailAddress syspref
    # will be used.
    contact: "librarian@example.org"

    # Extent
    extent:
        - text: "This is the extent of the database."
          lang: "en"
          primary: "true"

    # History
    history:
        - text: "This is the history of the database."
          lang: "en"
          primary: "true"

    # langUsage
    langUsage:
        - text: "Records are in English and Norwegian"
          codes: "en nb"
          lang: "en"
          primary: "true"

    # Restrictions
    restrictions:
        - text: "Free for all!"
          lang: "en"
          primary: "true"

    # Subjects
    subjects:
        - "Subject A"
        - "Subject B"

    # Index names
    # Indexes can be given more explanatory names, but this is optional.
    indexnames:
        dc_title:
          - title: "Title"
            lang: "en"
          - title: "Tittel"
            lang: "nb"
        dc_subject:
          - title: "Subject"
            lang: "en"
        rec_identifier:
          - title: "Record identifier"
            lang: "en"

=cut

# Load the config file, if one is specified
my $config;
if ( $configfile ) {
    if ( -e $configfile ) {
        say "Reading config from $configfile" if $verbose;
        $config = LoadFile( $configfile );
    } else {
        die "$configfile not found";
    }
}

# Get the path to he Koha config file from the KOHA_CONF environment variable
my $koha_conf = $ENV{ 'KOHA_CONF' };
say "Looking at $koha_conf" if $verbose;

# Read the Koha config file
my $conf = XMLin(
    $koha_conf,
    keyattr => ['id'],
    forcearray => ['listen', 'server', 'serverinfo'],
    suppressempty => ''
);

# Get the SRU host and port from the Koha config file
my $publicserver = $conf->{'listen'}->{'publicserver'}->{'content'};
my ( $tcp, $host, $port ) = split /:/, $publicserver;
say "SRU is listening on host $host and port $port" if $verbose;

# Find the path to pqf.properties file
my $pqf_properties_file = $conf->{'server'}->{'publicserver'}->{'cql2rpn'};
say "Looking at $pqf_properties_file" if $verbose;

# Read the pqf.properties file, and extract the information we need
my %pqf;
my @lines = read_file( $pqf_properties_file );
foreach my $line ( @lines ) {

    # Remove trailing whitespace
    chomp $line;
    # Skip commented lines - start of line, zero or more spaces, comment sign
    next if $line =~ m/^ {0,}#/;
    # Skip empty lines - start of line, zero or more spaces, end of line
    next if $line =~ m/^ {0,}$/;

    # Look for lines that start with "set."
    if ( $line =~ m/^set\.(.*?) {0,}= {0,}(.*)/ ) {
        push @{ $pqf{'sets'} }, {
            'name' => $1,
            'identifier' => $2,
        };
    }

    # Look for lines that start with "index."
    if ( $line =~ m/^index\.(.*?)\.(.*?) {0,}= (.*?)=(.*?) {0,}$/ ) {
        push @{ $pqf{'indexes'} }, {
            'set'   => $1,
            'index' => $2,
            'id'    => "$1_$2",
            'type'  => $3,
            'value' => $4,
        };
    }

    # Look for lines that start with "relation."
    if ( $line =~ m/^relation\.(.*?) {0,}=.*$/ ) {
        push @{ $pqf{'relations'} }, {
            'rel' => $1,
        };
    }

    # Look for lines that start with "relationModifier."
    if ( $line =~ m/^relationModifier\.(.*?) {0,}=.*$/ ) {
        push @{ $pqf{'relationmodifiers'} }, {
            'relmod' => $1,
        };
    }

}

# Set up the template
my $template = C4::Templates::gettemplate(
    'services/explain.tt',
    'intranet',
    new CGI
);

# Pass some values to the template
$template->param(
    'config'      => $config,
    'pqf'         => \%pqf,
    'host'        => $host,
    'port'        => $port,
    'authorities' => $authorities,
);

# Get the output from the template
my $output = $template->output;
if ( $overwrite ) {
    # Find the path to the Explain doc
    my $explain_doc;
    foreach my $inc ( @{ $conf->{'server'}->{'publicserver'}->{'xi:include'} } ) {
        my $href = $inc->{'href'};
        if ( $href =~ m/explain/ ) {
            $explain_doc = $href;
        }
    }
    say "Going to write to $explain_doc" if $verbose;
    # Make a backup of the existing file
    rename $explain_doc, "$explain_doc-old";
    # Do the actual write
    write_file( $explain_doc, $output );
} else {
    say $output;
}

=head1 AUTHOR

Magnus Enger, <magnus [at] libriotech.no>

=head1 LICENSE

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
