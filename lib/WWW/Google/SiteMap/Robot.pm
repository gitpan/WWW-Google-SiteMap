package WWW::Google::SiteMap::Robot;
use vars qw($VERSION); $VERSION = '1.10';

=head1 NAME

WWW::Google::SiteMap::Robot - DEPRECATED - See Search::Sitemap

=head1 DEPRECATED

Now that more search engines than just Google are supporting the Sitemap
protocol, the WWW::Google::SiteMap module has been renamed to
L<Search::Sitemap>.

=head1 SYNOPSIS

  use WWW::Google::SiteMap::Robot;
  
  my $robot = WWW::Google::SiteMap::Robot->new(
    domain        => 'www.jasonkohles.com',
    restrict      => qr{^http://www.jasonkohles.com/},
    starting_url  => ['/index.html','/google-me.html'],
    delay         => 1, # delay in minutes
    sitemap_file  => '/var/www/html/sitemap.gz',
    sitemap_url   => 'http://www.jasonkohles.com/sitemap.gz',
    user_agent    => 'MyOwnSpider/1.0',
  );
  $robot->run();

=head1 DESCRIPTION

This is a simple robot class which subclasses L<LWP::RobotUA> to create a
web-crawling spider.  By giving it the URL to your home page, it will crawl
all the pages it can find and create a sitemap for them.

=cut

use strict;
use warnings;
use WWW::Mechanize;
use WWW::RobotRules;
use Carp qw(croak);
use POSIX qw(strftime);
use WWW::Google::SiteMap;
use WWW::Google::SiteMap::Ping;

=head1 METHODS

=over 4

=item new();

Create a new WWW::Google::SiteMap::Robot object.

=cut

sub new {
	my $class = shift;
	my %args = @_;

	my $self = bless({},ref($class)||$class);

	croak "No domain specified" unless $args{domain};

	# These items have other methods that depend on them, so they need to
	# be called in this order:
	foreach my $x (qw(domain status_storage)) {
		$self->$x(delete($args{$x}));
	}

	while(my($k,$v) = each %args) { $self->$k($v) }

	return $self;
}

=item domain();

Get/Set the domain name of the server you want to spider.  This is used both
to create the initial URLs to put in the TO-DO list, as well as to create a
built-in restriction that prevents the robot from leaving your site.

Google doesn't allow a sitemap to refer to URL's that are outside the domain
that the sitemap was retrieved for, so there really isn't any benefit in
allowing the robot to cross multiple domains.  If you really think you need
to do this, you probably really just want more than one robot.  If you are
absolutely certain you want to cross domain boundaries, then you'll have to
subclass this module, and Google will probably reject your sitemaps.

=cut

sub domain {
	my $self = shift;

	if(@_) { $self->{domain} = shift }
	return $self->{domain};
}

=item restrict();

Get/Set the url restrictions.  The restriction list can be any of the
following:

=over 4

=item A list reference (or a list)

A list reference is assumed to contain a list of any of the following types.
When passed as an argument to the constructor it has to be a reference, but 
when you are calling restrict() as a method, you can pass it a list, and it
will turn it into a list reference.  If you provide more than one restrict
item in a list, the first one to return true will cause the rest of them to
be skipped, so the URL will be restricted (skipped) if any of the items are
true (if you want more complexity than that, then just use a code reference
by itself, which can do whatever it wants.)

=item A code reference

If you give restrict a code reference, it will be passed the URL that is
about to be spidered, if the code returns a true value, the URL will be
skipped.  If it returns false, it will not be restricted.

=item A regexp reference

If you give it a regexp reference, then the regexp will be applied to the
URL about to be spidered, if the regexp matches, then the URL will be
skipped.

=back

If called with no arguments, it will return the current list of restrictions.

There are built-in restrictions that are always applied at the end of your
restriction list.  One is a url regexp that matches your domain name, to
prevent the robot from leaving your site (it's qr{^\w+://YOUR_DOMAIN/}).
The other is a restriction that excludes any URLs that are not allowed by
your robots.txt.  This module doesn't provide any method for ignoring the
robots.txt restriction (because it's dangerous), you should really modify
your robots.txt to allow this robot to bypass any of the restrictions you
don't want it to honor.

For example, if your robot.txt contains:

  User-Agent: *
  Disallow: /admin
  Disallow: /google-stuff

Then those two paths will not be included in your sitemap.  If you decided
you actually did want /google-stuff to appear in your sitemap, you could add
this to your robots.txt:

  User-Agent: WWWGoogleSiteMapRobot
  Disallow: /admin

=cut

sub restrict {
	my $self = shift;

	if(@_) { $self->{restrict} = \@_ }
	unless($self->{restrict}) { $self->{restrict} = [] }

	return @{$self->{restrict}};
}

=item starting_url();

If called with one or more arguments, they are assumed to be URLs which will
seed the spider.  The spider continues to run as long as there are URLs in
it's "TO-DO" list, this method simply adds items to that list.  The arguments
to starting_url are just the filename part of the url, if you don't specify
one, it defaults to '/'.

You can pass it either a list of URLs, or a list reference (so you can use
a list reference in the constructor.)

=cut

sub starting_url {
	my $self = shift;

	if(@_) {
		$self->{starting_url} = \@_;
		$self->_populate_starting_urls;
	}
	unless($self->{starting_url}) { $self->{starting_url} = ['/'] }
	return $self->{starting_url};
}

sub _populate_starting_urls {
	my $self = shift;
	my @populate = @_;

	unless(@populate) { @populate = $self->starting_url() }

	foreach(@populate) {
		next unless $_;
		if(ref($_)) { $self->_populate_starting_urls(@{$_}); next; }
		$self->{storage}->{"http://".$self->domain.$_} ||= '';
	}
}

=item delay();

Get or set the delay (in minutes) to wait between requests.  The default is
1 minute, and if you want to hammer on your web server you can set this to
a value less than 1.

=cut

sub delay {
	my $self = shift;

	if(@_) { $self->{delay} = shift }

	return $self->{delay} || 1;
}

=item sitemap_file();

Sets the filename to save the L<WWW::Google::SiteMap> object to.  This is
required.

=cut

sub sitemap_file {
	my $self = shift;

	if(@_) { $self->{sitemap_file} = shift }
	return $self->{sitemap_file};
}

=item sitemap_url();

Sets the url for the sitemap.  This is optional, but if you specify it, then
the robot will notify Google (using L<WWW::Google::SiteMap::Ping>) after it
writes a new sitemap.

=cut

sub sitemap_url {
	my $self = shift;

	if(@_) { $self->{sitemap_url} = shift }
	return $self->{sitemap_url};
}

=item user_agent();

Set the User Agent that this robot uses to identify itself.  The default is
'WWWGoogleSiteMapRobot/version' (unless you have subclassed this module, it's
actually the class name with special characters removed.)
Be careful about changing this while the robot is active (this includes
changing it between runs if you are storing the state) as this affects how
your robot interprets your robots.txt file.

=cut

sub user_agent {
	my $self = shift;

	if(@_) { $self->{user_agent} = shift }
	unless($self->{user_agent}) {
		my $pkg = ref($self) || $self;
		$pkg =~ s/\W//g;
		$self->{user_agent} = join('/',$pkg,$VERSION);
	}
	return $self->{user_agent};
}

=item robot_rules();

Get or set the L<WWW::RobotRules> object used to handle robots.txt.

=cut

sub robot_rules {
	my $self = shift;

	if(@_) { $self->{robot_rules} = shift }
	unless($self->{robot_rules}) {
		$self->{robot_rules} = WWW::RobotRules->new($self->user_agent);
		my $url = "http://".$self->domain."/robots.txt";
		my $mech = $self->mechanize();
		$mech->get($url);
		$self->{robot_rules}->parse($url,$mech->content);
	}
	return $self->{robot_rules};
}

=item mechanize();

Get or set the L<WWW::Mechanize> object used for retrieving web documents.

=cut

sub mechanize {
	my $self = shift;

	if(@_) { $self->{mech} = shift }
	unless($self->{mech}) {
		$self->{mech} = WWW::Mechanize->new(
			agent		=> $self->user_agent,
			stack_depth	=> 1,
		);
	}
	return $self->{mech};
}

=item status_storage();

If you provide status_storage with a tied hash, it will be used to store the
state of the TO-DO list which includes the data needed to build the sitemap,
as well as the list of unvisited URLs.  This means that the robot can continue
where it left off if it is interrupted for some reason before finishing, then
you don't have to re-spider the entire site.  This is strongly recommended.

You can use this with basically anything that can be implemented as a tied
hash, as long as it can handle fully-qualified URLs as keys, the values will
be simple scalars (it won't try to store references or anything like that
in the values.)

Example:

  use WWW::Google::SiteMap::Robot;
  use GDBM::File;
  
  tie my %storage, 'GDBM_File', '/tmp/my-robot-status', &GDBM_WRCREAT, 0640;
  my $robot = WWW::Google::SiteMap::Robot->new(
    restrict     => qr{^http://www.jasonkohles.com/},
    starting_url => 'http://www.jasonkohles.com/index.html',
    sitemap_file => '/var/www/html/sitemap.gz',
  );

If you don't provide a tied hash to store the status in, it will be stored in
a normal (in-memory) hash.

=cut

sub status_storage {
	my $self = shift;

	if(@_) {
		$self->{storage} = shift;
		# If the storage is changed, we might have lost our starting urls
		$self->_populate_starting_urls;
	}
	unless($self->{storage}) {
		$self->{storage} = {};
		$self->_populate_starting_urls;
	}
	return $self->{storage};
}

=item pending_urls();

Return a list of all the URLs that have been found, but have not yet been
visited.  This may include URLs that will later be restricted, and will not
be visited.

=cut

sub pending_urls {
	my $self = shift;
	my $todo = $self->status_storage;
	return grep { ! $todo->{$_} } keys %{$todo};
}

=item restricted_urls();

Return a list of all the URLs that are in the TO-DO list that have already
been tried, but were skipped because they were restricted.

=cut

sub restricted_urls {
	my $self = shift;
	$self->_url_data_match(qr/^RESTRICTED /o);
}

=item visited_urls();

Return a list of all the URLs that have already been visited, and will be
included in the sitemap.

=cut

sub visited_urls {
	my $self = shift;
	$self->_url_data_match(qr/^OK /o);
}

=item run();

Start the robot running.  If you are building your robot into a larger
program that has to handle other tasks as well, then you can pass an integer
to run(), which will be the number of URLs to check (of course then you will
have to call it again later, probably in a loop, to make sure you get them
all.)  Returns true if something was done, returns false if no pending URLs
were found in the TO-DO list.  Calling start() again after it has returned
false is rather pointless.  If you call it in a loop as part of a larger
program, you are also responsible for calling write_sitemap() after all the
data is collected.

If called with no arguments (or a false argument) it will run until there are
no more URLs to process.

=cut

sub run {
	my $self = shift;
	my $count = shift;

	my $counter = $count;
	my @waiting = $self->pending_urls;
	my $mech = $self->mechanize;
	while(1) {
		sleep($self->delay * 60); # sleep first, because of all the nexts
		unless(@waiting) { @waiting = $self->pending_urls }
		if(my $url = shift(@waiting)) {
			# first make sure we didn't already do it
			next if $self->{storage}->{$url};
			# Then make sure it isn't restricted
			if($self->_check_restrictions($url)) {
				$self->{storage}->{$url} = 'RESTRICTED';
				next;
			}
			$mech->get($url);
			if($mech->success) {
				# extract the last modification time from the page
				my $modtime = $mech->response->last_modified()
					|| (time - $mech->response->current_age);
				$self->{storage}->{$url} = "SUCCESS $modtime";
				# add any links in the page to our todo list
				foreach($mech->links) {
                    my $url = $_->url_abs;
                    $url =~ s/#[^#]+$//;
					$self->{storage}->{$url} ||= '';
				}
			} else {
				$self->{storage}->{$url} = 'ERROR '.$mech->status();
			}
			next;
		}

		if($count) {
			last unless $counter--;
		} else {
			last unless @waiting;
		}
	}
	unless($count) { # if you are limiting, you have to do this part yourself
		$self->write_sitemap() if $self->sitemap_file();
	}
}

sub _check_restrictions {
	my $self = shift;
	my $url = shift;

	# some hard-coded restrictions for safety sake
	if($url !~ /^(http|https):/) {
		return 1;
	}

	foreach my $r ($self->restrict) {
		if(ref($r) eq 'Regexp' && $url =~ /$r/) {
			return 1;
		}
		if(ref($r) eq 'CODE' && $r->($url)) {
			return 1
		}
	}
	my $domain = $self->domain;
	if($url !~ m{^\w+://$domain}o) {
		return 1;
	}
	unless($self->robot_rules->allowed($url)) {
		return 1;
	}
	return 0;
}

=item write_sitemap();

Write out the sitemap (if a sitemap file was specified), and optionally notify
Google (if a sitemap url was specified).

=cut

sub write_sitemap {
	my $self = shift;

	my $map = WWW::Google::SiteMap->new(
		file	=> $self->sitemap_file,
		pretty	=> 1,
	);
	while(my($url,$val) = each(%{$self->{storage}})) {
		next unless $val =~ /^SUCCESS /;
		my(undef,$lastmod) = split(' ',$val);
		$map->add(WWW::Google::SiteMap::URL->new(
			loc			=> $url,
			lastmod		=> $lastmod,
		));
	}
	$map->write;

	if($self->sitemap_url) {
		my $ping = WWW::Google::SiteMap::Ping->new($self->sitemap_url);
		$ping->submit;
	}
}

sub _url_data_match {
	my $self = shift;
	my $regexp = shift;

	my $todo = $self->status_storage;
	return grep {
		$todo->{$_} && $todo->{$_} =~ /^$regexp/o
	} keys %{$todo};
}

=back

=head1 EXAMPLE ROBOT

  #!/usr/bin/perl -w
  ##################
  use strict;
  use warnings;
  use lib 'lib';
  use WWW::Google::SiteMap::Robot;
  use GDBM_File;
  
  foreach my $site (qw(www.example.com www.example2.com www.example3.com)) {
    my $status = '/tmp/sitemap-robot-status.$site.db';
    tie my %storage, 'GDBM_File', $status, &GDBM_WRCREAT, 0640
    my $robot = WWW::Google::SiteMap::Robot->new(
      domain         => $site,
      status_storage => \%storage,
      sitemap_file   => "/var/www/$site/sitemap.gz",
      sitemap_url    => "http://$site/sitemap.gz",
    );
    $robot->run();
  }

=head1 MODULE HOME PAGE

The home page of this module is
L<http://www.jasonkohles.com/software/WWW-Google-SiteMap>.  This is where you
can always find the latest version, development versions, and bug reports.  You
will also find a link there to report bugs.

=head1 SEE ALSO

L<WWW::Google::SiteMap>

L<WWW::Google::SiteMap::Index>

L<WWW::Google::SiteMap::Ping>

L<http://www.jasonkohles.com/software/WWW-Google-SiteMap>

L<WWW::Mechanize>

L<WWW::RobotRules>

=head1 AUTHOR

Jason Kohles, E<lt>email@jasonkohles.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Jason Kohles

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
__END__
