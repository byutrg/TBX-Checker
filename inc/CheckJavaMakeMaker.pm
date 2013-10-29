package inc::CheckJavaMakeMaker;
use Moose;
#writes a simple check that the computer has Java available
# most of this is from DZP:MakeMaker::Awesome documentation

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';
around _build_MakeFile_PL_template => sub {
    my $orig = shift;
    my $self = shift;

    my $NEW_CONTENT = <<'END';
    #Jing requires Java 4 or higher
    #Java outputs to STDERR on Windows, STDOUT on others
    my $java_version = `java -version 2>&1`;
    $java_version =~ m/java version "(.\..)[^"]+"/;
    print $java_version;
    return 0 unless $1 >= 1.4;
END

    # insert new content near the beginning of the file, preserving the
    # preamble header
    my $string = $self->$orig(@_);
    $string =~ m/use warnings;\n\n/g;
    return substr($string, 0, pos($string)) . $NEW_CONTENT . substr($string, pos($string));
};

__PACKAGE__->meta->make_immutable;