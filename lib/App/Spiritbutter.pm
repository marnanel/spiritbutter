package App::Spiritbutter;

use strict;
use warnings;

use App::Spiritbutter::Parser;
use App::Spiritbutter::Skin;
use File::Basename;
use File::Slurp;

sub details_of {
    my ($filename, $parser) = @_;
    my $base = basename($filename);

    return ( action=> 'ignore' ) if $base =~ /^_/;

    my %result;
    my %content = $parser->content();
    
    my ($path, $stub) = $filename =~ m{^(.*)/+[^/]+/+([^/]*)$};

    # FIXME: Should not match doubled underscores
    $stub =~ s/_/\//g;

    if ($stub =~ /\.sb\.xml$/) {
        $result{'parsed'} = 1;
        $stub =~ s/\.sb\.xml$/.html/;
    }

    $result{'target'} = "$path/$stub";

    if (!$result{'parsed'} &&
        -e $result{'target'} &&
        -M $result{'target'} > -M $filename) {
        $result{'uptodate'} = 1;
    } else {
        $result{'uptodate'} = 0;
    }

    if ($result{'uptodate'}) {
        $result{'action'} = 'ignore';
    } elsif ($result{'parsed'}) {
        $result{'action'} = 'interpret';
    } else {
        $result{'action'} = 'copy';
    }

    if ($result{'parsed'}) {

        # It asked to be parsed, so let's parse it.

        die "No content found for $stub" unless $content{$stub};

        %result = (
            %{$content{$stub}},
            toplinks => $parser->toplinks(),
            %result,
        );

        if ($result{'link'} && $result{'action'} eq 'interpret') {
            # it's not a real page, just a link
            $result{'action'} = 'ignore';
            delete $result{'target'};
        }

        if ($result{'body'} && !$result{'link'}) {
            # For planned expansion
            $result{'body'} = [['text', $result{'body'}]];
        }
    }

    return %result;
}

sub look_up_site {
    my ($wanted) = @_;

    # FIXME: there is probably a better way to look up
    # XDG directory names
    my $filename = "$ENV{HOME}/.config/spiritbutter/sites";
    return undef unless -e $filename;

    my $result;
    open SITES, "<$filename" or die "$!";
    while (<SITES>) {
        my ($site, $dir) = m/^(.*?)=(.*)$/;
        if (defined $site && defined $dir && $site eq $wanted) {
            $result = $dir;
            last;
        }
    }
    close SITES or die "$!";
    return $result;
}

sub handle {
    my $dir = $ARGV[0];

    die "Please give the name of a site\n" unless $dir;
    if (!-d $dir) {
        $dir = look_up_site($dir);
        die "That is neither a directory nor a known site\n" unless $dir;
    }

    $dir =~ s,/$,, if $dir ne '/';

    my $template = "$dir/_skin.tt2";
    die "Template $template not found" unless -e $template;

    my $parser = App::Spiritbutter::Parser->new($dir);
    my $skin = App::Spiritbutter::Skin->new($template);
    my @files = glob("$dir/*");

    for my $file (@files) {
        next if $file =~ /~$/;
        my %details = details_of($file, $parser);

        if ($details{'action'} eq 'ignore') {
            # ignore it
        } elsif ($details{'action'} eq 'interpret') {
            print "$details{target}\n";
            open OUT, ">$details{target}" or die "Can't open $details{target}: $!";
            binmode OUT, ":utf8";
            print OUT $skin->skin(\%details);
            close OUT or die "Can't close $details{target}: $!";
        } elsif ($details{'action'} eq 'copy') {
            my $content = read_file($file);
            write_file($details{'target'}, $content);
        } else {
            die "Unknown action on $file: $details{'action'}";
        }
    }
}

1;
