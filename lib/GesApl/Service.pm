package GesApl::Service;

use strict;
use warnings;

# Needed modules
use File::Copy;
# GesApl mmodules
use GesApl::App;

# Constructor
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

    my $service_name = shift;
    if ($service_name) {
        $self->{_name} = $service_name;
        $self->load_config();
    }
}

sub _get_config_file_path {
    my $self = shift;

    GesApl::App->get_cfg('services_data')."/".$self->get_name();
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

sub get_pid_file {
    my $self = shift;

    return $self->{_pid_file};
}

sub get_process {
    my $self = shift;

    return $self->{_process};
}

sub get_registered {
    my $self = shift;

    return $self->{_registered};
}
# Alias for get_registered
sub is_registered { 
    my $self = shift;

    return $self->get_registered();
}

# Returns if the service is active. 
# The monitoring of a service can be stopped with gesapl2ctl command.
sub get_active {
    my $self = shift;

    # A flag in the config directory with the .stop suffix is saved in case the monitoring is stoppd
    $self->{active} = ! -e $self->_get_config_file_path().".stop" ? 1 : 0;

    return $self->{_active};
}

# Load config from text file
sub load_config {
    my $self = shift;

    my $service_name = $self->get_name();

    # Load config from file
    my $config_filename = $self->_get_config_file_path();
    
    if (-e $config_filename)    {
        my $config_file;
        open ($config_file, '<', $config_filename)
            or die "Read of file $config_filename impossible: $!\n";
        my $config = <$config_file>;
        chomp ($config);

        my @fields = split ",", $config;
        $self->{_script} = $fields[0];
        $self->{_pid_file} = $fields[1];
        $self->{_process} = $fields[2];
        close $config_file;

        die "Error when reading config data from $config_filename: $!\n" if (not defined($self->{_script}) or not defined($self->{_pid_file}) or not defined($self->{_process}) );
        $self->{_registered} = 1;
    }
    else {
        # If the config files does not exist then the service is not yet registered
        $self->{_registered} = 0;
    }

    # Is the monitoring of the service stopped?
    $self->{_active} = not -e $config_filename.'.stop' ? 1 : 0;



}

# Print service configuration
sub get_config {
    my $self = shift;

    if ($self->is_registered())  {
        return sprintf ("%s:  script de arranque=/etc/init.d/%s, fichero pid=%s, proceso=%s", $self->get_name(), $self->get_script(), $self->get_pid_file(), $self->get_process());
    }
    else {
        return sprintf ("%s:  service NOT registered", $self->get_name());   
    }
}

# Remove service configuration
sub unregister {
    my $self = shift;

    my $config_filename = $self->_get_config_file_path();
    die "Error when reading config data from $config_filename: $!\n" if (not $self->is_registered());
    
    move($self->_get_config_file_path(), $self->_get_config_file_path().".deleted")
        or die "Error when moving config file data from $config_filename to $config_filename.stop: $!\n";

    return 1;
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

La configuración en el directorio indicado en el valor de configuración 'services_data')

=head1 METODOS

=head2 get_name()

=head2 get_script()

=head2 get_pid_file()

=head2 get_process()

=head2 load_config()

Carga la configuración de nuevo desde el fichero correspondiente en /etc/gesapl/services

=head2 get_config()

Muestra la configuración registrada para el servicio en GesApl

=head2 get_registered()

Indica si existe una configuración almacenada para el servicio

=head2 is_registered()

Alias para get_registered()

=head2 get_active()

Indica si el la monitorización del servicio está activa

=head2 unregister()

Elimina la configuración del servicio


=cut