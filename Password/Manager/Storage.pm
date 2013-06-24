package Password::Manager::Storage;

use strict;
use warnings;

use Clipboard;
use Password::Manager::Crypto;

sub new {
    my $class   = shift;
    my $file    = shift;
    my $encrypt = shift;

    my $self = {
        file    => $file,
        storage => {},
        encrypt => $encrypt
    };

    bless( $self, $class );
    $self->_parse_file;
    return $self;
}

sub add_credentials {
    my $self     = shift;
    my $username = shift;
    my $password = shift;
    my $section  = shift;

    if ($section) {
        $self->{storage}->{$section}->{username} = $username;
        $self->{storage}->{$section}->{password} = $password;
    }
    else {
        $self->{storage}->{username} = $username;
        $self->{storage}->{password} = $password;
    }

    $self->_write_file;
}

sub copy_value_to_clipboard {
    my $self    = shift;
    my $section = shift;
    my $key     = shift || 'password';

    if ( $section && $self->{storage}->{$section}->{$key} ) {
        Clipboard->copy( $self->{storage}->{$section}->{$key} );
    }
    elsif ( $self->{storage}->{$key} ) {
        Clipboard->copy( $self->{storage}->{$key} );
    }
}

sub del_credentials {
    my $self     = shift;
    my $username = shift;
    my $section  = shift;

    if (   $section
        && $self->{storage}->{$section}
        && $self->{storage}->{$section}->{username} eq $username )
    {
        delete( $self->{storage}->{$section} );
    }
    elsif ( $self->{storage}->{username} eq $username ) {
        delete( $self->{storage}->{username} );
        delete( $self->{storage}->{password} );
    }
    else {
        print("username not found\n");
    }

    $self->_write_file;

    unless ( -s $self->{file} ) {
        unlink( $self->{file} );
    }
}

sub print_credentials {
    my $self    = shift;
    my $section = shift;

    if ( $section && $self->{storage}->{$section} ) {
        print("$section:\n");
        if ( $self->{storage}->{$section}->{username} ) {
            print("    username: $self->{storage}->{$section}->{username}\n");
        }

        if ( $self->{storage}->{$section}->{password} ) {
            print("    password: $self->{storage}->{$section}->{password}\n");
        }

        foreach ( sort( keys( $self->{storage}->{$section} ) ) ) {
            unless ( $_ eq 'username' || $_ eq 'password' ) {
                print("    $_: $self->{storage}->{$section}->{$_}\n");
            }
        }
    }
    else {
        if ( $self->{storage}->{username} ) {
            print("username: $self->{storage}->{username}\n");
        }
        if ( $self->{storage}->{password} ) {
            print("password: $self->{storage}->{password}\n");
        }

        foreach ( keys( $self->{storage} ) ) {
            if ( $_ eq 'username' || $_ eq 'password' ) {
                next;
            }

            if ( ref( $self->{storage}->{$_} ) eq 'HASH' ) {
                $self->print_credentials($_);
            }
            else {
                print("$_: $self->{storage}->{$_}\n");
            }
        }
    }
}

sub _parse_file {
    my $self = shift;

    open( FILE, "<$self->{file}" ) or return;
    binmode( FILE, ":utf8" );

    my @data = <FILE>;
    unless (@data) {
        return;
    }
    if ( $data[0] =~ /^encrypt$/ ) {
        @data = Password::Manager::Crypto->new()->decrypt( $data[1] );
    }

    close(FILE);

    my $lvl;
    foreach (@data) {
        if ( $_ =~ /^(.*):$/ ) {
            $lvl = $1;
            $self->{storage}->{$1} = {};
        }
        elsif ( $_ =~ /^    (.*): (.*)$/ ) {
            $self->{storage}->{$lvl}->{$1} = $2;
        }
        elsif ( $_ =~ /^(.*): (.*)$/ ) {
            undef($lvl);
            $self->{storage}->{$1} = $2;
        }
    }
}

sub _write_file {
    my $self = shift;

    my $data = '';

    foreach ( keys( $self->{storage} ) ) {
        if ( ref( $self->{storage}->{$_} ) eq 'HASH' ) {
            $data .= "$_:\n";
            foreach my $key ( keys( $self->{storage}->{$_} ) ) {
                $data .= "    $key: $self->{storage}->{$_}->{$key}\n";
            }
        }
        else {
            $data .= "$_: $self->{storage}->{$_}\n";
        }
    }

    open( FILE, ">$self->{file}" );
    binmode( FILE, ":utf8" );

    if ( $self->{encrypt} ) {
        print FILE "encrypt\n";
        print FILE Password::Manager::Crypto->new()->encrypt($data);
    }
    else {
        print FILE $data;
    }

    close(FILE);
}
1;
