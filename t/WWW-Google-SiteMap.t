use Test::More tests => 6;
BEGIN { use_ok('WWW::Google::SiteMap') };

my $baseurl = "http://www.jasonkohles.com/software/WWW-Google-SiteMap";

my $map;
ok($map = WWW::Google::SiteMap->new(file => 'test.xml', pretty => 'indented'));
isa_ok($map,'WWW::Google::SiteMap');
ok($map->add(WWW::Google::SiteMap::URL->new(
	loc			=> "$baseurl/test1",
	lastmod		=> '2005-06-03',
	changefreq	=> 'daily',
	priority	=> 1,
)));
ok($map->add(
	loc			=> "$baseurl/test2",
	lastmod		=> '2005-07-11',
	changefreq	=> 'weekly',
	priority	=> 0.1,
));

ok($map->write());

#eval "use XML::LibXML";
#my $HAVE_libxml = $XML::LibXML::VERSION;
#SKIP: {
#	skip "Need XML::LibXML for these tests", 1 unless $HAVE_libxml;
#	eval {
#		my $parser = XML::LibXML->new;
#		$parser->validation(1);
#		$parser->parse_file('test.xml');
#	};
#	ok(!$@,"test.xml validated with XML::LibXML");
#};
