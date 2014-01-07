package autobahn::Event;

use strict;
use warnings;
use Moo;

has description => ( is => 'rw' );

has template_name => ( is => 'rw' );

has template_data => ( is => 'rw' );


1;
