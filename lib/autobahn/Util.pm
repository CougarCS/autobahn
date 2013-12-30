package autobahn::Util;

use parent qw( Exporter );
@EXPORT = qw(
USERSKILLSTATE_HAVE USERSKILLSTATE_WANT

    check_account
    edit_profile_skills
    get_profile_skills
    get_all_skills
    edit_project_skills
    get_project_skills
    get_projectid_by_uid
    get_project_by_uid
    check_project
    create_project
    edit_project
    get_profile_by_username
    get_skill_by_name
    set_flash
    get_flash
    uuid_str
    check_logged_in
    get_logged_in_userid
    get_logged_in_username
    formfill_template
    skill_map
    profile_map
    project_map
    profile_to_form
    skills_to_form
    project_to_form
    clean_skills_formdata
    validate_skill_data
    validate_description
    validate_project_title
    validate_github_repo
    validate_project_form
    validate_profile_form
    is_printable


);

use Dancer ':syntax';
use Dancer::Plugin::Auth::Github;
use Dancer::Plugin::DBIC qw(schema resultset rset);
use Data::UUID;
use HTML::FillInForm;
use URI::Encode qw(uri_encode uri_decode);
use HTML::Entities;
use List::AllUtils qw/first/;
#use Text::Markdown 'markdown';
#use HTML::Restrict;

use autobahn::Helper;

use constant USERSKILLSTATE_HAVE => 1;
use constant USERSKILLSTATE_WANT => 2;

our $uuid_gen = Data::UUID->new;

# Database actions {{{
# Create/update account on login {{{
# create account if doesn't exist
# update account otherwise
#
# Table actions:
# Profile (create/update)
# Useravatar (create/update)
# Userlogin (create)
sub check_account {
	my $login = session('github_user')->{'login'};
	my $name = session('github_user')->{'name'} || $login;
	my $avatar_url = session('github_user')->{'avatar_url'} // '';
	my $userlogin = schema->resultset('Userlogin')
		->find({ githubuser => $login });
	my $profile;
	my $userid;
	unless($userlogin) {
		# new
		$profile = schema->resultset('Profile')->new({
			name => $login, # user github profile name as profile name
			fullname => $name,
			description => '',
			jointime => time, # now
			lastloggedin => time,
		});
		$profile = $profile->insert;
		$userid = $profile->userid;
		$userlogin = schema->resultset('Userlogin')
			->new({ userid => $profile->userid, githubuser => $login });
		$userlogin->insert;
		session "new_account" => 1;
	} else {
		# update
		$userid = $userlogin->userid->userid;
		$profile = schema->resultset('Profile')->update_or_create( {
			userid => $userid,
			fullname => $name,
			lastloggedin => time, # now
		}, { key => 'primary' });
	}
	session logged_in_userid => $userid;
	session logged_in_username => $profile->name;
	session logged_in_profile_url => uri_for('/profile/'.encode_entities($profile->name));
	schema->resultset('Useravatar')->update_or_create({
		userid => $userid,
		avatarurl => $avatar_url,
	}, { key => 'primary' });
}
#}}}
# Skills {{{
# Edit skills on a profile {{{
sub edit_profile_skills {
	# TODO
}
#}}}
# Get skills on a profile {{{
sub get_profile_skills {
	# TODO
}
#}}}
# Get all skills {{{
sub get_all_skills {
	# TODO
}
#}}}
# Edit project skills {{{
sub edit_project_skills {
	# TODO
}
#}}}
# Get project skills {{{
sub get_project_skills {
	# TODO
}
#}}}
#}}}
# Project {{{

