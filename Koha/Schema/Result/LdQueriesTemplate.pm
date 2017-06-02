use utf8;
package Koha::Schema::Result::LdQueriesTemplate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Koha::Schema::Result::LdQueriesTemplate

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<ld_queries_templates>

=cut

__PACKAGE__->table("ld_queries_templates");

=head1 ACCESSORS

=head2 ld_queries_templates_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 slug

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 ld_main_template_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 query

  data_type: 'text'
  is_nullable: 0

=head2 template

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "ld_queries_templates_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "slug",
  { data_type => "char", is_nullable => 0, size => 32 },
  "ld_main_template_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "query",
  { data_type => "text", is_nullable => 0 },
  "template",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</ld_queries_templates_id>

=back

=cut

__PACKAGE__->set_primary_key("ld_queries_templates_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<slug>

=over 4

=item * L</slug>

=back

=cut

__PACKAGE__->add_unique_constraint("slug", ["slug"]);

=head1 RELATIONS

=head2 ld_main_template

Type: belongs_to

Related object: L<Koha::Schema::Result::LdMainTemplate>

=cut

__PACKAGE__->belongs_to(
  "ld_main_template",
  "Koha::Schema::Result::LdMainTemplate",
  { ld_main_template_id => "ld_main_template_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-05-30 12:03:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:D/ER1VlW3L4oGcy6ElVCKQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
