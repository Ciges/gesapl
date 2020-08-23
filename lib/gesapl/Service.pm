package GesApl::Service;

use strict;
use warnings;
use feature 'say';

# Needed modules
use File::Copy;
use Proc::ProcessTable;

# TODO: Delete when dev is finished
use Data::Dumper;

# GesApl modules
use GesApl::App;

# Constructor
# Service name is mandatory
# Optionally we could get three more parameters:  start/stop script, pidfile and process
sub new {
    my $class = shift;

    # This method is static
    die "class method invoked on object" if ref $class;

    my $self = bless {}, $class;

    $self->_initialize(@_);
    return $self;
}

# Private functions

sub _initialize {
    my $self = shift;

    if (@_ == 1)  {
        my ($service_name) = @_;
        $self->{_name} = $service_name;
        $self->load_config();
    }
    elsif (@_ == 4)  {
        my ($service_name, $script, $pidfile, $process) = @_;
        $self->{_name} = $service_name;
        $self->set_script($script);
        $self->set_pidfile($pidfile);
        $self->set_process($process);
    }
    else {
        die("Instance creation error, incorrect number of parameters\n");
    }

}

sub _get_config_file_path {
    my $self = shift;

    GesApl::App->get_cfg('services_data') . "/" . $self->get_name();
}

# Getters
sub get_name {
    my $self = shift;

    return $self->{_name};
}

sub get_script {
    my $self = shift;

    return $self->{_script};
}

sub get_pidfile {
    my $self = shift;

    return $self->{_pidfile};
}

sub get_process {
    my $self = shift;

    return $self->{_process};
}

sub get_registered {
    my $self = shift;

    $self->{_registered} = -e $self->_get_config_file_path() ? 1 : 0;

    return $self->{_registered};
}

# Returns if the service is active.
# The monitoring of a service can be stopped with gesapl2ctl command.
sub get_active {
    my $self = shift;

# A flag in the config directory with the .stop suffix is saved in case the monitoring is stoppd
    $self->{_active} = !-e $self->_get_config_file_path() . ".stop" ? 1 : 0;

    return $self->{_active};
}

sub get_monitor_status {
    my $self = shift;

    return $self->{monitor}->{status};
}

sub get_monitor_status_message {
    my $self = shift;

    return $self->{monitor}->{status_message};
}

sub get_monitor_lasttime {
    my $self = shift;

    return $self->{monitor}->{lasttime};
}

# Setters

# Auxiliar function to update config file if we have all the elements
# Return 1 if config has been saved and 0 if not
sub _save_config {
    my $self = shift;

    if (    $self->get_name()
        and $self->get_script()
        and $self->get_pidfile()
        and $self->get_process() )
    {
        my $config_filename = $self->_get_config_file_path();
        my $config_file;
        open( $config_file, '>', $config_filename )
            or die
            "Opening of file $config_filename to write impossible: $!\n";
        print $config_file $self->get_script() . ","
            . $self->get_pidfile() . ","
            . $self->get_process();
        close($config_file);

        return 1;
    }
    else {
        return 0;
    }
}

sub set_script {
    my $self = shift;
    $self->{_script} = shift;

    $self->_save_config();
}

sub set_pidfile {
    my $self = shift;
    $self->{_pidfile} = shift;

    $self->_save_config();
}

sub set_process {
    my $self = shift;
    $self->{_process} = shift;

    $self->_save_config();
}

sub _set_monitor_status {
    my $self   = shift;
    my $status = shift;

    if ( lc $status eq "ok" ) {
        $self->{monitor}->{status} = 1;
    }
    else {
        $self->{monitor}->{status} = 0;
    }

}

sub _set_monitor_status_message {
    my $self = shift;

    $self->{monitor}->{status_message} = shift;
}

sub _set_monitor_lasttime {
    my $self = shift;

    $self->{monitor}->{lasttime} = localtime;
}

# Methods

