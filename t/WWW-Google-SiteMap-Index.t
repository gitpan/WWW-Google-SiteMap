use Test::More tests => 1;
BEGIN { use_ok('WWW::Google::SiteMap::Index') };

my $baseurl = "http://www.example.com";

my $index = WWW::Google::SiteMap::Index->new(
	file	=> 'test-index.xml',
	pretty	=> 'indented',
);
$index->add(WWW::Google::SiteMap::URL->new(
	loc			=> "$baseurl/test-sitemap-1.gz",
	lastmod		=> '2005-06-03',
));
$index->add(
	loc			=> "$baseurl/test-sitemap-2.gz",
	lastmod		=> '2005-07-11',
);

$index->write();
