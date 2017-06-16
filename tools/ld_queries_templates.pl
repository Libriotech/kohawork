#!/usr/bin/perl

# This file is part of Koha.
#
# Copyright (C) 2017 Magnus Enger
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

use Modern::Perl;
use CGI qw( -utf8 );
use JSON;

use C4::Auth;
use C4::Output;

use Koha::LdMainTemplates;

my $input  = CGI::->new;
my $op     = $input->param('op');

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {   template_name   => "tools/ld_queries_templates.tt",
        query           => $input,
        type            => "intranet",
        authnotrequired => 0,
        # FIXME flagsrequired   => { tools => 'upload_general_files' },
    }
);

my $main_templates = Koha::LdMainTemplates->search();

$template->param(
    'main_templates' => $main_templates,
);
output_html_with_http_headers $input, $cookie, $template->output;
