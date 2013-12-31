package autobahn::Util;

use parent qw( Exporter );
@EXPORT = qw(
    set_flash get_flash

    formfill_template profile_to_form skills_to_form
    project_to_form clean_skills_formdata
    validate_skill_data validate_description
    validate_project_title validate_github_repo validate_project_form
    validate_profile_form is_printable
);

use Dancer ':syntax';
use Dancer::Plugin::Auth::Github;
use Dancer::Plugin::DBIC qw(schema resultset rset);
use HTML::FillInForm;
use URI::Encode qw(uri_encode uri_decode);
use HTML::Entities;
use List::AllUtils qw/first/;
#use Text::Markdown 'markdown';
#use HTML::Restrict;
use Unicode::CaseFold; # because fc is not in Perl < 5.016

use autobahn::Helper;

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
sub profile_to_form {
	my ($profile_row) = @_;
	my $profileid = $profile_row->userid;
	my $skills_have_rs = get_skills_have_for_profile($profile_row);
	my $skills_want_rs = get_skills_wanted_for_profile($profile_row);
	
	{ description => $profile_row->description,
		'skills-acquired' => skills_to_form( map { $_->skillid } $skills_have_rs->all ),
		'skills-tolearn' => skills_to_form( map { $_->skillid } $skills_want_rs->all ), };
}
sub skills_to_form {
	join ",", sort { fc $a cmp fc $b } map { $_->name } @_;
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
