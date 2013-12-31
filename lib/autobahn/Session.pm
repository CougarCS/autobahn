package autobahn::Session;

use parent qw( Exporter );
@EXPORT = qw(
    check_account
    uuid_str
    check_logged_in
    get_logged_in_userid
    get_logged_in_username
);
use Dancer ':syntax';
use Dancer::Plugin::Auth::Github;
use Dancer::Plugin::DBIC qw(schema resultset rset);
use Data::UUID;

use autobahn::Helper;

our $uuid_gen = Data::UUID->new;


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
	session logged_in_profile_url => $profile->get_profile_url;
	schema->resultset('Useravatar')->update_or_create({
		userid => $userid,
		avatarurl => $avatar_url,
	}, { key => 'primary' });
}
#}}}

sub uuid_str {
	$uuid_gen->create_str =~ s/-//gr =~ tr/A-Z/a-z/r;
}
sub check_logged_in {
	if ( not session('logged_in') ) {
		send_error("Not logged in", 401);
	}
}
sub get_logged_in_userid {#{{{
	return session('logged_in_userid') // '';
}#}}}
sub get_logged_in_username {
	return session('logged_in_username') // '';
}

1;
# vim: fdm=marker
