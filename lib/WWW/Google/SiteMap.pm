package WWW::Google::SiteMap;
our $VERSION = '1.00';

=head1 NAME

WWW::Google::SiteMap - Perl extension for managing Google SiteMaps

=head1 SYNOPSIS

  use WWW::Google::SiteMap;

  my $map = WWW::Google::SiteMap->new(file => 'sitemap.gz');

  # Main page, changes a lot because of the blog
  $map->add(WWW::Google::SiteMap::URL->new(
    loc        => 'http://www.jasonkohles.com/',
    lastmod    => '2005-06-03',
    changefreq => 'daily',
    priority   => 1.0,
  ));

  # Top level directories, don't change as much, and have a lower priority
  $map->add({
    loc        => "http://www.jasonkohles.com/$_/",
    changefreq => 'weekly',
    priority   => 0.9, # lower priority than the home page
  ) for qw(
    software gpg hamradio photos scuba snippets tools
  );

  $map->write;

=head1 DESCRIPTION

The Sitemap Protocol allows you to inform search engine crawlers about URLs
on your Web sites that are available for crawling. A Sitemap consists of a
list of URLs and may also contain additional information about those URLs,
such as when they were last modified, how frequently they change, etc.

This module allows you to create and modify sitemaps.

=cut

use strict;
use warnings;
use WWW::Google::SiteMap::URL qw();
use XML::Twig qw();
unless($IO::Zlib::VERSION) { eval "use IO::Zlib ()"; }
my $ZLIB = $IO::Zlib::VERSION;
use IO::File qw();
require UNIVERSAL;
use Carp qw(carp croak);

=head1 METHODS

=over 4


=item new()

Creates a new WWW::Google::SiteMap object.

  my $map = WWW::Google::SiteMap->new(
    file => 'sitemap.gz',
  );

=cut

sub new {
	my $class = shift;
	my %opts = @_;
	my $self = bless({}, ref($class) || $class);
	while(my($key,$value) = each %opts) { $self->$key($value) }
	if($self->file && -e $self->file) { $self->read }
	return $self;
}

=item read()

Read a sitemap in to this object.  If a filename is specified, it will be
read from that file, otherwise it will be read from the file that was
specified with the file() method.  Reading of compressed files is done
automatically if the filename ends with .gz.

=cut

sub read {
	my $self = shift;
	my $file = shift || $self->file ||
		croak "No filename specified for ".(ref($self)||$self)."::read";

	# don't try to parse missing or empty files
	# no errors for this, because we might be creating it
	return unless -f $file && -s $file;
	
	# don't try to parse very small compressed files
	# (empty .gz files are 20 bytes)
	return if $file =~ /\.gz/ && -s $file < 50;

	my $fh;
	if($file =~ /\.gz$/i) {
		croak "IO::Zlib not available, cannot read compressed sitemaps"
			unless $ZLIB;
		$fh = IO::Zlib->new($file,"rb");
	} else {
		$fh = IO::File->new($file,"r");
	}
	my @urls = ();
	my $urlparser = sub {
		my $self = shift;
		my $elt = shift;

		my $url = WWW::Google::SiteMap::URL->new();
		foreach my $c ($elt->children) {
			my $var = $c->gi; $url->$var($c->text);
		}
		$self->purge;
		push(@urls,$url);
	};
	my $twig = XML::Twig->new(
		twig_roots => {
			'urlset/url'				=> $urlparser,
			'sitemapindex/sitemap'		=> $urlparser,
		},
	);
	$twig->safe_parse(join('',$fh->getlines)) || die "Could not parse $file";
	$self->urls(@urls);
}

=item write([$file])

Write the sitemap out to the file.  If a filename is specified, it will be
written to that file, otherwise it will be written to the file that was
specified with the file() method.  Writing of compressed files is done
automatically if the filename ends with .gz.

=cut

sub write {
	my $self = shift;
	my $file = shift || $self->file ||
		croak "No filename specified for ".(ref($self)||$self)."::write";

	my $fh;
	if($file =~ /\.gz$/i) {
		croak "IO::Zlib not available, cannot write compressed sitemaps"
			unless $ZLIB;
		$fh = IO::Zlib->new($file,"wb9");
	} else {
		$fh = IO::File->new($file,"w");
	}
	croak "Could not create '$file'" unless $fh;
	$fh->print($self->xml);
}

=item urls()

Return the L<WWW::Google::SiteMap::URL> objects that make up the sitemap.

=cut

sub urls {
	my $self = shift;
	$self->{urls} = \@_ if @_;
	my @urls = grep { ref($_) && defined $_->loc } @{$self->{urls}};
	return wantarray ? @urls : \@urls;
}

=item add($item,[$item...])

Add the L<WWW::Google::SiteMap::URL> items listed to the sitemap.

If you pass hashrefs instead of L<WWW::Google::SiteMap::URL> objects, it
will turn them into objects for you.  If the first item you pass is a
simple scalar that matches \w, it will assume that the values passed are
a hash for a single object.  If the first item passed matches m{^\w+://}
(i.e. it looks like a URL) then all the arguments will be treated as URLs,
and L<WWW::Google::SiteMap::URL> objects will be constructed for them, but only
the loc field will be populated.

This means you can do any of these:

  # create the WWW::Google::SiteMap::URL object yourself
  my $url = WWW::Google::SiteMap::URL->new(
    loc => 'http://www.jasonkohles.com/',
    priority => 1.0,
  );
  $map->add($url);

  # or
  $map->add(
    { loc => 'http://www.jasonkohles.com/' },
    { loc => 'http://www.jasonkohles.com/software/google-sitemap/' },
    { loc => 'http://www.jasonkohles.com/software/geo-shapefile/' },
  );

  # or
  $map->add(
    loc       => 'http://www.jasonkohles.com/',
    priority  => 1.0,
  );

  # or even something funkier
  $map->add(qw(
    http://www.jasonkohles.com/
    http://www.jasonkohles.com/software/www-google-sitemap/
    http://www.jasonkohles.com/software/geo-shapefile/
    http://www.jasonkohles.com/software/text-fakedata/
  ));
  foreach my $url ($map->urls) { $url->changefreq('daily') }
    
=cut

sub add {
	my $self = shift;
	if(ref($_[0])) {
		if(UNIVERSAL::isa($_[0],"WWW::Google::SiteMap::URL")) {
			push(@{$self->{urls}}, @_);
		} elsif(ref($_[0]) =~ /HASH/) {
			push(@{$self->{urls}},map {
				WWW::Google::SiteMap::URL->new($_)
			} @_);
		}
	} elsif($_[0] =~ /^\w+$/) {
		push(@{$self->{urls}}, WWW::Google::SiteMap::URL->new(@_));
	} elsif($_[0] =~ m{^\w+://}) {
		push(@{$self->{urls}}, map {
			WWW::Google::SiteMap::URL->new(loc => $_)
		} @_);
	} else {
		croak "Can't turn '".(
			ref($_[0]) || $_[0]
		)."' into WWW::Google::SiteMap::URL object";
	}
}

=item xml();

Return the xml representation of the sitemap.

=cut

sub xml {
	my $self = shift;

	my $xml = XML::Twig::Elt->new('urlset', {
		'xmlns'	=> 'http://www.google.com/schemas/sitemap/0.84',
		'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
		'xsi:schemaLocation' => join(' ',
			'http://www.google.com/schemas/sitemap/0.84',
			'http://www.google.com/schemas/sitemap/0.84/sitemap.xsd',
		),
	});
	foreach($self->urls) {
		$_->as_elt->paste(last_child => $xml);
	}
	$xml->set_pretty_print($self->pretty);
	return $xml->sprint();
}

=item file()

Get or set the filename associated with this object.  If you call read() or
write() without a filename, this is the default.

=cut

sub file {
	my $self = shift;
	$self->{file} = shift if @_;
	return $self->{file};
}

=item pretty()

Set this to a true value to enable 'pretty-printing' on the XML output.  If
false (the default) the XML will be more compact but not as easily readable
for humans (Google and other computers won't care what you set this to).

If you set this to a 'word' (something that matches /[a-z]/i), then that
value will be passed to XML::Twig directly (see the L<XML::Twig> pretty_print
documentation).  Otherwise if a true value is passed, it means 'nice', and a
false value means 'none'.

Returns the value it was set to, or the current value if called with no
arguments.

=cut

sub pretty {
	my $self = shift;
	my $val = shift || return $self->{pretty} || 'none';

	if($val =~ /[a-z]/i) {
		$self->{pretty} = $val;
	} elsif($val) {
		$self->{pretty} = 'nice';
	} else {
		$self->{pretty} = 'none';
	}
	return $self->{pretty};
}

=back

=head1 SEE ALSO

L<WWW::Google::SiteMap::Index>

L<WWW::Google::SiteMap::Ping>

L<WWW::Google::SiteMap::Robot>

L<http://www.jasonkohles.com/software/WWW-Google-SiteMap>

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
