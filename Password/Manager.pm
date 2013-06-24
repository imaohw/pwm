package Password::Manager;

use strict;
use warnings;

use File::Path qw(make_path);

use Password::Manager::Storage;

sub new {
    my $class  = shift;
    my $config = shift;

    my $self = { config => $config };

    make_path( $self->{config}->{dir} );
    bless( $self, $class );

    return $self;
}

sub add_credentials {
    my $self = shift;

    my $service  = shift;
    my $username = shift;
    my $password = shift;
    my $section  = shift;

    my $storage
        = Password::Manager::Storage->new(
        "$self->{config}->{dir}/$service.txt",
        $self->{config}->{encrypt} );

    $storage->add_credentials( $username, $password, $section );
}

sub copy_value_to_clipboard {
    my $self = shift;

    my $service = shift;
    my $section = shift;
    my $key     = shift;

    my $storage
        = Password::Manager::Storage->new(
        "$self->{config}->{dir}/$service.txt",
        $self->{config}->{encrypt} );

    $storage->copy_value_to_clipboard( $section, $key );
}

sub del_credentials {
    my $self     = shift;
    my $service  = shift;
    my $username = shift;
    my $section  = shift;

    my $storage
        = Password::Manager::Storage->new(
        "$self->{config}->{dir}/$service.txt",
        $self->{config}->{encrypt} );

    $storage->del_credentials( $username, $section );
}

sub list_services {
    my $self = shift;

    opendir( DIR, $self->{config}->{dir} ) or die $!;
    my @files = grep { !/^\.\.?$/ } readdir(DIR);
    closedir(DIR);

    foreach ( sort(@files) ) {
        $_ =~ s/.txt$//;
        print("$_\n");
    }
}

sub print_credentials {
    my $self    = shift;
    my $service = shift;
    my $section = shift;

    my $storage
        = Password::Manager::Storage->new(
        "$self->{config}->{dir}/$service.txt",
        $self->{config}->{encrypt} );

    $storage->print_credentials($section);
    $storage->copy_value_to_clipboard( $section, 'password' );
}
1;
