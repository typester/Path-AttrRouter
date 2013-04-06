use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
$ENV{LANG} = 'C';
add_stopwords(<DATA>);
set_spell_cmd("aspell -l en list");
all_pod_files_spelling_ok('lib');
__DATA__
Daisuke
Murase
KAYAC
CGI
eg
namespace
