# vim: fdm=marker
package autobahn;
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

use constant USERSKILLSTATE_HAVE => 1;
use constant USERSKILLSTATE_WANT => 2;

our $VERSION = '0.1';
our $uuid_gen = Data::UUID->new;

set 'session'      => 'Simple';
set 'template'      => 'template_toolkit';
set 'layout'      => 'main';
# List of everything (home,profiles,projects,skills) routes {{{
#by default success will redirect to this route
get '/' => sub {#{{{
	template 'index', {
		page_title => 'Welcome!',
		on_home => 1,
		# TODO
		#events => [
			#{ time => '2013-02-14 00:13:15+0000', title => 'Joe Joined 1', url => uri_for('/profile/joe'), description => '<b>heh</b>' },
			#{ time => '2013-02-14 00:14:52+0000', title => 'Skill added 2', url => uri_for('/profile/cool'), description => '<ul>meh</ul>' },
			#{ time => '2013-02-14 00:14:58+0000', title => 'Joe added project 3', url => uri_for('/project/joe'), description => '' },
		#],
	};
};#}}}
get '/projects' => sub {#{{{
	my @projects = schema->resultset('Project')
		->search({}, { order_by => 'title' })->all;
	template 'projects', {
		page_title => 'Projects',
		on_projects => 1,
		projects => [ project_map( @projects ) ]
	}
};#}}}
get '/profiles' => sub {#{{{
	my @profiles = schema->resultset('Profile')
		->search({}, { order_by => 'fullname' })->all;
	template 'profiles', {
		page_title => 'Profiles',
		on_profiles => 1,
		profiles => [ profile_map(@profiles) ]
	}
};#}}}
get '/skills' => sub {#{{{
	my $skills_want_rs = schema->resultset('Userskill')->search({ skillstate => USERSKILLSTATE_WANT },
		{ prefetch => 'skillid', group_by => [qw/me.skillid/], order_by => 'skillid.name'  });
	my $skills_have_rs = schema->resultset('Userskill')->search({ skillstate => USERSKILLSTATE_HAVE },
		{ prefetch => 'skillid', group_by => [qw/me.skillid/], order_by => 'skillid.name' });
	my $skills_project_rs = schema->resultset('Projectskill')->search({},
		{ prefetch => 'skillid', group_by => [qw/me.skillid/], order_by => 'skillid.name'  });
	template 'skills', {
		page_title => 'Skills',
		on_skills => 1,
		skills_have => [ skill_map(map { $_->skillid } $skills_have_rs->all) ],
		skills_want => [ skill_map(map { $_->skillid } $skills_want_rs->all) ],
		skills_project => [ skill_map(map { $_->skillid } $skills_project_rs->all) ],
	}
};#}}}
#}}}
# Profile {{{
get '/profile/:username' => sub {#{{{
	my $profile = get_profile_by_username(params('route')->{username});
	unless($profile) {
		send_error("User does not exist", 401);
	}
	my @projects_started = schema->resultset('Project')
		->search({ creator => $profile->userid }, { order_by => 'title' })->all;
	my @projects_interest = schema->resultset('Userprojectinterest')
		->search({ userid => $profile->userid }, { prefetch => 'projectid', order_by => 'projectid.title' })->all;
	my $skills_have_rs = schema->resultset('Userskill')
		->search({ userid => $profile->userid, skillstate => USERSKILLSTATE_HAVE },
		{ prefetch => 'skillid', order_by => 'skillid.name' });
	my $skills_want_rs = schema->resultset('Userskill')
		->search({ userid => $profile->userid, skillstate => USERSKILLSTATE_WANT },
		{ prefetch => 'skillid', order_by => 'skillid.name' });
	template 'profile', { 
		page_title => 'Profile: '.$profile->fullname,
		name => $profile->fullname,
		profile_avatar =>
					schema->resultset('Useravatar')
						->find({ userid => $profile->userid })->avatarurl,
		description => $profile->description,
		github_url => 'http://github.com/'.encode_entities($profile->name),
			# TODO refactor to a function that looks up github login
		projects => {
			started => [ project_map( @projects_started ) ],
			interested => [ project_map( map { $_->projectid } @projects_interest ) ],
		},
		skills => {
			have => [skill_map(map { $_->skillid } $skills_have_rs->all)],
			want => [skill_map(map { $_->skillid } $skills_want_rs->all)],
		},
		logged_in_user_profile => get_logged_in_username() eq params('route')->{'username'},
		profile_edit_url => request->path . '/edit',
	};
};
#}}}
get '/profile/:username/edit' => sub {#{{{
	check_logged_in();
	check_profile_permission();
	unless(get_logged_in_username() eq params('route')->{'username'}) {
		send_error("You do not have permission for this action.", 401);
	}
	my $username = params('route')->{username};
	my $profile = schema->resultset('Profile')->find({ name => $username });
	unless($profile) {
		send_error("User does not exist", 401);
	}
	# if already in database, fill form
	return formfill_template('profileedit', {}, profile_to_form($profile));
};#}}}
post '/profile/:username/edit' => sub {#{{{
	check_logged_in();
	check_profile_permission();
	my $username = params('route')->{username};
	my %params = params();
	if( exists $params{'update-profile'} ) {
		my $v_data = validate_profile_form({params('body')});
		unless($v_data->{validated}) {
			# data validation
			my $error_string = template 'errorlist', { errors => $v_data->{errors} }, { layout => undef };
			set_flash($error_string);
			return formfill_template('profileedit', {}, $v_data->{new_params});
			#send_error('Invalid data', 401);
		}
		params_profile_edit($v_data->{new_params});
		redirect '/profile/'.$username;
	}
};#}}}
sub check_profile_permission {
	unless(get_logged_in_username() eq params('route')->{'username'}) {
		send_error("You do not have permission for this action.", 401);
	}
}

