package autobahn::Helper;

use parent qw( Exporter );
@EXPORT = qw(
USERSKILLSTATE_HAVE USERSKILLSTATE_WANT
);
use Dancer ':syntax';
use Dancer::Plugin::DBIC qw(schema resultset rset);
use HTML::Entities;

use constant USERSKILLSTATE_HAVE => 1;
use constant USERSKILLSTATE_WANT => 2;

# Profile {{{
use autobahn::Schema::Result::Profile;

sub autobahn::Schema::Result::Profile::get_profile_hash {
	my ($self) = @_;
	+{ name => $self->fullname,
		url => $self->get_profile_url,
		nick => $self->name,
		avatarurl => $self->get_avatar };
}

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
# Skill {{{
use autobahn::Schema::Result::Skill;

sub autobahn::Schema::Result::Skill::get_skill_hash {
	my ($self) = @_;
	+{ name => $self->name, url =>  $self->get_skill_url };
}

sub autobahn::Schema::Result::Skill::get_skill_url {
	my ($self) = @_;
	uri_for("/skill/").encode_entities($self->name);
}
#}}}
# Project {{{
use autobahn::Schema::Result::Project;

sub autobahn::Schema::Result::Project::get_project_hash {
	my ($self) = @_;
	+{ name => $self->title, url => $self->get_project_url };
}

sub autobahn::Schema::Result::Project::get_project_url {
	my ($self) = @_;
	uri_for('/project/').encode_entities($self->projectuid);
}
#}}}

# vim: fdm=marker
true;
