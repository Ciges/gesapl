package GesApl::Common;
use strict;
use warnings;

use Exporter qw(import);

our @EXPORT = qw(help error_message info_message);


# load some modules
use Pod::Usage qw(pod2usage);
use IO::String;
use Pod::Select;

# GesApl modules
use GesApl::App;

# Constant and default values
use constant DESCRIPTION =>
    GesApl::App->get_cfg( 'general', 'gesapl_description' );


# FUNCTIONS

# Print in standard output the following POD sections: SINOPSIS and USO and exits
# Optional parameters: message, exit value, show_info
# - If a message is passed as parameter, the message will be shown after GesApl description and only USO section will be shown
# - As second parameter an exit value could be given
# - If the third parameter is 0 then no info will be shown
sub help {
    my $message    = shift;
    my $exit_value = shift || 0;
    my $show_info  = shift;
    $show_info = 1 if ( not defined $show_info );

    my ( $buffer, $io, $parser );
    if ( $show_info == 1 ) {
        $io     = IO::String->new($buffer);
        $parser = Pod::Select->new();
    }

    printf( "\n%s\n", DESCRIPTION );
    if ($message) {
        printf( "\n%s\n", $message );
        $parser->select("USO") if ( $show_info == 1 );
    }
    else {
        $parser->select("SINOPSIS|USO") if ( $show_info == 1 );
    }
    printf("\n");

    if ( $show_info == 1 ) {
        $parser->parse_from_file( $0, $io );
        $buffer =~ s/=head1\s*//g;

        print $buffer;
    }

    exit $exit_value;
}

# Alias for previous help() function with two paremeters message and exit_value
# The message received will have the preffix ERROR: and no usage info will be shown
sub error_message {
    my $message    = shift;
    my $exit_value = shift;
    &help( "ERROR: " . $message, $exit_value, 0 );
}

# Shows the application description and a informative message
sub info_message {
    printf( "\n%s\n\n%s\n", DESCRIPTION, shift );
}



1;

__END__

# HELP

=encoding utf8

=head1 NOMBRE

GesApl::Common - Variables y funciones comunes a los distintios scripts de GesApl


=head1 SINOPSIS

    use GesApl::Common qw(help error_message info_message);

    # Mostramos la ayuda del script si $help es verdadero
    help() if $help;
    
    # Mensaje de error e informativo
    $gesapl->register_service($service_name)
        or &error_message( "el servicio ".$service_name." no se ha podido añadir al registro", 3 );
    &info_message("Configuración del servicio eliminada\n");


=head1 DESCRIPCIÓN

GesApl es una aplicación que permite monitorizar distintos servicios del sistema. 

En este módulo se incluyen métodos para mostrar la ayuda del script (obtenida de la documentación POD del propio script) y mostrar mensajes de error e informativos.

Las funciones se exportan con lo que se pueden usar directamente, sin prefijo alguno.


=head1 MÉTODOS

=head2 help( [ message, exit value, show_info ] )

Esta función es usada para mostrar mensajes informativos y de error al usuario. 
Una vez mostrado la ejecución del script se interrumpe.

Muestra las secciones SINOPSIS y USO de la documentación POD del script.
Si se le indica un mensaje se mostrará el texto y luego la sección USO
El segundo parámetro es un valor de retorno (por defecto devuelve 0).
Si el tercer parámetro es 0 no se mostrará ninguna ayuda, únicamente el mensaje de texto indicado en el primer parámetro.

=head error_messsage( [ message, exit value ] )

Función wrapper de help. Muestra el mensaje indicado con el prefijo ERROR: y no muestra la ayuda

=head info_message( [ message ] )

Función wrapper de help. Muestra únicamente el mensjae informativo.

=cut
