use utf8;
package autobahn::Schema::Result::Skill;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

autobahn::Schema::Result::Skill

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<skill>

=cut

__PACKAGE__->table("skill");

=head1 ACCESSORS

=head2 skillid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "skillid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</skillid>

=back

=cut

__PACKAGE__->set_primary_key("skillid");

=head1 RELATIONS

=head2 projectskills

Type: has_many

Related object: L<autobahn::Schema::Result::Projectskill>

=cut

__PACKAGE__->has_many(
  "projectskills",
  "autobahn::Schema::Result::Projectskill",
  { "foreign.skillid" => "self.skillid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 userskills

Type: has_many

Related object: L<autobahn::Schema::Result::Userskill>

=cut

__PACKAGE__->has_many(
  "userskills",
  "autobahn::Schema::Result::Userskill",
  { "foreign.skillid" => "self.skillid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 projectids

Type: many_to_many

Composing rels: L</projectskills> -> projectid

=cut

__PACKAGE__->many_to_many("projectids", "projectskills", "projectid");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-02-27 22:43:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZlZMh/PvjWjDq5o47vevQA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
