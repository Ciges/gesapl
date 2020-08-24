#  GesApl v2.00 - Class GesApl::GMail :  Send of emails via Google SMTP Server
#  Authentication config is done in gesapl2.cnf
package GesApl::GMail;

use strict;
use warnings;
use feature 'say';

# Needed modules
use Net::SMTP::SSL;

# GesApl modules
use GesApl::App;

# CONSTRUCTOR

# Returns an instance of GesApl::GMail
sub new {
    my $class = shift;

    # This method is static
    die "class method invoked on object" if ref $class;

    my $self = bless {}, $class;

    $self->_initialize(@_);
    return $self;
}

sub _initialize {
    my $self = shift;

    my ( $server, $port, $user, $pass ) = (
        GesApl::App->get_cfg( 'mail', 'smtp_server' ),
        GesApl::App->get_cfg( 'mail', 'smtp_port' ),
        GesApl::App->get_cfg( 'mail', 'smtp_user' ),
        GesApl::App->get_cfg( 'mail', 'smtp_pass' )
    );

    $self->{_server} = $server;
    $self->{_port}   = $port;
    $self->{_user}   = $user;
    $self->{_pass}   = $pass;
}

# Send email. Parameters are three: mail receiver, subject and text of email
sub send {
    my $self = shift;
    my ( $receiver, $subject, $body ) = @_;

    # Connection to SMTP server
    my $smtp = Net::SMTP::SSL->new(
        $self->{_server},
        Port    => $self->{_port},
        Debug   => 0,
        Timeout => 60
    ) or die("Error connecting to SMTP server: $!\n");
    $smtp->auth( $self->{_user}, $self->{_pass} )
        or die("Error authenticating username $self->{_user}: $!\n");

    # Creation and send of email
    $smtp->mail( $self->{_user} );

    if ( $smtp->to($receiver) )  {
        $smtp->data();
        $smtp->datasend( "From: " . $self->{_user} );
        $smtp->datasend("\n");
        $smtp->datasend( "To: " . $receiver );
        $smtp->datasend("\n");
        $smtp->datasend( "Subject: " . $subject . "" );
        $smtp->datasend("\n");
        $smtp->datasend( $body . "" );
        $smtp->dataend();
    } else {
        # Replace by a write to the log
        GesApl::App->log('error', sprintf("Error sending mail to %s: %s\n", $receiver, $smtp->message()));
    }

    $smtp->quit();
}

1;

__END__

# HELP

=encoding utf8

=head1 NOMBRE

GesApl::GMail - Clase para el envío de correos usando el servidor SMTP de google.

=head1 SINOPSIS

Este módulo se ha desarrollado para simplificar el envío de correos desde el código de la aplicación GesApl

Los datos de autenticación se configuran en la sección mail del archivo de configuración gesapl2.cnf.

Aunque puede ser usado directamente, está pensado para ser usado por la aplicación GesApl. 

TODO: Ejemplo de uso de código


=head1 DESCRIPCIÓN

GesApl es una aplicación que permite monitorizar distintos servicios del sistema.

Este módulo se ha desarrollado para simplificar el envío de correos desde el código de la aplicación. Cuando se monitoriza un servicio y se ha caído se envía un mensaje de error a las direcciones de correo indicadas indicadas en la variable ¡admin_emails' del archivo de configuración

=head1 MÉTODOS


=head2 CONSTRUCTOR

=head3 new()

Se conecta al servicio SMTP de Google y devuelve una instancia de GesApl::GMail

No tiene parámetros.


=head2 OTROS MÉTODOS

=head3 send( destinatario, asunto, mensaje)

Envia el correo al email de destino y con el asunto y mensaje indicados en los parámetros.

=cut
