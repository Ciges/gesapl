#  GesApl v2.00 - Class GesApl::App :  Aplication class
package GesApl::App;
use strict;
use warnings;

use experimental qw(switch);

# Needed modules
use Config::IniFiles;
use File::Path qw(mkpath);
use File::Basename;
use Log::Log4perl qw(get_logger);

# GesApl modules
use GesApl::ServiceList;
use GesApl::Service;

use Data::Dumper;

# Constants and default values
use constant CFG_FILE => "/usr/local/etc/gesapl/gesapl2.cnf";


# CONSTRUCTOR

# Read config files for the application and services and returns the an instance of GesApl::App.
# Has no parameteres
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

    # Creation of temporary dir under /var/run if we are root
    my $tmp_dir_gesapld = GesApl::App->get_cfg( 'daemon', 'tmp_dir_gesapld' );
    if ( $< == 0 and not -d $tmp_dir_gesapld ) {
        make_path($tmp_dir_gesapld)
            or die();
    }

    # Creation of temporary dir if it does not exists
    my $tmp_dir = GesApl::App->get_cfg( 'general', 'tmp_dir' );
    if ( not -d $tmp_dir ) {
        mkpath($tmp_dir)
            or die();
        chmod 0777, $tmp_dir
            or die();
    }

    # Open log files, defined in log4perl.cnf configuration file
    # TODO: Make it a little better, now if there is a problem with log4j no log is done
    eval {  Log::Log4perl::init(GesApl::App->get_cfg( 'log_configuration' )); };
    if (not $@)  {
        $self->{_logger} = get_logger("daemon");
        $self->{_commands_logger} = get_logger("commands");
    }
    else {
        printf "WARNING: No se han podido abrir los archivos log (error: ".$@.")\n";
    }

    # Add an instance of ServiceList
    $self->{_ServiceList} = GesApl::ServiceList->new();

}

# Static function to get config values
# Parameters: section and variable name of gesapl2.cnf
# If no parameters are given then an array is returned with all the values
# If only one parameter is given then the value is searched in "general" section
sub get_cfg {
    my ( $class, $section, $config_value ) = @_;

    # This method is static
    die "class method invoked on object" if ref $class;

    # Load config values
    my $cfg = Config::IniFiles->new( -file => CFG_FILE )
        or die;

    if ( defined $section and defined $config_value ) {
        return $cfg->{v}->{$section}->{$config_value};
    }
    elsif ( defined $section ) {
        $config_value = $section;
        return $cfg->{v}->{'general'}->{$config_value};
    }
    else {
        return $cfg->{v};
    }
}

# Returns a list of GesApl::Service for each service configured
sub list_services {
    my $self = shift;

    return $self->{_ServiceList}->list_services();
}

# Returns true if a service with the name told is registered
sub is_service_registered {
    my $self = shift;

    my $name = shift;

    my $service = GesApl::Service->new($name);
    return $service->is_registered();
}

# Returns true if a service with the name told has been deleted but the configuration is still in the register
sub is_service_deleted {
    my $self = shift;

    my $name = shift;

    my $service = GesApl::Service->new($name);
    return $service->is_deleted();
}

# Remove a service from the configuration
# Returns true if the service has been deleted or false if not (because the service is not registered!)
sub unregister_service {
    my $self = shift;

    my $name    = shift;
    my $service = GesApl::Service->new($name);

    if ( $service->is_registered() ) {
        return $service->unregister();
    }
    else {
        return 0;
    }

}

# Register a service
# Parameters could be:
# - Four: service name, name of start/stop script under init.d, path of pid file and name of process
# - Only one: if the service has been deleted and only the name is given then old values are restored
#
# Returns an instace of GesApl::Service with the data loaded
sub register_service {
    my $self = shift;

    my $name = shift;

    my $service;

    # All the info for the service is given
    if ( @_ == 3 ) {
        my ( $script, $pidfile, $process ) = @_;
        $service = GesApl::Service->new( $name, $script, $pidfile, $process );
    }
    elsif ( @_ == 0 ) {
        $service = GesApl::Service->new($name);
    }
    else {
        die("Number of parameters for GesApl::App->register_service() incorrect\n"
        );
    }

    return $service->register();
}

# Returns a list of GesApl::Service for each service configured with monitor properties updated
sub monitor_services {
    my $self = shift;

    return $self->{_ServiceList}->monitor_services();
}

# Sends a message to the log file with the severity level as first parameter and message as second
# If only the message is passed then level info will be set as default
# Returns 0 if no logger has been initiated
sub log {
    my $self = shift;

    my $logger = $self->{_logger};
    if ($logger)  {
        my $level = 'info';
        my $message;
        given(scalar @_)  {
            when (1)  {  $message = shift;  }
            when (2)  { ($level, $message) = @_; }
            default   { die ("Incorrect number of paremeters in function GesApl::App->log()\n"); }
        }

        given($level)  {
            when ('debug')  { $logger->debug($message); }
            when ('info')  { $logger->info($message); }
            when ('warn')  { $logger->warn($message); }
            when ('error')  { $logger->error($message); }
            when ('fatal')  { $logger->fatal($message); }
        }
    }
    else {
        return 0;
    }
}

# Same 


1;

__END__

# HELP

=encoding utf8

=head1 NOMBRE

GesApl::App - Aplicación de monitorización de servicios

=head1 SINOPSIS

    use GesApl::App;
    my $gesapl = GesApl::App->new();

=head1 DESCRIPCION

GesApl es un módulo que permite monitorizar distintos servicios del sistema. Mediante los métodos que proporciona se registran los servicios a monitorizar indicando el script de arranque en /etc/init.d, la ruta del fichero pid y el nombre del proceso ejecutable. Este módulo permite mantener este registro y verificar el estado de cada uno de los servicios 


=head1 MÉTODOS


=head2 CONSTRUCTOR

=head3 new()

Carga la configuración de la aplicación y de los servicios regisrtados y devuelve una instancia de GesApl::App.

No tiene parámetros.


=head2 MÉTODOS


=head3 get_cfg( [ section ] , [ config_value ] )

Devuelve los valores de configuración (leídos del archivo gesapl2.cnf).
Si se le indica la sección y el nombre de la variable de configuración se devuelve su valor. 
Sin parámetros  se devuelve un array con todos los valores de configuración
Son un único parámetro se busca el valor en la seccion "general".

=head3 list_services()

Devuelve una lista de instancias de GesApl::Service, una para cada servicio registrado. 

=head3 is_service_registered( nombre )

Indica si el servicio existe o no en la configuración

=head3 is_service_deleted( nombre )

Indica si el servicio ha sido borrado del registro pero su configuración aún existe

=head3 unregister_service( nombre )

Elimina la configuración del servicio

=head3 register_service( nombre [, script, fichero_pid, proceso ] )

Registra un servicio en la aplicación.
Admite 1 ó 4 parámetros:

=head3 log([nivel=info,] mensaje)

Escribe un mensaje en el log de la aplicación (configurado en /etc/gesapl/log4perl.cnf).
El primer parámetro indica el nivel, una de las siguientes palabras clave: debug, info, warn, error, fatal. Este parámetro es opcional, si no se indica el nivel escogido será info
El segundo parámetro es una cadena de texto a escribir en el log.

=over

=item - Si sólo se le pasa el nombre y la configuración está presente (el servicio se ha borrado y se quiere restaurar) se recuperan los datos y se registra

=item - Si se pasa nombre, ruta del script de arranque y parada en /etc/init.d, ruta del fichero pid y nombre del proceso un nuevo servicio se registra en la aplicación

=back

=cut
