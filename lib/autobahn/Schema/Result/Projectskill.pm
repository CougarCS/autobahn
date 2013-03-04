use utf8;
package autobahn::Schema::Result::Projectskill;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

autobahn::Schema::Result::Projectskill

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<projectskill>

=cut

__PACKAGE__->table("projectskill");

=head1 ACCESSORS

=head2 projectid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 skillid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "projectid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "skillid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</projectid>

=item * L</skillid>

=back

=cut

__PACKAGE__->set_primary_key("projectid", "skillid");

=head1 RELATIONS

=head2 projectid

Type: belongs_to

Related object: L<autobahn::Schema::Result::Project>

=cut

__PACKAGE__->belongs_to(
  "projectid",
  "autobahn::Schema::Result::Project",
  { projectid => "projectid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 skillid

Type: belongs_to

Related object: L<autobahn::Schema::Result::Skill>

=cut

__PACKAGE__->belongs_to(
  "skillid",
  "autobahn::Schema::Result::Skill",
  { skillid => "skillid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-02-27 22:43:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uoJhCb2ZmBwebprQtFvDBg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