sub get_projectid_by_uid {#{{{
	my ($uid) = @_;
	my $project = get_project_by_uid($uid);
	if($project) {
		return $project->projectid;
	}
	return undef;
}#}}}
sub get_project_by_uid {#{{{
	my ($uid) = @_;
	schema->resultset('Project')
		->find({ projectuid => $uid });
}#}}}
# Check project {{{
sub check_project {
	# TODO
}
#}}}
# Create project {{{
sub create_project {
	# TODO
}
#}}}
# Edit project {{{
sub edit_project {

}
#}}}
#}}}
sub get_profile_by_username {
	my ($username) = @_;
	schema->resultset('Profile')
		->find({ name => $username });
}
sub get_skill_by_name {#{{{
	my ($skillname, $create) = @_;
	my $skill = schema->resultset('Skill')->find({ name => $skillname });
	return $skill if($skill);
	return schema->resultset('Skill')->create({ name => $skillname, description => '' }) if $create;
	undef;
}#}}}
#}}}
# Flash message {{{
sub set_flash {
	my $message = shift;
	session flash => $message;
}
sub get_flash {
	my $msg = session('flash');
	session flash => "";
	return $msg;
}
#}}}
# Session utils {{{
sub uuid_str {#{{{
	$uuid_gen->create_str =~ s/-//gr =~ tr/A-Z/a-z/r;
}#}}}
sub check_logged_in {#{{{
	if ( not session('logged_in') ) {
		send_error("Not logged in", 401);
	}
}#}}}
sub get_logged_in_userid {#{{{
	return session('logged_in_userid') // '';
}#}}}
sub get_logged_in_username {#{{{
	return session('logged_in_username') // '';
}#}}}
#}}}
# Template utils {{{
hook 'before_template_render' => sub {#{{{
	my $tokens = shift;

	$tokens->{'css_url'} = request->base . 'css/style.css';
	if( session('github_user') ) {
		$tokens->{'logged_in'} = 1;
		$tokens->{'user_name'} = session('github_user')->{'name'};
		$tokens->{'profile_url'} = session('logged_in_profile_url');
		$tokens->{'user_avatar'} = session('github_user')->{'avatar_url'};
		#$tokens->{'user_github_profile'} = session('github_user')->{'html_url'}
	} else {
		$tokens->{'logged_in'} = 0;
	}
	$tokens->{'flash_msg'} = get_flash();
	$tokens->{'login_url'} = auth_github_authenticate_url;
	$tokens->{'home_url'} = uri_for('/');
	$tokens->{'logout_url'} = uri_for('/logout');
	$tokens->{'projects_url'} = uri_for('/projects');
	$tokens->{'profiles_url'} = uri_for('/profiles');
	$tokens->{'skills_url'} = uri_for('/skills');
};
#}}}
sub formfill_template {
	my ($template_name, $template_data, $formdata) = @_;
	my $template_html = template $template_name, $template_data;
	return HTML::FillInForm->fill( \$template_html , $formdata );
}
sub skill_map {#{{{
	map { { name => $_->name,
		url => uri_for("/skill/").encode_entities($_->name) } } @_;
}#}}}
sub profile_map {#{{{
	map { { name => $_->fullname,
		url => $_->get_profile_url,
		nick => $_->name,
		avatarurl => $_->get_avatar,
	} } @_
}#}}}
sub project_map {
	map { { name => $_->title,
		url => uri_for('/project/').encode_entities($_->projectuid) } } @_
}
sub profile_to_form {
	my ($profile_row) = @_;
	my $profileid = $profile_row->userid;
	my $skills_have_rs = schema->resultset('Userskill')
		->search({ userid => $profileid, skillstate => USERSKILLSTATE_HAVE } );
	my $skills_want_rs = schema->resultset('Userskill')
		->search({ userid => $profileid, skillstate => USERSKILLSTATE_WANT } );
	
	{ description => $profile_row->description,
		'skills-acquired' => skills_to_form( map { $_->skillid } $skills_have_rs->all ),
		'skills-tolearn' => skills_to_form( map { $_->skillid } $skills_want_rs->all ), };
}
sub skills_to_form {
	join ",", map { $_->name } @_;
}
sub project_to_form {
	my ($project_row) = @_;
	my $projectid = $project_row->projectid;
	my $project_skills_rs = schema->resultset('Projectskill')
		->search({ projectid => $projectid } );
	{ title => $project_row->title,
		repourl => $project_row->githubrepo,
		description => $project_row->description,
		'skills' => skills_to_form( map { $_->skillid } $project_skills_rs->all ), };
}
#}}}
# Data validation {{{
use constant MAX_LENGTH_SKILL => 30;
use constant MAX_LENGTH_DESCRIPTION => 1000;
use constant MAX_LENGTH_TITLE => 80;
sub clean_skills_formdata {
	my ($skills_string) = @_;
	return [ map { $_ =~ s/^\s+|\s+$//gr } # trim
		map { lc } # lowercase
		grep { $_ !~ m,/, } # no /'s in skill
		split(/,/, $skills_string) ];
}
sub validate_skill_data {
	my ($skill_string) = @_;
	# skills can be empty list,
	#  each skill
	#    - can not contain slashes
	#    - must be all lowercase
	#    - trimmed
	#    - 0 < length <= max_length
	my $skills = clean_skills_formdata($skill_string);
	my $errors = [];
	my @new_skills = ();
	if(@$skills) {
		first { not ( is_printable($_) and $_ !~ /\n/m )  } @$skills and push @$errors, "Skills may only contain printable ASCII";
		first { not ( length($_) > 0 && length($_) <= MAX_LENGTH_SKILL )  } @$skills and push @$errors, "Skills must be at most ".MAX_LENGTH_SKILL." characters";
		@new_skills = grep {
				is_printable($_)
				and $_ !~ /\n/m
				and length($_) > 0
				and length($_) <= MAX_LENGTH_SKILL } @$skills;
	}
	{ data => join(",", @new_skills),
		validated => !@$errors, errors => $errors };
}
sub validate_description {
	my ($desc_string) = @_;
	# description can be empty, but needs a max length (only ASCII chars.)
	$desc_string =~ s,^\s+|\s+$,,g; # trim
	my $errors = [];
	length($desc_string) <= MAX_LENGTH_DESCRIPTION or push @$errors, "Project description must be at most ".MAX_LENGTH_DESCRIPTION." characters";
	is_printable($desc_string) or push @$errors, "Project description may only contain printable ASCII";
	{ data => $desc_string, validated => !@$errors, errors => $errors };

}
sub validate_project_title {
	my ($title_string) = @_;
	# check that title field is non-empty, max length (only ASCII chars.)
	$title_string =~ s,^\s+|\s+$,,g; # trim
	my $errors = [];
	length($title_string) > 0 or push @$errors, "Project title can not be empty";
	length($title_string) <= MAX_LENGTH_TITLE or push @$errors, "Project title must be at most ".MAX_LENGTH_TITLE." characters";
	is_printable($title_string) or push @$errors, "Project title may only contain printable ASCII";
	{ data => $title_string, validated => !@$errors, errors => $errors };
}
sub validate_github_repo {
	my ($github_repo_string) = @_;
	# github repo url can either be empty or of the type http://github.com/user/project
	$github_repo_string =~ s,^\s+|\s+,,g; # trim
	my $errors = [];
	unless(length($github_repo_string) == 0) {
		my $u = URI->new($github_repo_string);
		my $path_segments = defined $u ? [$u->path_segments()] : [];
		(defined $u
			and $u->scheme and $u->scheme =~ 'https?'
			and $u->host and $u->host eq 'github.com'
			and $u->path_segments and 0+@$path_segments == 3
				and length($path_segments->[1]) and length($path_segments->[2]))
			or push @$errors, "Not a valid GitHub project URL";
	}
	return { data => $github_repo_string,
		validated => !@$errors, errors => $errors };
}
sub validate_project_form {
	my ($params) = @_;
	my $v_title = validate_project_title($params->{title});
	my $v_repo = validate_github_repo($params->{repourl});
	my $v_desc = validate_description($params->{description});
	my $v_skills = validate_skill_data($params->{"skills"});
	{ new_params => {
			title => $v_title->{data},
			description => $v_desc->{data},
			repourl => $v_repo->{data},
			skills => $v_skills->{data},
		},
		validated => $v_title->{validated} && $v_repo->{validated} && $v_desc->{validated} && $v_skills->{validated},
		errors => [@{$v_title->{errors}}, @{$v_repo->{errors}}, @{$v_desc->{errors}}, @{$v_skills->{errors}}], };
}

sub validate_profile_form {
	my ($params) = @_;
	my $v_desc = validate_description($params->{description});
	my $v_skills_a = validate_skill_data($params->{"skills-acquired"});
	my $v_skills_t = validate_skill_data($params->{"skills-tolearn"});
	{ new_params => {
			description => $v_desc->{data},
			"skills-acquired" => $v_skills_a->{data},
			"skills-tolearn" => $v_skills_t->{data},
		},
		validated => $v_desc->{validated} && $v_skills_a->{validated} && $v_skills_t->{validated},
		errors => [@{$v_desc->{errors}}, @{$v_skills_a->{errors}}, @{$v_skills_t->{errors}}], };
}

sub is_printable {
	$_[0] =~ /^[ -~]*$/m;
}
#}}}

true;
# vim: fdm=marker
