package Password::Manager::Crypto;

use strict;
use warnings;

use Crypt::CBC;

sub new {
    my $class = shift;

    my $self = {};
    bless( $self, $class );

    return $self;
}

sub encrypt {
    my $self  = shift;
    my $plain = shift;

    print("Please enter encryption password:\n");
    system( '/usr/bin/stty', '-echo' );
    my $key1 = <STDIN>;
    system( '/usr/bin/stty', 'echo' );
    print("Plese repeat password:\n");
    system( '/usr/bin/stty', '-echo' );
    my $key2 = <STDIN>;
    system( '/usr/bin/stty', 'echo' );

    unless ( $key1 eq $key2 ) {
        die("Encryption keys don't match\n");
    }

    chomp($key1);

    my $cipher = Crypt::CBC->new(
        -key    => $key1,
        -cipher => 'Blowfish'
    );

    return $cipher->encrypt_hex($plain);
}

sub decrypt {
    my $self  = shift;
    my $crypt = shift;

    print("Please enter decryption password:\n");
    system( '/usr/bin/stty', '-echo' );
    my $key = <STDIN>;
    system( '/usr/bin/stty', 'echo' );
    chomp($key);

    my $cipher = Crypt::CBC->new(
        -key    => $key,
        -cipher => 'Blowfish'
    );

    return split( /\n/, $cipher->decrypt_hex($crypt) );
}
1;
