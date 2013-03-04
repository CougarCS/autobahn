use utf8;
package autobahn::Schema::Result::Userlogin;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

autobahn::Schema::Result::Userlogin

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<userlogin>

=cut

__PACKAGE__->table("userlogin");

=head1 ACCESSORS

=head2 userid

  data_type: 'integer'
  is_auto_increment: 1
  is_foreign_key: 1
  is_nullable: 0

=head2 githubuser

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "userid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_foreign_key    => 1,
    is_nullable       => 0,
  },
  "githubuser",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</userid>

=back

=cut

__PACKAGE__->set_primary_key("userid");

=head1 RELATIONS

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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Q1hBnqH8mYCiZShm7s/onQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
