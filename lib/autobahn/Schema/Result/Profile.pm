use utf8;
package autobahn::Schema::Result::Profile;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

autobahn::Schema::Result::Profile

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<profile>

=cut

__PACKAGE__->table("profile");

=head1 ACCESSORS

=head2 userid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 fullname

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 0

=head2 jointime

  data_type: 'integer'
  is_nullable: 0

=head2 lastloggedin

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "userid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "fullname",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 0 },
  "jointime",
  { data_type => "integer", is_nullable => 0 },
  "lastloggedin",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</userid>

=back

=cut

__PACKAGE__->set_primary_key("userid");

=head1 RELATIONS

=head2 projects

Type: has_many

Related object: L<autobahn::Schema::Result::Project>

=cut

__PACKAGE__->has_many(
  "projects",
  "autobahn::Schema::Result::Project",
  { "foreign.creator" => "self.userid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 useravatar

Type: might_have

Related object: L<autobahn::Schema::Result::Useravatar>

=cut

__PACKAGE__->might_have(
  "useravatar",
  "autobahn::Schema::Result::Useravatar",
  { "foreign.userid" => "self.userid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 userlogin

Type: might_have

Related object: L<autobahn::Schema::Result::Userlogin>

=cut

__PACKAGE__->might_have(
  "userlogin",
  "autobahn::Schema::Result::Userlogin",
  { "foreign.userid" => "self.userid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 userprojectinterests

Type: has_many

Related object: L<autobahn::Schema::Result::Userprojectinterest>

=cut

__PACKAGE__->has_many(
  "userprojectinterests",
  "autobahn::Schema::Result::Userprojectinterest",
  { "foreign.userid" => "self.userid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 userskills

Type: has_many

Related object: L<autobahn::Schema::Result::Userskill>

=cut

__PACKAGE__->has_many(
  "userskills",
  "autobahn::Schema::Result::Userskill",
  { "foreign.userid" => "self.userid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 projectids

Type: many_to_many

Composing rels: L</userprojectinterests> -> projectid

=cut

__PACKAGE__->many_to_many("projectids", "userprojectinterests", "projectid");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-03-03 15:39:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:A/b2xvHAkdLb15RmM3phmA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
