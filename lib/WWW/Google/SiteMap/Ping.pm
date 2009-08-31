package WWW::Google::SiteMap::Ping;
use vars qw($VERSION); $VERSION = '1.10';

=head1 NAME

WWW::Google::SiteMap::Ping - DEPRECATED - See Search::Sitemap

=head1 DEPRECATED

Now that more search engines than just Google are supporting the Sitemap
protocol, the WWW::Google::SiteMap module has been renamed to
L<Search::Sitemap>.

=head1 SYNOPSIS

  use WWW::Google::SiteMap::Ping;
  
  my $ping = WWW::Google::SiteMap::Ping->new(
    'http://www.jasonkohles.com/sitemap.gz',
  );
  
  $ping->submit;
  print "These pings succeeded:\n";
  foreach($ping->success) {
    print "$_: ".$ping->status($_)."\n";
  }
  print "These pings failed:\n";
  foreach($ping->failure) {
    print "$_: ".$ping->status($_)."\n";
  }

=head1 DESCRIPTION

This module makes it easy to notify Google that your sitemaps, or sitemap
indexes, have been updated.  See L<WWW::Google::SiteMap> and
L<WWW::Google::SiteMap::Index> for tools to help you create sitemaps and
indexes.

=cut

use strict;
use warnings;
use LWP::UserAgent;
use URI::Escape qw(uri_escape);

=head1 METHODS

=over 4

=item new();

Create a new WWW::Google::SiteMap::Ping object.  Can be given a list of
URLs which refer to sitemaps or sitemap indexes, these URLs will simply
be passed to url().

=cut

sub new {
	my $class = shift;
	my $self = bless({}, ref($class) || $class);
	$self->{urls} = {};
	$self->add_urls(@_);
	return $self;
}

=item add_urls(@urls);

Add one or more urls to the list of URLs to submit to Google.

=cut

sub add_urls {
	my $self = shift;
	foreach(@_) {
		$self->{urls}->{$_} ||= 'PENDING';
	}
}

=item urls();

Return the list of urls that will be (or were) submitted to google.

=cut

sub urls { return keys %{shift()->{urls}}; }

=item submit

Submit the urls to Google, returns the number of successful submissions.  This
module uses L<LWP::UserAgent> for the web-based submissions, and will honor
proxy settings in the environment.  See L<LWP::UserAgent> for more information.

=cut

sub submit {
	my $self = shift;

	my $ua = $self->user_agent();
	my $success = 0;
	foreach my $url ($self->urls) {
		my $ping = "http://www.google.com/webmasters/sitemaps/ping?".
			"sitemap=".uri_escape($url);
		my $response = $ua->get($ping);
		if($response->is_success) {
			$self->{urls}->{$url} = 'SUCCESS';
			$success++;
		} else {
			$self->{urls}->{$url} = $response->status_line;
		}
	}

	return $success;
}

=item success();

Return the URLs that were successfully submitted.  Note that success only
means that the request was successfully received by Google, it does not
mean your sitemap was found, loaded or parsed successfully.  If you want
to know whether your sitemap was loaded or parsed successfully, you have
to go to L<http://www.google.com/webmasters/sitemaps> and check the status
there.

=cut

sub success {
	my $self = shift;

	return grep { $self->{urls}->{$_} eq 'SUCCESS' } keys %{$self->{urls}};
}

=item failure();

Return the URLs that were not successfully submitted.

=cut

sub failure {
	my $self = shift;

	return grep { $self->{urls}->{$_} ne 'SUCCESS' } keys %{$self->{urls}};
}

=item user_agent();

If called with no arguments, will return the current L<LWP::UserAgent> object
which will be used to access the web-based submission.  If called with an
arugment, you can set the user agent that will be used in case you need to
give it special arguments.  It must be a L<LWP::UserAgent> object.

If you call submit without having provided a user agent, one will be created
for you that is a basic L<LWP::UserAgent> object, which honors proxy settings
in the environment.

=cut

sub user_agent {
	my $self = shift;

	if(@_) { $self->{_ua} = shift }
	unless($self->{_ua}) {
		$self->{_ua} = LWP::UserAgent->new();
		$self->{_ua}->env_proxy;
		$self->{_ua}->timeout(10);
	}
	return $self->{_ua};
}

=back

=head1 MODULE HOME PAGE

The home page of this module is
L<http://www.jasonkohles.com/software/WWW-Google-SiteMap>.  This is where you
can always find the latest version, development versions, and bug reports.  You
will also find a link there to report bugs.

=head1 SEE ALSO

L<http://www.google.com/webmasters/sitemaps/docs/en/submit.html#ping>

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
