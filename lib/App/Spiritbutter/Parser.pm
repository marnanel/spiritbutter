package App::Spiritbutter::Parser;

use strict;
use warnings;
use XML::Parser;

sub _filename_to_page {
    my ($self, $filename) = @_;

    $filename =~ s/^(.*)\///;
    $filename =~ s/\.sb\.xml$/.html/;
    $filename =~ s/_(?!_)/\//g;
    $filename =~ s/__/_/g;
    return $filename;
}

sub _resolve_breadcrumbs {
    my ($pages) = @_;

    my $unresolved;
    do {
        $unresolved = 0;
        my $changes = 0;
        for my $name (keys %$pages) {
            my $parent = $pages->{$name}->{'parent'};
            my $title = $pages->{$name}->{'title'};
            $title = $name unless $title;

            if (defined $pages->{$name}->{'breadcrumbs'}) {
                # ignore: we've already done it
            } elsif (!$parent) {
                # easy, no parent
                $pages->{$name}->{'breadcrumbs'} = [$title, $name];
                $changes++;
            } elsif ($pages->{"$parent.html"}->{'breadcrumbs'}) {
                $pages->{$name}->{'breadcrumbs'} = [ @{$pages->{"$parent.html"}->{'breadcrumbs'}}, $title, $name ];
                $changes++;
            } else {
                $unresolved++;
            }
        }

        # FIXME: this isn't very helpful for debugging
        die "Parent links are inconsistent" unless $changes;
    } while ($unresolved!=0);
}

sub new {
    my ($class, $filename) = @_;

    if (-d $filename) {
        my %result;

        for my $found (glob("$filename/*.sb.xml")) {
            my $singleton = $class->new($found);

            my @k = keys(%$singleton);

            die "multiple keys returned for a single file: ".scalar(@k) unless scalar(@k)==1;

            $result{$class->_filename_to_page($found)} = $singleton->{$k[0]};
        }

        die "No *.sb.xml files found in $filename" unless %result;

        _resolve_breadcrumbs(\%result);

        return bless \%result, $class;

    } elsif (-f $filename) {

        my %result;

        # if we're inside an <sb:body> tag
        my $in_body = 0;

        # if we have JUST seen an open tag
        # (so that a close tag should modify it)
        my $open_and_shut = 0;

        my $p = new XML::Parser(Handlers => {
                Start => sub {
                    my ($parser, $tag, @attrs) = @_;

                    if ($tag eq 'sb:field') {
                        my %attrs = @attrs;

                        die "<sb:field> needs a name attribute" unless defined $attrs{'name'};
                        die "<sb:field> needs a value attribute" unless defined $attrs{'value'};

                        $result{$attrs{'name'}} = $attrs{'value'};

                    } elsif ($tag eq 'sb:body') {
                        $in_body = 1;
                        $result{'body'} = '';
                    } elsif ($in_body) {
                        $result{'body'} .= "<$tag";

                        while (@attrs) {
                            my $field = shift @attrs;
                            my $value = shift @attrs;
                            $result{'body'} .= " $field=\"$value\"";
                        }
                        $result{'body'} .= ">";
                        $open_and_shut = 1;
                    }
                },
                End   => sub {
                    my ($parser, $tag) = @_;
                    if ($tag eq 'sb:body') {
                        $in_body = 0;
                    } elsif ($in_body) {
                        if ($open_and_shut) {
                            $result{'body'} =~ s/>$/\/>/;
                            $open_and_shut = 0;
                        } else {
                            $result{'body'} .= "</$tag>";
                        }
                    }
                },
                Char  => sub {
                    my ($parser, $text) = @_;

                    if ($in_body) {
                        $result{'body'} .= $text;
                        $open_and_shut = 0;
                    }
                }});

        $p->parsefile($filename);

        my @stat = stat($filename);
        if ($result{'date'}) {
            die "can't yet parse supplied dates";
        } else {
            $result{'date'} = $stat[9];
        }
        $result{'filedate'} = $stat[9];

        return bless {
            $class->_filename_to_page($filename) => \%result,
        }, $class;

    } else {
        die "Don't know how to handle $filename";
    }
}

sub toplinks {
    my ($self) = @_;

    my @temp;

    for my $k (keys %$self) {
       next unless defined $self->{$k}->{'toplink'};

       my $href = "/$k";
       $href = $self->{$k}->{'body'} if $self->{$k}->{'link'};

       $href =~ s/\/index.html$/\//;

       push @temp, {
           name => $self->{$k}->{'title'},
           href => $href,
           toplink => $self->{$k}->{'toplink'},
       };
    }

    @temp = sort { $a->{'toplink'} cmp $b->{'toplink'} } @temp;

    for my $t (@temp) {
        delete $t->{'toplink'};
    }

    return \@temp;
}

sub content {
    my ($self) = @_;

    return %$self;
}

1;

