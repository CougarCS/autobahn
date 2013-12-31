package autobahn::Route::Project;

use Dancer ':syntax';
use Dancer::Plugin::DBIC qw(schema resultset rset);

use autobahn::Util;
use autobahn::Helper;
use autobahn::Session;


# Project {{{
get '/project/:projectid' => sub {#{{{
	my $projectuid = params('route')->{projectid};
	my $project = get_project_by_uid($projectuid);
	unless($project) {
		send_error("Invalid project", 401);
	}
	my $projectskills_rs = schema->resultset('Projectskill')
		->search({ projectid => $project->projectid });
	my $others_interested_rs = schema->resultset('Userprojectinterest')
		->search({ projectid => $project->projectid });
	template 'project', {
			page_title => 'Project: '.$project->title,
			name => $project->title,
			github_repo => $project->githubrepo,
			description => $project->description,
			skills => $projectskills_rs->related_resultset('skillid')->get_skill_map,
			project_edit_url => request->path . '/edit',
			project_creator_logged_in => is_project_owner_logged_in_by_uid($projectuid),
			project_interest_url => request->path . '/interest',
			has_interest => has_interest(session('logged_in_userid'), $project->projectid),
			creator_profile_url => uri_for('/profile/'. $project->creator->name),
			creator_profile_nick => $project->creator->name,
			creator_profile_name => $project->creator->fullname,
			others_interested => $others_interested_rs->related_resultset('userid')->get_profile_map,
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

true;
# vim: fdm=marker
