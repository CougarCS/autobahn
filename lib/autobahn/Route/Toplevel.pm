package autobahn::Route::Toplevel;

use Dancer ':syntax';
use Dancer::Plugin::DBIC qw(schema resultset rset);

use autobahn::Util;
use autobahn::Helper;
use autobahn::Session;

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
	my $projects_rs = get_all_projects();
	template 'projects', {
		page_title => 'Projects',
		on_projects => 1,
		projects => $projects_rs->get_project_map,
	}
};#}}}
get '/profiles' => sub {#{{{
	my $profiles_rs = schema->resultset('Profile')
		->search({}, { order_by => 'fullname' });
	template 'profiles', {
		page_title => 'Profiles',
		on_profiles => 1,
		profiles => $profiles_rs->get_profile_map,
	}
};#}}}
get '/skills' => sub {#{{{
	my $skills_want_rs = get_all_skills_wanted;
	my $skills_have_rs = get_all_skills_have;
	my $skills_project_rs = get_all_project_skills_have;
	template 'skills', {
		page_title => 'Skills',
		on_skills => 1,
		skills_have => $skills_have_rs->related_resultset('skillid')->get_skill_map,
		skills_want => $skills_want_rs->related_resultset('skillid')->get_skill_map,
		skills_project => $skills_project_rs->related_resultset('skillid')->get_skill_map,
	}
};#}}}
#}}}

true;
# vim: fdm=marker
