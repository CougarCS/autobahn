package autobahn::Route::Skill;

use Dancer ':syntax';
use Dancer::Plugin::DBIC qw(schema resultset rset);

use autobahn::Util;
use autobahn::Helper;
use autobahn::Session;

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
				have => $skill_have_rs->related_resultset('userid')->get_profile_map,
				want => $skill_want_rs->related_resultset('userid')->get_profile_map,
			},
			projects => $projects_rs->related_resultset('projectid')->get_project_map,
	};
};
#}}}
##}}}

true;
# vim: fdm=marker