sub params_profile_edit {#{{{
	my ($params) = @_;
	my $username = params('route')->{username};
	my $profile = get_profile_by_username($username);
	my $userid = $profile->userid;
	my $description = $params->{description};
	my $skills_acquired = clean_skills_formdata($params->{"skills-acquired"});
	my $skills_tolearn = clean_skills_formdata($params->{"skills-tolearn"});

	$profile->update({ description => $description });
	my $userskills_rs = schema->resultset('Userskill')->search({ userid => $userid });
	$userskills_rs->delete if $userskills_rs;
	schema->resultset('Userskill')->update_or_create({
		userid => $userid,
		skillid => get_skill_by_name($_,1)->skillid,
		skillstate => USERSKILLSTATE_HAVE,
	}) for @$skills_acquired;
	schema->resultset('Userskill')->update_or_create({
		userid => $userid,
		skillid => get_skill_by_name($_,1)->skillid,
		skillstate => USERSKILLSTATE_WANT,
	}) for @$skills_tolearn;

	return;
}#}}}
#}}}
# Skill {{{
get '/skill/:skillname' => sub {#{{{
	my $skill = get_skill_by_name(params('route')->{skillname});
	unless($skill) {
		send_error("Unknown skill", 401);
	}
	my $skill_want_rs = schema->resultset('Userskill')->search({ skillid => $skill->skillid,
		skillstate => USERSKILLSTATE_WANT });
	my $skill_have_rs = schema->resultset('Userskill')->search({ skillid => $skill->skillid,
		skillstate => USERSKILLSTATE_HAVE });
	my $projects_rs = schema->resultset('Projectskill')->search({ skillid => $skill->skillid });
	template 'skill', { 
			page_title => 'Skill: '.$skill->name,
			name => $skill->name,
			profiles => {
				have => [ profile_map( map { $_->userid } $skill_have_rs->all ) ],
				want => [ profile_map( map { $_->userid } $skill_want_rs->all ) ]
			},
			projects => [ project_map( map { $_->projectid } $projects_rs->all) ],
	};
};
#}}}
##}}}
# Account {{{
get '/logout' => sub {
	session->destroy;
	set_flash('You are logged out.');
	redirect '/';
};

