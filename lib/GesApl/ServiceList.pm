package GesApl::ServiceList;

use strict;
use warnings;

# Constructor
sub new {
    my $class = shift;

    # This method is static
    die "class method invoked on object" if ref $class;

    my $self = bless {}, $class;

    $self->_initialize(@_);
    return $self;
}

# Load current registered services
sub _initialize {

}

sub list_services {

}

1;

__END__

# HELP

=encoding utf8

=head1 NOMBRE

GesApl::ServiceList - Modulo para la gestión de servicios de GesApl 2.00 (con ficheros de texto)

=head1 SINOPSIS

Este módulo, aunque puede ser usado directamente, está pensado para ser usado por la aplicación GesApl. En el ejemplo de código mostrado a continuación es una instancia de GesApl::App la que usa este módulo en su método list_services.

    # Creamos una nueva instancia de GesApl
    use GesApl::App;
    my $gesapl = GesApl::App->new();

    # Obtenemos los servicios configurados
    my @services = $gesapl->list_services();

    # Equivalente a 
    my $servicelist = GesApl::ServiceList->new();
    my @services = $servicelist->list_services();    


=head1 DESCRIPCION

GesApl es una aplicación que permite monitorizar distintos servicios del sistema.

Este módulo se encarga de gestionar el listado de servicios, permitiendo monitorizar cada uno de los servicios configurados, registrar un nuevo servicio, borrar un servicio registrado o mostrar el listado de los servicios

=head1 METODOS

=head2 list_services()

Devuelve una lista de instancias de GesApl::Service, una para cada servicio registrado. 

La clase GesApl::Service permite realizar operaciones sobre el servicio (modificar sus parámetros, activar o desactivar su monitorización, mostrar información ...). La configuración se almacena en archivos de texto (en el directorio indicado en el valor de configuración 'services_data')

=cut
