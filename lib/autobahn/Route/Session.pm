package autobahn::Routes::Session;

use Dancer ':syntax';
use Dancer::Plugin::Auth::Github;

use autobahn::Util;
use autobahn::Helper;
use autobahn::Session;

# Account {{{
get '/logout' => sub {
	session->destroy;
	set_flash('You are logged out.');
	redirect '/';
};

#by default authentication failure will redirect to this route
get '/auth/github/failed' => sub { return "Github authentication Failed" };

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

true;
# vim: fdm=marker
