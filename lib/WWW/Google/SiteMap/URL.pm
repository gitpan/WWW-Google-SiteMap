package WWW::Google::SiteMap::URL;
use vars qw($VERSION); $VERSION = '1.10';

=head1 NAME

WWW::Google::SiteMap::URL - DEPRECATED - See Search::Sitemap

=head1 DEPRECATED

Now that more search engines than just Google are supporting the Sitemap
protocol, the WWW::Google::SiteMap module has been renamed to
L<Search::Sitemap>.

=head1 SYNOPSIS

  use WWW::Google::SiteMap;

=head1 DESCRIPTION

This is a helper class that supports L<WWW::Google::SiteMap> and
L<WWW::Google::SiteMap::Index>.

=cut

=head1 METHODS

=over 4

=cut

use strict;
use warnings;
use Carp qw(carp croak);
use XML::Twig qw();
use POSIX qw(strftime);
use HTML::Entities qw(encode_entities);

=item new()

=cut

sub new {
	my $class = shift;
	my %opts = ref($_[0]) ? %{$_[0]} : @_;

	my $self = bless({}, $class);
	while(my($key,$value) = each %opts) { $self->$key($value) }
	return $self;
}

=item loc()

Change the URL associated with this object.  For a L<WWW::Google::SiteMap>
this specifies the URL to add to the sitemap, for a
L<WWW::Google::SiteMap::Index>, this is the URL to the sitemap.

=cut

