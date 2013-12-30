# vim: fdm=marker
package autobahn;
use Dancer ':syntax';
use Dancer::Plugin::Auth::Github;
use Dancer::Plugin::DBIC qw(schema resultset rset);

our $VERSION = '0.1';

set 'session'      => 'Simple';
set 'template'      => 'template_toolkit';
set 'layout'      => 'main';

# make sure you call this first.
# initializes the config
auth_github_init();

use autobahn::Route::Toplevel;
use autobahn::Route::Project;
use autobahn::Route::Profile;
use autobahn::Route::Session;
use autobahn::Route::Skill;

true;
