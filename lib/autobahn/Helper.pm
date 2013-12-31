package autobahn::Helper;

use parent qw( Exporter );
@EXPORT = qw(
USERSKILLSTATE_HAVE USERSKILLSTATE_WANT

get_all_skills_wanted get_all_skills_have get_all_project_skills_have
get_skill_by_name

get_all_projects


get_projectid_by_uid get_profile_by_username get_project_by_uid
);
use Dancer ':syntax';
use Dancer::Plugin::DBIC qw(schema resultset rset);
use HTML::Entities;

use constant USERSKILLSTATE_HAVE => 1;
use constant USERSKILLSTATE_WANT => 2;

#### Search helpers
# Profile {{{
sub get_profile_by_username {
	my ($username) = @_;
	schema->resultset('Profile')
		->find({ name => $username });
}
#}}}
# Skills {{{
sub get_all_skills_wanted {
	schema->resultset('Userskill')->search({ skillstate => USERSKILLSTATE_WANT },
		{ prefetch => 'skillid', group_by => [qw/me.skillid/], order_by => 'skillid.name'  });
}
sub get_all_skills_have {
	schema->resultset('Userskill')->search({ skillstate => USERSKILLSTATE_HAVE },
		{ prefetch => 'skillid', group_by => [qw/me.skillid/], order_by => 'skillid.name' });
}
sub get_all_project_skills_have {
	schema->resultset('Projectskill')->search({},
		{ prefetch => 'skillid', group_by => [qw/me.skillid/], order_by => 'skillid.name'  });
}
sub get_skill_by_name {
	my ($skillname, $create) = @_;
	my $skill = schema->resultset('Skill')->find({ name => $skillname });
	return $skill if($skill);
	return schema->resultset('Skill')->create({ name => $skillname, description => '' }) if $create;
	undef;
}
#}}}
# Project {{{
sub get_all_projects {
	schema->resultset('Project')
		->search({}, { order_by => 'title' })
}
sub get_projectid_by_uid {
	my ($uid) = @_;
	my $project = get_project_by_uid($uid);
	if($project) {
		return $project->projectid;
	}
	return undef;
}
sub get_project_by_uid {
	my ($uid) = @_;
	schema->resultset('Project')
		->find({ projectuid => $uid });
}
#}}}

#### Result class helpers
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

sub autobahn::Schema::Result::Project::get_project_with_skills_hash {
	my ($self) = @_;
	my $data = $self->get_project_hash;
	my $projectskills_rs = schema->resultset('Projectskill')
		->search({ projectid => $self->projectid });
	$data->{skills} = $projectskills_rs->related_resultset('skillid')->get_skill_map;
	$data;
}

sub autobahn::Schema::Result::Project::get_project_hash {
	my ($self) = @_;
	+{ name => $self->title, url => $self->get_project_url, description => $self->description };
}

sub autobahn::Schema::Result::Project::get_project_url {
	my ($self) = @_;
	uri_for('/project/').encode_entities($self->projectuid);
}
#}}}

# vim: fdm=marker
true;
