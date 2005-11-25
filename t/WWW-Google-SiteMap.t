use Test::More tests => 1;
BEGIN { use_ok('WWW::Google::SiteMap') };

my $baseurl = "http://www.jasonkohles.com/software/WWW-Google-SiteMap";

my $map = WWW::Google::SiteMap->new(file => 'test.xml', pretty => 'indented');
$map->add(WWW::Google::SiteMap::URL->new(
	loc			=> "$baseurl/test1",
	lastmod		=> '2005-06-03',
	changefreq	=> 'daily',
	priority	=> 1,
));
$map->add(
	loc			=> "$baseurl/test2",
	lastmod		=> '2005-07-11',
	changefreq	=> 'weekly',
	priority	=> 0.1,
);

$map->write();
