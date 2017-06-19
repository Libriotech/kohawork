#!/usr/bin/perl
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
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#

use Modern::Perl;

use File::Basename qw/basename/;
use Koha::Database;
use t::lib::TestBuilder;

use Test::More;

use_ok('Koha::LdQueriesTemplate');
use_ok('Koha::LdQueriesTemplates');

my $schema = Koha::Database->new->schema;
$schema->storage->txn_begin;

my $builder = t::lib::TestBuilder->new;

my $LdQueriesTemplate = $builder->build({
    source => 'LdQueriesTemplate',
    value => {
        slug => 'test',
        ld_main_template_id => 1,
        name => 'Test',
        query => "SELECT ?p",
        template => "{{test}}",
    }
});

my $qt = Koha::LdQueriesTemplate->new;

my $QTobject = $qt->find($LdQueriesTemplate->{ld_queries_templates_id});
isa_ok($QTobject, "Koha::LdQueriesTemplate");

$schema->storage->txn_rollback;
done_testing();
__END__

# Test delete works correctly.
my $illRequestDelete = $builder->build({
    source => 'Illrequest',
    value => {
        borrowernumber  => $patron->{borrowernumber},
        branch          => $branch->{branchcode},
        biblionumber    => 0,
        status          => 'NEW',
        completion_date => 0,
        reqtype         => 'book',
    }
});
sub ill_req_search {
    return Koha::Illrequestattributes->search({
        illrequest_id => $illRequestDelete->{illrequest_id}
    })->count;
}

is(ill_req_search, 0, "Correctly not found matching Illrequestattributes.");
# XXX: For some reason test builder can't build Illrequestattributes.
my $illReqAttr = Koha::Illrequestattribute->new({
    illrequest_id => $illRequestDelete->{illrequest_id},
    type => "test",
    value => "Hello World"
})->store;
is(ill_req_search, 1, "We have found a matching Illrequestattribute.");

Koha::Illrequests->find($illRequestDelete->{illrequest_id})->delete;
is(
