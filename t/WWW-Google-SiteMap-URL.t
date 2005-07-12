use Test::More tests => 1;
BEGIN { use_ok('WWW::Google::SiteMap::URL') };

my $url = WWW::Google::SiteMap::URL->new();
