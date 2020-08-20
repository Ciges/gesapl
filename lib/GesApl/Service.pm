package GesApl::Service;

use strict;
use warnings;

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

sub _initialize {
    my $self = shift;

    my $service_name = shift;
    if ($service_name) {
        $self->{_name} = $service_name;
        $self->load_config();
    }
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

sub get_active {
    my $self = shift;

    return $self->{_active};
}

# Load config from text file
sub load_config {
    my $self = shift;

    my $service_name = $self->get_name();

    # Load config from file
    my $config_filename = GesApl::App->get_cfg('services_data')."/".$service_name;
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

    # Is the monitoring of the service stopped?
    $self->{_active} = not -e $config_filename.'.stop' ? 1 : 0;

    die "Error when readind config data from $config_filename: $!\n" if (not defined($self->{_script}) or not defined($self->{_pid_file}) or not defined($self->{_process}) );

}

# Print service configuration
sub get_config {
    my $self = shift;

    return sprintf ("%s:  script de arranque=/etc/init.d/%s, fichero pid=%s, proceso=%s", $self->get_name(), $self->get_script(), $self->get_pid_file(), $self->get_process());
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

=cut