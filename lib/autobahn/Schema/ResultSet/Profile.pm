package autobahn::Schema::ResultSet::Profile;

use parent qw( DBIx::Class::ResultSet );

sub get_profile_map {
	my ($self) = @_;
	return [ map { $_->get_profile_hash } $self->all ];
}

1;
