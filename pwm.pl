#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use Password::Manager;

my $opt = {};
GetOptions( $opt, 'new|n=s', 'delete|d=s', 'encrypt|e', 'section|s=s',
    'list|l' );

$opt->{service} = join( '', @ARGV );

my $config = {
    dir     => "$ENV{'HOME'}/.password",
    encrypt => 0,
};

unless ( -e "$ENV{HOME}/.pwm.conf" ) {
    open( FILE, ">$ENV{HOME}/.pwm.conf" ) or die $!;
    binmode( FILE, ":utf8" );
    foreach ( keys($config) ) {
        print FILE "$_ $config->{$_}\n";
    }
    close(FILE);
}
else {
    open( FILE, "<$ENV{HOME}/.pwm.conf" ) or die $!;
    binmode( FILE, ":utf8" );
    while (<FILE>) {
        if ( $_ =~ /^(.*) (.*)$/ ) {
            $config->{$1} = $2;
        }
    }
    close(FILE);
}

$config->{encrypt} = $opt->{encrypt} ? 1 : 0;

my $pwm = Password::Manager->new($config);

if ( $opt->{new} && $opt->{service} ) {
    print("Please enter password: \n");

    system( '/usr/bin/stty', '-echo' );
    my $password = <STDIN>;

    system( '/usr/bin/stty', 'echo' );
    print("Please repeat password: \n");

    system( '/usr/bin/stty', '-echo' );
    my $password2 = <STDIN>;

    system( '/usr/bin/stty', 'echo' );

    if ( $password eq $password2 ) {
        chomp($password);
        my $section = $opt->{section} ? $opt->{section} : '';
        $pwm->add_credentials( $opt->{service}, $opt->{new}, $password,
            $section );
    }
    else {
        print("Error: passwords don't match\n");
    }

}
elsif ( $opt->{delete} && $opt->{service} ) {
    my $section = $opt->{section} ? $opt->{section} : '';
    $pwm->del_credentials( $opt->{service}, $opt->{delete}, $section );
}
elsif ( $opt->{service} ) {
    my $section = $opt->{section} ? $opt->{section} : '';
    $pwm->print_credentials( $opt->{service}, $section );
}
else {
    $pwm->list_services();
}
