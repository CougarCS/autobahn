package autobahn::Schema::ResultSet::Skill;

use parent qw( DBIx::Class::ResultSet );

sub get_skill_map {
	my ($self) = @_;
	return [ map { $_->get_skill_hash } $self->all ];
}

1;