#by default authentication failure will redirect to this route
get '/auth/github/failed' => sub { return "Github authentication Failed" };

#make sure you call this first.
#initializes the config
auth_github_init();

hook before => sub {
	# we don't want to be in a redirect loop
	return if request->path =~ m{/auth/github/callback};
	if (session('github_user') and not session('github_checked')) {
		check_account();
		session github_checked => true;
		session logged_in => true;
		if(session('new_account')) {
			set_flash('Welcome to Autobahn!');
		}
	}
};
#}}}
# Project {{{
get '/project/:projectid' => sub {#{{{
	my $projectuid = params('route')->{projectid};
	my $project = get_project_by_uid($projectuid);
	unless($project) {
		send_error("Invalid project", 401);
	}
	my $projectskills_rs = schema->resultset('Projectskill')
		->search({ projectid => $project->projectid });
	my @others_interested = map { $_->userid } schema->resultset('Userprojectinterest')
		->search({ projectid => $project->projectid })->all;
	template 'project', { 
			page_title => 'Project: '.$project->title,
			name => $project->title,
			github_repo => $project->githubrepo,
			description => $project->description,
			skills => [ skill_map(map { $_->skillid } $projectskills_rs->all) ],
			project_edit_url => request->path . '/edit',
			project_creator_logged_in => is_project_owner_logged_in_by_uid($projectuid),
			project_interest_url => request->path . '/interest',
			has_interest => has_interest(session('logged_in_userid'), $project->projectid),
			creator_profile_url => uri_for('/profile/'. $project->creator->name),
			creator_profile_nick => $project->creator->name,
			creator_profile_name => $project->creator->fullname,
			others_interested => [ profile_map(@others_interested) ]
	};
};
#}}}
post '/project' => sub {#{{{
	check_logged_in();
	my $uuid = uuid_str();
	my $project_data = session('project_data');
	$project_data->{$uuid} = {};
	session project_data => $project_data;
	set_flash('Adding new project');
	redirect '/project/'.$uuid.'/edit';
};#}}}
get '/project/:projectid/edit' => sub {#{{{
	# TODO add a delete button
	check_logged_in();
	check_project_permission();
	my $projectuid = params('route')->{projectid};
	my $project = schema->resultset('Project')->find({ projectuid => $projectuid });
	unless($project or is_projectuid_in_session($projectuid)) {
		send_error("Project does not exist", 401);
	}
	my $project_data = session('project_data');
	my $formdata = $project_data->{$projectuid} // {};
	if($project) {
		# if already in database, fill form
		$formdata = project_to_form($project);
	}
	return formfill_template( 'projectedit', {} , $formdata );
};#}}}
post '/project/:projectid/edit' => sub {#{{{
	check_logged_in();
	check_project_permission();
	my $uuid = params('route')->{'projectid'};
	my %params = params();
	if( exists $params{'update-project'} ) {
		my $v_data = validate_project_form({params('body')});
		unless($v_data->{validated}) {
			# data validation
			set_flash(template 'errorlist', { errors => $v_data->{errors} }, { layout => undef });
			return formfill_template('projectedit', {}, $v_data->{new_params});
			#send_error('Invalid data', 401);
		}
		params_project_edit($v_data->{new_params});
		redirect '/project/'.$uuid;
	} elsif( exists $params{'delete-project'} ) {
		check_logged_in();
		delete_project_by_uid($uuid);
		set_flash('Deleted project');
		redirect session('logged_in_profile_url');
	}
};#}}}
post '/project/:projectid/interest' => sub {#{{{
	check_logged_in();
	my $projectuid = params('route')->{'projectid'};
	my $project = schema->resultset('Project')->find({ projectuid => $projectuid });
	unless($project) {
		send_error("Invalid project", 401);
	}
	if(is_project_owner_logged_in_by_uid($projectuid)) {
		# project owner can not have project interest
		send_error("You do not have permission for this action.", 401);
	}
	params_project_interest_toggle();
	redirect uri_for('/project/'.$projectuid);
};#}}}

