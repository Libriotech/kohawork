use utf8;
package Koha::Schema::Result::LdMainTemplate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Koha::Schema::Result::LdMainTemplate

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<ld_main_template>

=cut

__PACKAGE__->table("ld_main_template");

=head1 ACCESSORS

=head2 ld_main_template_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 type_uri

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 main_template

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "ld_main_template_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "type_uri",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "main_template",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</ld_main_template_id>

=back

=cut

__PACKAGE__->set_primary_key("ld_main_template_id");

=head1 RELATIONS

=head2 ld_queries_templates

Type: has_many

Related object: L<Koha::Schema::Result::LdQueriesTemplate>

=cut

__PACKAGE__->has_many(
  "ld_queries_templates",
  "Koha::Schema::Result::LdQueriesTemplate",
  { "foreign.ld_main_template_id" => "self.ld_main_template_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-05-30 12:03:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VfCyn9rYAeznkoFHuQurEA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