# Load config from text file
# Return 1 if config has been loaded and 0 if not (it could not exists)
sub load_config {
    my $self = shift;

    my $service_name = $self->get_name();

    # Load config from file
    my $config_filename = $self->_get_config_file_path();

    if ( -e $config_filename ) {
        my $config_file;
        open( $config_file, '<', $config_filename )
            or die "Read of file $config_filename impossible: $!\n";
        my $config = <$config_file>;
        chomp($config);

        my @fields = split ",", $config;
        $self->{_script}  = $fields[0];
        $self->{_pidfile} = $fields[1];
        $self->{_process} = $fields[2];
        close $config_file;
        return 1;

        die "Error when reading config data from $config_filename: $!\n"
            if ( not defined( $self->{_script} )
            or not defined( $self->{_pidfile} )
            or not defined( $self->{_process} ) );
    }
    else {
        return 0;
    }

}

# Print service configuration
sub get_config {
    my $self = shift;

    if ( $self->is_registered() ) {
        return sprintf(
            "%s:  script de arranque=/etc/init.d/%s, fichero pid=%s, proceso=%s",
            $self->get_name(),    $self->get_script(),
            $self->get_pidfile(), $self->get_process()
        );
    }
    else {
        return sprintf( "%s:  service NOT registered", $self->get_name() );
    }
}

# Returns true if the service configuration is in the register
sub is_registered {
    my $self = shift;

    return $self->get_registered();
}

# Returns true if the service configuration has been deleted but is still present in the register
sub is_deleted {
    my $self = shift;

    $self->{_deleted}
        = -e $self->_get_config_file_path() . ".deleted" ? 1 : 0;

    return $self->{_deleted};
}

# Remove service configuration
sub unregister {
    my $self = shift;

    my $config_filename = $self->_get_config_file_path();
    die "Error when reading config data from $config_filename: $!\n"
        if ( not $self->is_registered() );

    move( $self->_get_config_file_path(),
        $self->_get_config_file_path() . ".deleted" )
        or die
        "Error when moving config file data from $config_filename to $config_filename.stop: $!\n";

    return 1;
}

# Adds the service configuration to the register
# The data in the config file is overwriten with instance properties.
# If only name has values and the service has been deleted then the info is recovered from the old configuration
sub register {
    my $self = shift;

    my $config_filename = $self->_get_config_file_path();
    if ( not $self->_save_config() ) {
        if ( -e $config_filename . ".deleted" ) {
            move( $config_filename . ".deleted", $config_filename )
                or die
                "Error when moving config file data from $config_filename.deleted to $config_filename: $!\n";
            return $self->load_config();
        }
        else {
          # Configuration has not been updated and old data has not been found
          # Here we do not should arrive :-|
            die
                "Configuration service has not been updated and old data has not been found: $!\n";
        }
    }
    else {
        # Configuration has been updated
        return 1;
    }
}

# Verify the status of the service
# This functon checks de PID in the pid file and verifies if it corresponds to a service process
# In case of error a text message is generated
# If the service is active in the system a return value of 1 is returned, 0 if not
# The results are saved in the instance properties {monitor}->{status} ("OK" or "NOOK"), {monitor}->{status_message} and {monitor}->{last_time} (date and time of last monitorization)
sub monitor {
    my $self = shift;

    # Default values
    $self->_set_monitor_status("nook");
    $self->_set_monitor_lasttime();

    # Check the pid in the _pidfile
    my $pidfilename = $self->get_pidfile();
    if ( -r $pidfilename ) {
        open my $pidfile, '<', $pidfilename;
        my $pid = <$pidfile>;
        chomp($pid);
        close $pidfile;

        my $t = Proc::ProcessTable->new;
        foreach my $p ( @{ $t->table } ) {
            if ( $p->pid == $pid ) {
                if ( defined( @{ $p->cmdline }[0] )
                    and @{ $p->cmdline }[0] =~ $self->get_process() )
                {

                    # The PID file is a server process
                    $self->_set_monitor_status("ok");
                }
                else {
                    # The PID file is a NOT server process!
                    $self->_set_monitor_status_message(
                        sprintf(
                            "El proceso con PID %s existe pero no corresponde al servicio %s (debería ser %s)",
                            $self->get_pidfile, $self->get_name(),
                            $self->get_process
                        )
                    );
                }
            }
        }
    }
    else {
        # The pid file is not readable
        $self->_set_monitor_status_message(
            sprintf( "El fichero PID %s no existe o no se puede leer",
                $self->get_pidfile )
        );

        # Search the process by name
        my $t = Proc::ProcessTable->new;
        foreach my $p ( @{ $t->table } ) {
            if ( defined( @{ $p->cmdline }[0] )
                and @{ $p->cmdline }[0] =~ $self->get_process() )
            {
                # Service is there!
                $self->_set_monitor_status("ok");
                $self->_set_monitor_status_message(
                    sprintf(
                        "El servicio está arrancado pero el fichero PID %s no existe o no se puede leer",
                        $self->get_pidfile )
                );
                last;
            }
        }
    }

    return $self->get_monitor_status();

}

