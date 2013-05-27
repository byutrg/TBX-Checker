package TBX::Checker;
use strict;
use warnings;
use autodie;
use File::ShareDir 'dist_dir';
use Exporter::Easy (
	OK => [ qw(check) ],
);
use Path::Tiny;
use Carp;
use feature 'state';
use Capture::Tiny 'capture_merged';
# VERSION

my $TBXCHECKER = path( dist_dir('TBX-Checker'),'tbxcheck-1.2.9.jar' );

# ABSTRACT: Check TBX validity using TBXChecker
=head1 SYNOPSIS

	use TBX::Checker qw(check);
	my ($passed, $messages) = check('/path/to/file.tbx');
	$passed && print 'ok!'
		or print join (qq{\n}, @$messages);

=head1 DESCRIPTION

This modules allows you to use the Java TBXChecker utility from Perl.
It has one function, C<check> which returns the errors found by the
TBXChecker (hopefully none!).

=cut

#When run as a script instead of used as a module: check the input file and print the results
_run(@ARGV) unless caller;
sub _run {
	my ($tbx) = @_;
	my ($passed, $messages) = check($tbx);
	($passed && print 'ok!')
		or print join (qq{\n}, @$messages);
	return;
}

=head1 METHODS

=head2 C<check>

Checks the validity of the given TBX file. Returns 2 elements: a
boolean representing the validity of the input TBX, and an array reference
containing messages returned by TBXChecker.

Arguments: file to be checked, followed by named arguments accepted by TBXChecker.
For example: C<check('file.tbx', loglevel => 'ALL')>. The allowed parameters are listed below:

    loglevel      Increase level of output while processing.
                         OFF     => Error code only.
                         SEVERE  => Error code only.
                         WARNING => Valid or invalid message (default).
                         INFO    => Location of files used in processing.
                         CONFIG  => .
                         FINE    => .
                         FINER   => .
                         FINEST  => .
                         ALL     => All logging messages.
    lang           ISO-639 lowercase two-letter language code.
    country      ISO-3166 uppercase two-letter country code.
    variant
    system       System ID to use for relative paths in document.
                         Default: Uses the directory where the file is located.
    version       Displays version information and quits.
    environment    Adds the environmental conditions on startup to the messages.

=cut

sub check {
	my @args = @_;
	my $command = _process_args(@args);

	# capture STDOUT and STDERR from jar call into $output
	my ($output, $result) = capture_merged {system($command)};
	my @messages = split /\v+/, $output;
	my $valid = _is_valid(\@messages);
	return ($valid, \@messages);
}

#process arguments and return the command to be run
sub _process_args {
	my ($file, %args) = @_;
	#check the parameters. TODO: use a module or something for param checking
	croak 'missing file argument. Usage: TBX::Checker::check($file, %args)'
		unless $file;
	croak "$file doesn't exist!"
		unless -e $file;
	state $allowed_params = [ qw(
		loglevel lang country variant system version environment) ];
	foreach my $param (keys %args){
		croak "unknown paramter: $param"
			unless grep { $_ eq $param } @$allowed_params;
	}
	state $allowed_levels = [ qw(
		OFF SEVERE WARNING INFO CONFIG FINE FINER FINEST ALL) ];
	if(exists $args{loglevel}){
		grep { $_ eq $args{loglevel} } @$allowed_levels
			or croak "Loglevel doesn't exist: $args{loglevel}";
	}
	$args{loglevel} ||= q{OFF};
	#due to TBXChecker bug, file must be relative to cwd
	$file = path($file)->relative;

	#shell out to the jar with the given arguments.
	my $arg_string = join q{ }, map {"--$_=$args{$_}"} keys %args;
	my $command = qq{java -cp ".;$TBXCHECKER" org.ttt.salt.Main $arg_string "$file"};
	return $command;
}

#return a boolean indicating the validity of the file, given the messages
#remove the message indicating that the file is valid (if it exists)
sub _is_valid {
	my ($messages) = @_;
	#locate index of "Valid file:" message
	my $index = 0;
	while($index < @$messages){
		last if $$messages[$index] =~ /^Valid file: /;
		$index++;
	}
	#if message not found, file was invalid
	if($index > $#$messages){
		return 0;
	}
	#remove message and return true
	splice(@$messages, $index, 1);
	return 1;
}

1;

=head1 SEE ALSO

The TBXChecker project is located on SourceForge in a
project called L<tbxutil|http://sourceforge.net/projects/tbxutil/>.