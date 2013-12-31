package autobahn::Schema::ResultSet::Project;

use parent qw( DBIx::Class::ResultSet );

sub get_project_with_skills_map {
	my ($self) = @_;
	return [ map { $_->get_project_with_skills_hash } $self->all ];
}

sub get_project_map {
	my ($self) = @_;
	return [ map { $_->get_project_hash } $self->all ];
}

1;
