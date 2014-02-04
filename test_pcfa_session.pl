#!/usr/bin/env perl

use v5.012;

use strict;
use warnings;

use POE qw(Component::FeedAggregator);
use Log::Log4perl;

sub new_feed_entry {
  my ( $self, @args ) = @_[ OBJECT, ARG0..$#_ ];
  print "in the event";
  my $feed = $args[0]; # POE::Component::FeedAggregator::Feed object of the feed
  my $entry = $args[1]; # XML::Feed::Format::* object of the new entry
  #use DDP; p $feed;
  use DDP; p $entry->title;
};
 

sub _start {
	my $agg = POE::Component::FeedAggregator->new();
	unlink 'bbc.feedcache';
	$agg->add_feed({
		url => 'http://feeds.bbci.co.uk/news/rss.xml', # required
		name => 'bbc',                                 # required
		delay => 5,                                    # default value
		ignore_first => 0,
		entry_event => 'new_feed_entry',               # default value
	});
}


POE::Session->create(
	inline_states => {
		'_start' => \&_start,
		'new_feed_entry' => \&new_feed_entry,
	}
);

POE::Kernel->run();


1;
