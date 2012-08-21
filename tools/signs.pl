#!/usr/bin/perl
#
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
#
#
#

=head1 NAME

signs.pl - Script for managing digital signs for the OPAC.

=head1 SYNOPSIS

signs.pl

=head1 DESCRIPTION

Allows authorized users to create and manage digital signs for the OPAC.

=cut

use strict;
use warnings;

use CGI;
use C4::Context;
use C4::Auth;
use C4::Output;
use C4::Log;

my $debug = 1;

my $input = new CGI;

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => "tools/signs.tt",
        query           => $input,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { tools => 'edit_digital_signs' },
        debug           => 0,
    }
);

# TODO

output_html_with_http_headers $input, $cookie, $template->output;

exit 0;

=head1 AUTHORS

Written by Magnus Enger of Libriotech.

=cut
