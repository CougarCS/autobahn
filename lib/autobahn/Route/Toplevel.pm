package autobahn::Route::Toplevel;

use Dancer ':syntax';
use Dancer::Plugin::DBIC qw(schema resultset rset);
use autobahn::Util;

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

true;
# vim: fdm=marker
