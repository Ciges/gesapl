#  GesApl v2.00 - Class GesApl::GMail :  Send of emails via Google SMTP Server
#  Authentication config is done in gesapl2.cnf
package GesApl::GMail;

use strict;
use warnings;

# Needed modules

# TODO: Delete when dev is finished
use Data::Dumper;

# CONSTRUCTOR

# Connects to Google SMTP server and returns an instance of GesApl::GMail
# If the connection is not possible then NULL is returned
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

}

# Send email. Parameters are tree: mail receiver, subject and text of email
sub send_mail {
    my $self = shift;

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

=head3 send_mail( remitente, asunto, mensaje)

Envia el correo al remitente y con el asunto y mensaje indicados en los parámetros.

=cut
