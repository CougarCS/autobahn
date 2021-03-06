package autobahn::Route::Profile;

use Dancer ':syntax';
use Dancer::Plugin::DBIC qw(schema resultset rset);

use autobahn::Util;
use autobahn::Helper;
use autobahn::Session;

# Profile {{{
get '/profile/:username' => sub {#{{{
	my $profile = get_profile_by_username(params('route')->{username});
	unless($profile) {
		send_error("User does not exist", 401);
	}
	my $projects_started_rs = schema->resultset('Project')
		->search({ creator => $profile->userid }, { order_by => 'title' });
	my $projects_interest_rs = schema->resultset('Userprojectinterest')
		->search({ userid => $profile->userid }, { prefetch => 'projectid', order_by => 'projectid.title' });
	my $skills_have_rs = get_skills_have_for_profile($profile);
	my $skills_want_rs = get_skills_wanted_for_profile($profile);
	template 'profile', {
		page_title => 'Profile: '.$profile->fullname,
		name => $profile->fullname,
		profile_avatar => $profile->get_avatar,
		description => $profile->description,
		github_url => $profile->get_github_url,
		projects => {
			started => $projects_started_rs->get_project_map,
			interested => $projects_interest_rs->related_resultset('projectid')->get_project_map,
		},
		skills => {
			have => $skills_have_rs->related_resultset('skillid')->get_skill_map,
			want => $skills_want_rs->related_resultset('skillid')->get_skill_map,
		},
		logged_in_user_profile => get_logged_in_username() eq params('route')->{'username'},
		profile_edit_url => uri_for(request->path . '/edit'),
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

true;
# vim: fdm=marker