sub loc {
	shift->_doval('loc', sub {
		local $_ = shift;
		return unless defined;
		return 'must be less than 2048 characters long' unless length($_) < 2048;
		return 'must be a fully qualified url' unless m{^https?://};
		return;
	}, @_);
}

=item changefreq()

Set the change frequency of the object.  This field is not used in sitemap
indexes, only in sitemaps.

=cut

sub changefreq {
	shift->_doval('changefreq', sub {
		local $_ = shift;
		my @values = qw(always hourly daily weekly monthly yearly never);
		my $re = join('|',@values);
		return unless defined;
		return 'must be one of '.join(', ',@values) unless /^$re$/;
		return;
	}, @_);
}

=item lastmod()

Set the last modified time.  You have to provide this as one of the following:

=over 4

=item a complete ISO8601 time string

A complete time string will be accepted in exactly this format:

  YYYY-MM-DDTHH:MM:SS+TZ:TZ
  YYYY   - 4-digit year
  MM     - 2-digit month (zero padded)
  DD     - 2-digit year (zero padded)
  T      - literal character 'T'
  HH     - 2-digit hour (24-hour, zero padded)
  SS     - 2-digit second (zero padded)
  +TZ:TZ - Timezone offset (hours and minutes from GMT, 2-digit, zero padded)

=item epoch time

Seconds since the epoch, such as would be returned from time().  If you provide
an epoch time, then an appropriate ISO8601 time will be constructed with
gmtime() (which means the timezone offset will be +00:00).  If anyone knows
of a way to determine the timezone offset of the current host that is
cross-platform and doesn't add dozens of dependencies then I might change this.

=item an ISO8601 date (YYYY-MM-DD)

A simple date in YYYY-MM-DD format.  The time will be set to 00:00:00+00:00.

=item a L<DateTime> object.

If a L<DateTime> object is provided, then an appropriate timestamp will be
constructed from it.

=item a L<HTTP::Response> object.

If given an L<HTTP::Response> object, the last modified time will be
calculated from whatever time information is available in the response
headers.  Currently this means either the Last-Modified header, or tue
current time - the current_age() calculated by the response object.
This is useful for building web crawlers.

=back

Note that in order to conserve memory, any of these items that you provide
will be converted to a complete ISO8601 time string when they are stored.
This means that if you pass an object to lastmod(), you can't get it back
out.  If anyone actually has a need to get the objects back out, then I
might make a configuration option to store the objects internally.

If you have suggestions for other types of date/time objects or formats
that would be usefule, let me know and I'll consider them.

=cut

sub lastmod {
	my $self = shift;

	return $self->{lastmod} unless @_;

	my $value = shift;
	if(ref($value)) {
		if($value->isa('DateTime')) { # DateTime object
			my($date,$tzoff) = $value->strftime("%Y-%m-%dT%T","%z");
			if($tzoff =~ /^([+-])?(\d\d):?(\d\d)/) {
				$tzoff = ($1 || '+').$2.':'.($3||'00');
			} else {
				$tzoff = '+00:00';
			}
			$self->{lastmod} = $date.$tzoff;
		} elsif($value->isa('HTTP::Response')) {
			my $modtime = $value->last_modified()
				|| (time - $value->current_age());
			$self->{lastmod} = strftime("%Y-%m-%dT%T+00:00",gmtime($_));
		}
	} else {
		local $_ = $value;
		if(/^\d+$/) { # epoch time
			$self->{lastmod} = strftime("%Y-%m-%dT%T+00:00",gmtime($_));
		} elsif(/^\d\d\d\d-\d\d-\d\d$/) {
			$self->{lastmod} = $_.'T00:00:00+00:00';
		} elsif(/^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\+\d\d:\d\d$/) {
			$self->{lastmod} = $_;
		}
	}

	return $self->{lastmod} if $self->{lastmod};
	$self->_err("'$_' is not a valid value for lastmod");
}

=item priority()

Set the priority.  This field is not used in sitemap indexes, only in sitemaps.

=cut

sub priority {
	shift->_doval('priority', sub {
		local $_ = shift;
		return unless defined;
		return 'must be a number' unless /^[\d\.]+$/;
		return 'must be greater than 0.0' unless $_ >= 0.0;
		return 'must be less than 1.0' unless $_ <= 1.0;
		return;
	}, @_);
}

sub _doval {
	my $self = shift;
	my $var = shift;
	my $valid = shift;
	return $self->{$var} unless @_;
	my $value = shift;
	if(my $res = $valid->($value)) {
		my $msg = "'$value' is not a valid value for $var: $res";
		if($self->{lenient}) { carp $msg } else { croak $msg }
	} else {
		$self->{$var} = $value;
	}
}
sub _err {
	my $self = shift;

	if($self->{lenient}) { carp @_ } else { croak @_ }
}


=item delete()

Delete this object from the sitemap or the sitemap index.

=cut

sub delete {
	my $self = shift;
	for(keys %{$self}) { $self->{$_} = undef }
}

=item lenient()

If lenient contains a true value, then errors will not be fatal.

=cut

sub lenient {
	my $self = shift;
	$self->{lenient} = shift if @_;
	return $self->{lenient};
}

sub as_elt {
	my $self = shift;
	my $type = shift || 'url';
	my @fields = @_;
	unless(@fields) { @fields = qw(loc changefreq lastmod priority) }
	my @elements = ();
	foreach(@fields) {
		my $val = $self->$_() || next;
        if($_ eq 'loc') {
            $val = XML::Twig::Elt->new('#PCDATA' => encode_entities($val));
            $val->set_asis(1);
        } else {
            $val = XML::Twig::Elt->new('#PCDATA' => $val);
        }
        push(@elements,$val->wrap_in($_));
	}
	return XML::Twig::Elt->new($type, {}, @elements);
}

=back

=head1 MODULE HOME PAGE

The home page of this module is
L<http://www.jasonkohles.com/software/WWW-Google-SiteMap>.  This is where you
can always find the latest version, development versions, and bug reports.  You
will also find a link there to report bugs.

=head1 SEE ALSO

L<WWW::Google::SiteMap>

L<WWW::Google::SiteMap::Index>

L<WWW::Google::SiteMap::Ping>

L<http://www.jasonkohles.com/software/WWW-Google-SiteMap/>

L<https://www.google.com/webmasters/sitemaps/docs/en/protocol.html>

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
