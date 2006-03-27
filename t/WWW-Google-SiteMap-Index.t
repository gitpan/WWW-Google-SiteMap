use Test::More tests => 6;
BEGIN {
    unlink("test-index.xml");
    use_ok('WWW::Google::SiteMap::Index');
};

my $baseurl = "http://www.example.com";

my $index;
ok($index = WWW::Google::SiteMap::Index->new(
	file	=> 'test-index.xml',
	pretty	=> 'indented',
));
isa_ok($index,'WWW::Google::SiteMap::Index');
ok($index->add(WWW::Google::SiteMap::URL->new(
	loc			=> "$baseurl/test-sitemap-1.gz",
	lastmod		=> '2005-06-03',
)));
ok($index->add(
	loc			=> "$baseurl/test-sitemap-2.gz",
	lastmod		=> '2005-07-11',
));

ok($index->write());
