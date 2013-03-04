use utf8;
package autobahn::Schema::Result::Project;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

autobahn::Schema::Result::Project

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<project>

=cut

__PACKAGE__->table("project");

=head1 ACCESSORS

=head2 projectid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 projectuid

  data_type: 'text'
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 0

=head2 githubrepo

  data_type: 'text'
  is_nullable: 0

=head2 creator

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 createtime

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "projectid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "projectuid",
  { data_type => "text", is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 0 },
  "githubrepo",
  { data_type => "text", is_nullable => 0 },
  "creator",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "createtime",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</projectid>

=back

=cut

__PACKAGE__->set_primary_key("projectid");

=head1 UNIQUE CONSTRAINTS

=head2 C<projectuid_unique>

=over 4

=item * L</projectuid>

=back

=cut

__PACKAGE__->add_unique_constraint("projectuid_unique", ["projectuid"]);

=head1 RELATIONS

=head2 creator

Type: belongs_to

Related object: L<autobahn::Schema::Result::Profile>

=cut

__PACKAGE__->belongs_to(
  "creator",
  "autobahn::Schema::Result::Profile",
  { userid => "creator" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 projectskills

Type: has_many

Related object: L<autobahn::Schema::Result::Projectskill>

=cut

__PACKAGE__->has_many(
  "projectskills",
  "autobahn::Schema::Result::Projectskill",
  { "foreign.projectid" => "self.projectid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 userprojectinterests

Type: has_many

Related object: L<autobahn::Schema::Result::Userprojectinterest>

=cut

__PACKAGE__->has_many(
  "userprojectinterests",
  "autobahn::Schema::Result::Userprojectinterest",
  { "foreign.projectid" => "self.projectid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 skillids

Type: many_to_many

Composing rels: L</projectskills> -> skillid

=cut

__PACKAGE__->many_to_many("skillids", "projectskills", "skillid");

=head2 userids

Type: many_to_many

Composing rels: L</userprojectinterests> -> userid

=cut

__PACKAGE__->many_to_many("userids", "userprojectinterests", "userid");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-02-28 00:42:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KoOE5jNXmzZf3ebBUzlHLg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
