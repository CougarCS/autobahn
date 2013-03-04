use utf8;
package autobahn::Schema::Result::Userskill;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

autobahn::Schema::Result::Userskill

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<userskill>

=cut

__PACKAGE__->table("userskill");

=head1 ACCESSORS

=head2 userid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 skillid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 skillstate

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "userid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "skillid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "skillstate",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</userid>

=item * L</skillid>

=back

=cut

__PACKAGE__->set_primary_key("userid", "skillid");

=head1 RELATIONS

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

=head2 userid

Type: belongs_to

Related object: L<autobahn::Schema::Result::Profile>

=cut

__PACKAGE__->belongs_to(
  "userid",
  "autobahn::Schema::Result::Profile",
  { userid => "userid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-02-28 00:42:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ACzWQUizMQDYf+KF5s/CEw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
