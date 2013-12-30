package autobahn::Route::Profile;

use Dancer ':syntax';
use Dancer::Plugin::DBIC qw(schema resultset rset);
use autobahn::Util;
use HTML::Entities;


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

true;
# vim: fdm=marker
