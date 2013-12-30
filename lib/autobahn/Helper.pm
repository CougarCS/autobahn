package autobahn::Helper;

use Dancer ':syntax';
use Dancer::Plugin::DBIC qw(schema resultset rset);
use HTML::Entities;

# Profile {{{
use autobahn::Schema::Result::Profile;

sub autobahn::Schema::Result::Profile::get_avatar {
	my ($self) = @_;
	# TODO default avatar?
	return schema->resultset('Useravatar')
		->find({ userid => $self->userid })->avatarurl || 'test';
}

sub autobahn::Schema::Result::Profile::get_profile_url {
	my ($self) = @_;
	return uri_for('/profile/').encode_entities($self->name);
}

sub autobahn::Schema::Result::Profile::get_github_url {
	my ($self) = @_;
	return 'http://github.com/'.encode_entities($self->name);
}
#}}}


# vim: fdm=marker
true;
