use inc::Module::Install;

name 'WWW-Google-SiteMap';
license 'perl';
all_from 'lib/WWW/Google/SiteMap.pm';
requires 'XML::Twig';
requires 'IO::File';
requires 'Carp';
requires 'POSIX';
requires 'URI::Escape';
recommends 'IO::Zlib';
recommends 'LWP::UserAgent';
recommends 'WWW::Mechanize';
recommends 'WWW::RobotRules';

auto_install;
WriteAll;

# TODO - Module::Signature
