package GesApl::App;

use strict;
use warnings;

# Needed modules
use Config::IniFiles;
use File::Path qw(mkpath);
use File::Basename;

# GesApl modules
use GesApl::ServiceList;
use GesApl::Service;

use Data::Dumper;

# Constants and default values
use constant CFG_FILE => "/usr/local/etc/gesapl/gesapl2.cnf";

# Constructor
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

    # Creation of empty daemon log file, writable by everyone
    # TODO: Limit the rights in the log to be writeable only by the dameon and create a communication between client scripts and daemon
    my $daemon_log_file = GesApl::App->get_cfg( 'daemon', 'log_file' );
    if ( not -e $daemon_log_file and -w dirname($daemon_log_file) ) {
        open my $log, '>>', "$daemon_log_file"
            or die();
        close $log;
        chmod 0666, $daemon_log_file
            or die();
    }

    # Creation of commands log, to be writable by all the scripts
    my $log_commands_file
        = GesApl::App->get_cfg( 'general', 'log_commands_file' );
    if ( not -e $log_commands_file ) {
        open my $log, '>>', "$log_commands_file"
            or die();
        close $log;
        chmod 0666, $log_commands_file
            or die();
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

# Returns true if a service with the name told is registered
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

    my $name    = shift;
    my $service = GesApl::Service->new($name);

    # All the info for the service is given
    if ( @_ == 3 ) {
        my ( $script, $pidfile, $process ) = @_;
        $service->set_script($script);
        $service->set_pidfile($pidfile);
        $service->set_process($process);
        return $service->register();
    }
    elsif ( @_ == 0 ) {
        return $service->register();
    }
    else {
        die("Number of parameters for GesApl::App->register_service() incorrect\n"
        );
    }
}

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

=head1 METODOS

=head2 get_cfg ( [ section ] , [ config_value ] )

Devuelve los valores de configuración (leídos del archivo gesapl2.cnf).
Si se le indica la sección y el nombre de la variable de configuración se devuelve su valor. 
Sin parámetros  se devuelve un array con todos los valores de configuración
Son un único parámetro se busca el valor en la seccion "general".

=head2 list_services()

Devuelve una lista de instancias de GesApl::Service, una para cada servicio registrado. 

=head2 is_service_registered( nombre )

Indica si el servicio existe o no en la configuración

=head2 is_service_deleted( nombre )

Indica si el servicio ha sido borrado del registro pero su configuración aún existe

=head2 unregister_service( nombre )

Elimina la configuración del servicio

=cut
