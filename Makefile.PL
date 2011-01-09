use inc::Module::Install;

name           'App-Spiritbutter';
all_from       'lib/App/Spiritbutter.pm';

requires       'XML::Parser';
requires       'Template';
requires       'JSON';

install_script 'scripts/spiritbutter';

WriteAll;