sub has_interest {
	my ($userid, $projectid) = @_;
	my $user_interest_row = schema->resultset('Userprojectinterest')
		->find({ userid => $userid, projectid => $projectid });
}
sub params_project_interest_toggle {
	my $projectuid = params('route')->{'projectid'};
	my $project = schema->resultset('Project')->find({ projectuid => $projectuid });
	my $projectid = $project->projectid;
	my $userid = session('logged_in_userid');
	my $user_interest_row = schema->resultset('Userprojectinterest')
		->find_or_new({ userid => $userid, projectid => $projectid });
	if($user_interest_row->in_storage) {
		$user_interest_row->delete;
	} else {
		$user_interest_row->insert;
	}
}

sub is_project_owner_logged_in_by_uid {
	my ($projectuid) = @_;
	my $project = schema->resultset('Project')->find({ projectuid => $projectuid });
	return 0 unless $project;
	my $project_creator_name = $project->creator->name;
	return get_logged_in_username() eq $project_creator_name;
}
sub is_projectuid_in_session {
	my ($projectuid) = @_;
	my $project_data = session('project_data');
	exists $project_data->{$projectuid};
}
sub check_project_permission {
	my $projectuid = params('route')->{'projectid'};
	unless(is_project_owner_logged_in_by_uid($projectuid)
		or is_projectuid_in_session($projectuid)) {
		send_error("You do not have permission for this action.", 401);
	}
}
sub clean_skills_formdata {
	my ($skills_string) = @_;
	return [ map { $_ =~ s/^\s+|\s+$//gr } # trim
		map { lc } # lowercase
		grep { $_ !~ m,/, } # no /'s in skill
		split(/,/, $skills_string) ];
}
sub params_project_edit {#{{{
	my ($params) = @_;
	my $projectuid = params('route')->{projectid};
	my $title = $params->{title};
	my $repo_url = $params->{repourl};
	my $description = $params->{description};
	my $skills = clean_skills_formdata($params->{"skills"});

	my $project = schema->resultset('Project')
		->find({ projectuid => $projectuid  });
	my $projectid;
	unless($project) {
		# new
		$project = schema->resultset('Project')->new({
			projectuid => $projectuid,
			title => $title,
			description => $description,
			githubrepo => $repo_url,
			creator => get_logged_in_userid(),
			createtime => time,
		});
		$project = $project->insert;
		$projectid = $project->projectid;
	} else {
		# update
		$projectid = $project->projectid;
		$project = schema->resultset('Project')->update_or_create({
			projectid => $projectid,
			title => $title,
			description => $description,
			githubrepo => $repo_url,
		}, { key => 'primary' });
	}
	my $projectskills_rs = schema->resultset('Projectskill')->search({ projectid => $projectid });
	$projectskills_rs->delete if $projectskills_rs;
	schema->resultset('Projectskill')->update_or_create({
		projectid => $projectid,
		skillid => get_skill_by_name($_, 1)->skillid,
	}) for @$skills;
	return;
}#}}}
sub delete_project_by_uid {#{{{
	my ($projectuid) = @_;
	my $projectid = get_projectid_by_uid($projectuid);
	return unless $projectid;
	my $projectskills_rs = schema->resultset('Projectskill')
		->search({ projectid => $projectid });
	$projectskills_rs->delete;
	my $userprojectinterest_rs = schema->resultset('Userprojectinterest')
		->search({ projectid => $projectid });
	$userprojectinterest_rs->delete;
	my $project = schema->resultset('Project')
		->find({ projectid => $projectid });
	$project->delete;
}#}}}
sub check_project_edit {#{{{
	my ($project) = @_;
	if ( not session('logged_in') ) { # can't edit if not logged in
		send_error("Not logged in", 401);
	}
	# TODO error if not owner

}#}}}
#}}}
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
		url => uri_for('/profile/').encode_entities($_->name),
		nick => $_->name, 
		avatarurl => # TODO only if it exists, otherwise use a default
			schema->resultset('Useravatar')
				->find({ userid => $_->userid })->avatarurl || 'test',
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
