package GesApl;

use strict;
use warnings;

# Needed modules
use Config::IniFiles;
use File::Path;
use Data::Dumper;

=encoding utf8

=head1 NOMBRE

GesApl - Aplicación de monitorización de servicios

=head1 SINOPSIS

    use GesApl;
    my $gesapl = GesApl->new();

=head1 DESCRIPCION

GesApl es un módulo que permite monitorizar distintos servicios del sistema. Mediante los métodos que proporciona se registran los servicios a monitorizar indicando el script de arranque en /etc/init.d, la ruta del fichero pid y el nombre del proceso ejecutable. Este módulo permite mantener este registro y verificar el estado de cada uno de los servicios 

=head1 METODOS

=head2 get_cfg ( [ section ] , [ config_value ] )

Devuelve los valores de configuración (leídos del archivo gesapl2.cnf).
Si se le indica la sección y el nombre de la variable de configuración se devuelve su valor. En caso contrario se devuelve un array con todos los valores de configuración o los valores de la sección si se indica únicamente la sección.

=cut


# TODO 
# Use static functions

# Init GesApl application
sub new {
	my ($class,$args) = @_;

	# Default values
	my $cfg_file = "/usr/local/etc/gesapl/gesapl2.cnf";

	# Load config values
	my $cfg = Config::IniFiles->new( -file => $cfg_file )
	   || die ;

    my $self = bless { cfg => $cfg
                    }, $class;

    $self->_initialize(); 
    return $self;
}

sub _initialize {
    my $self = shift;

    # Creation of temporary dir if we are root
    my $tmp_dir_gesapld = $self->get_cfg('daemon', 'tmp_dir_gesapld');
    if ( $< == 0 and not -d $tmp_dir_gesapld )  {
        make_path($tmp_dir_gesapld)
            || die();
    }

    #TODO

    # Creamos el directorio temporal si no existe
    
    # Creamos archivos log vacíos con los derechos adecuados si es necesario
    # Log del demonio. Además del demonio también una monitorización lanzada manualmente será registrada
    # Abrimos los permisos por tanto (TODO: Mejorar la gestión de los logs)

    # Log de comandos, a usar por todos los scripts y a ejecutar por usuarios no root

}


# Get config values
# Parameters: section and variable name of gesapl2.cnf
# If no parameters are given then an array is returned with all the values. If only the section is given then the values for the section are returned.
sub get_cfg {
	my ($self, $section, $config_value) = @_;
	if (defined $section and defined $config_value) {
		return $self->{cfg}->{v}->{$section}->{$config_value};	
	}
	elsif (defined $section) {
		return $self->{cfg}->{v}->{$section};
	}
	else {
		return $self->{cfg}->{v};
	}
}

1;