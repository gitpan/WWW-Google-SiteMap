package WWW::Google::SiteMap::Index;
use vars qw($VERSION); $VERSION = '1.08';

=head1 NAME

WWW::Google::SiteMap::Index - Perl extension for managing Google SiteMap Indexes

=head1 SYNOPSIS

  use WWW::Google::SiteMap::Index;
  
  my $index = WWW::Google::SiteMap::Index->new(
    file => 'sitemap-index.gz',
  );
  
  $index->add(WWW::Google::SiteMap::URL->new(
    loc     => 'http://www.jasonkohles.com/sitemap1.gz',
    lastmod => '2005-11-01',
  ));
  
=head1 DESCRIPTION

A sitemap index is used to point Google at your sitemaps if you have more
than one of them.

=cut

use strict;
use warnings;
use base 'WWW::Google::SiteMap';

=head1 METHODS

=over 4

=item new()

Creates a new WWW::Google::SiteMap::Index object.

  my $index = WWW::Google::SiteMap::Index->new(
    file => 'sitemap-index.gz',
  );

=item read()

Read a sitemap index in to this object.  If a filename is specified, it will
be read from that file, otherwise it will be read from the file that was
specified with the file() method.  Reading of compressed files is done
automatically if the filename ends with .gz.

=item write([$file]);

Write the sitemap index out to the file.  If a filename is specified, it will
be written to that file, otherwise it will be written to the file that was
specified with the file() method.  Writing of compressed files is done
automatically if the filename ends with .gz

=item urls()

Return the L<WWW::Google::SiteMap::URL> objects that make up the sitemap index.

=item add($item,[$item...]);

Add the L<WWW::Google::SiteMap::URL> items listed to the sitemap index.

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
    loc => 'http://www.jasonkohles.com/sitemap1.gz',
  );
  $map->add($url);
  
  # or
  $map->add(
    { loc => 'http://www.jasonkohles.com/sitemap1.gz' },
    { loc => 'http://www.jasonkohles.com/sitemap2.gz' },
    { loc => 'http://www.jasonkohles.com/sitemap3.gz' },
  );
  
  # or
  $map->add(
    loc       => 'http://www.jasonkohles.com/sitemap1.gz',
    priority  => 1.0,
  );
  
  # or even something funkier
  $map->add(qw(
    http://www.jasonkohles.com/
    http://www.jasonkohles.com/software/www-google-sitemap/
    http://www.jasonkohles.com/software/geo-shapefile/
    http://www.jasonkohles.com/software/text-fakedata/
  ));
  foreach my $url ($map->urls) { $url->lastmod('2005-11-01') }

=item xml();

Return the xml representation of the sitemap index.

=cut

sub xml {
	my $self = shift;

	my $xml = XML::Twig::Elt->new('sitemapindex', {
		'xmlns' => 'http://www.google.com/schemas/sitemap/0.84',
		'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
		'xsi:schemaLocation' => join(' ',
			'http://www.google.com/schemas/sitemap/0.84',
			'http://www.google.com/schemas/sitemap/0.84/siteindex.xsd',
		),
	});
	foreach($self->urls) {
		$_->as_elt('sitemap',qw(loc lastmod))->paste(last_child => $xml);
	}
	$xml->set_pretty_print($self->pretty);
	my $header = '<?xml version="1.0" encoding="UTF-8"?>';
	if($self->pretty) { $header .= "\n" }
	return $header.$xml->sprint();
}

=item file();

Get or set the filename associated with this object.  If you call read() or
write() without a filename, this is the default.

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

=back

=head1 MODULE HOME PAGE

The home page of this module is
L<http://www.jasonkohles.com/software/WWW-Google-SiteMap>.  This is where you
can always find the latest version, development versions, and bug reports.  You
will also find a link there to report bugs.

=head1 SEE ALSO

L<WWW::Google::SiteMap>

L<WWW::Google::SiteMap::Ping>

L<http://www.jasonkohles.com/software/WWW-Google-Sitemap>

L<https://www.google.com/webmasters/sitemaps/docs/en/protocol.html#sitemapFileRequirements>

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
