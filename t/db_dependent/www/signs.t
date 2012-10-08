#!/usr/bin/perl

# Copyright 2012 Magnus Enger Libriotech
#
# This is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# Koha; if not, write to the Free Software Foundation, Inc., 59 Temple Place,
# Suite 330, Boston, MA  02111-1307 USA
#

use Modern::Perl;
use Test::More qw(no_plan); # TODO Set the number
use Test::WWW::Mechanize;
use Data::Dumper;

use C4::Context;

my $user     = $ENV{KOHA_USER};
my $password = $ENV{KOHA_PASS};
my $intranet = $ENV{KOHA_INTRANET_URL};
my $opac     = $ENV{KOHA_OPAC_URL};

my $stream_name = 'some dummy stream name';

BAIL_OUT("You must set the environment variable KOHA_INTRANET_URL to ".
         "point this test to your staff client. If you do not have ".
         "KOHA_CONF set, you must also set KOHA_USER and KOHA_PASS for ".
         "your username and password") unless $intranet;

$intranet =~ s#/$##;
$opac     =~ s#/$##;

my $agent = Test::WWW::Mechanize->new( autocheck => 1 );

# Log in to the Koha staff client
$agent->get_ok( "$intranet/cgi-bin/koha/mainpage.pl", 'connect to intranet' );
$agent->form_name('loginform');
$agent->field( 'password', $password );
$agent->field( 'userid',   $user );
$agent->field( 'branch',   '' );
$agent->click_ok( '', 'login to staff client' );
$agent->get_ok( "$intranet/cgi-bin/koha/mainpage.pl", 'load main page' );

# Go to the tools page
$agent->follow_link_ok( { url_regex => qr/tools-home/i }, 'open Tools page' );

# Digital signs
$agent->follow_link_ok( { text => 'Digital signs' }, 'go to Digital signs' );
$agent->title_like(   qr/Digital signs/, 'title contains Digital signs' );
$agent->content_like( qr/Digital signs/, 'content contains Digital signs' );
$agent->content_like( qr/New sign/,      'content contains New sign' );
$agent->content_like( qr/New stream/,    'content contains New stream' );

# Add stream
$agent->follow_link_ok( { url_regex => qr/op=add_stream/i }, 'open Add stream page' );
$agent->content_like( qr/Add stream/, 'content contains Add stream' );
$agent->content_like( qr/Report/,     'content contains Report' );

# my @report_selects = $agent->grep_selects({
#   # type => qr/option/,
#   id   => qr/^report$/,
# });
# diag( Dumper @report_selects );

$agent->submit_form_ok({
  form_id => 'streamform',
  fields  => {
    'op'     => 'save_stream',
    'name'   => $stream_name,
    'report' => 1, # FIXME Make this dynamic
  }
}, 'add a new stream' );
$agent->content_like( qr/$stream_name/, 'content contains new stream name' );

# Stream detail page
$agent->follow_link_ok( { text => $stream_name, n => 1 }, 'detail page for stream' );
$agent->content_like( qr/$stream_name/, 'detail page contains stream name' );
$agent->content_like( qr/Based on report/, 'detail page contains Based on report' );
