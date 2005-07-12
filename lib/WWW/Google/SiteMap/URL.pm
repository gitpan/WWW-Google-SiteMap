package WWW::Google::SiteMap::URL;
our $VERSION = '0.03';

=head1 NAME

WWW::Google::SiteMap::URL - URL Helper class for WWW::Google::SiteMap

=head1 SYNOPSIS

  use WWW::Google::SiteMap;

=head1 DESCRIPTION

This is a helper class that supports L<WWW::Google::SiteMap>.

=head1 METHODS

=over 4

=cut

use strict;
use warnings;
use Carp qw(carp croak);
use XML::Twig qw();

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

Change the URL associated with this object.

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

Set the change frequency of the object.

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

Set the last modified time.

=cut

sub lastmod {
	shift->_doval('lastmod', sub {
		local $_ = shift;
		return unless defined;
		return 'must be an ISO-8601 formatted date string' unless (
			/^\d{4}-\d{2}-\d{2}(T\d\d:\d\d:\d\d\+\d\d:\d\d)?$/
		);
		return;
	}, @_);
}

=item priority()

Set the priority.

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

=item delete()

Delete this object from the sitemap.

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
	my $twig = shift;
	return XML::Twig::Elt->new('url', {}, map {
		XML::Twig::Elt->new($_,{},$self->{$_})
	} grep { defined $self->{$_} } qw(loc changefreq lastmod priority));
}

=back

=head1 SEE ALSO

L<http://www.jasonkohles.com/software/www-google-sitemap/>

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