1;

__END__

# HELP

=encoding utf8

=head1 NOMBRE

GesApl::Service - Modulo para gestionar la configuración de un servicio registrado en GesApl 2.00 (con ficheros de texto)

=head1 SINOPSIS

Este módulo, aunque puede ser usado directamente, está pensado para ser usado por la aplicación GesApl. 

    # Carga de la configuración de Apache
    my $apache_config = GesApl::Service->new("apache");

    # Reload and show configuration from /etc/gesapl/services/apache
    $apache_config->load_config();
    $apache_config->print();

=head1 DESCRIPCION

GesApl es una aplicación que permite monitorizar distintos servicios del sistema.

Este módulo se encarga de gestionar la configuración de un servicio dado, permitiendo registrar sus propiedades en archivos de texto y activar/desactivar su monitorización.

Cada servicio se define por cuatro propiedades fundamentales:

=over

=item - nombre

=item - nombre del script de arranque y parada en /etc/init.d

=item - ruta del fichero pid

=item - ruta del proceso en el sistema

=back

La configuración en el directorio indicado en el valor de configuración 'services_data')

=head1 METODOS

=head2 LECTURA DE PROPIEDADES

=head3 get_name()

=head3 get_script()

=head3 get_pidfile()

=head3 get_process() 


=head2 ESCRITURA DE PROPIEDADES

=head3 set_script()

=head3 set_pidfile()

=head3 set_process()


=head2 MÉTODOS

=head3 new( nombre [ script, pidfile, process ] )

Crea una instancia de GesApl::Service.

Podemos pasarle el nombre únicamente o las cuatro propiedades que definen a un servicio:

=over

=item - nombre

=item - nombre del script de arranque y parada en /etc/init.d

=item - ruta del fichero pid

=item - ruta del proceso en el sistema

=back

=head3 get_registered()

Indica si existe una configuración almacenada para el servicio

=head3 is_registered()

Indica si existe una configuración almacenada para el servicio (alias the get_registered())

=head3 get_active()

Indica si el servicio está siendo monitorizado

=head3 get_monitor_status()

Indica si el servicio está arrancado en el sistema

=head3 get_monitor_status_message()

Devuelve una cadena de texto con un mensaje de warning si se ha producido alguna incidencia en la monitorizaciñon

=head3 get_monitor_lasttime()

Devuelve un timestamp con la última fecha y hora de monitorización

=head3 load_config()

Carga la configuración de nuevo desde el fichero correspondiente en /etc/gesapl/services

=head3 is_deleted()

Indica si la configuración del servicio ha sido borrada pero aún está en el registro

=head3 unregister()

Elimina la configuración del servicio

=head3 register()

Añade una configuŕación al registro

Si sólo tiene valor la propiedad name y el servicio ha sido borrado, se recuperan los datos almacenados antes de haberlo borrado.

=head3 monitor()

Verifica el estado del servicio y devuelve 1 si el servicio está activo y 0 en caso contrario.
El estado del servicio ("OK" o "NOOK"), un mensaje de error y la fecha y hora de ultima monitorización ejecutada serán almacenados en propiedades de la instancia.

=cut
