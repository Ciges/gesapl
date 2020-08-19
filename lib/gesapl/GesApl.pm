package GesApl;

use strict;
use warnings;

# Needed modules
use Config::IniFiles;
use File::Path qw(mkpath);
use File::Basename;

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

# Init GesApl application
sub new {
    my ( $class, $args ) = @_;

    # This method is static
    die "class method invoked on object" if ref $class;

    # Default values
    my $cfg_file = "/usr/local/etc/gesapl/gesapl2.cnf";

    # Load config values
    my $cfg = Config::IniFiles->new( -file => $cfg_file )
        or die;

    my $self = bless { cfg => $cfg }, $class;

    $self->_initialize();
    return $self;
}

sub _initialize {
    my $self = shift;

    # Creation of temporary dir under /var/run if we are root
    my $tmp_dir_gesapld = $self->get_cfg( 'daemon', 'tmp_dir_gesapld' );
    if ( $< == 0 and not -d $tmp_dir_gesapld ) {
        make_path($tmp_dir_gesapld)
            or die();
    }

    # Creation of temporary dir if it does not exists
    my $tmp_dir = $self->get_cfg( 'general', 'tmp_dir' );
    if ( not -d $tmp_dir ) {
        mkpath($tmp_dir)
            or die();
        chmod 0777, $tmp_dir
            or die();
    }

    # Creation of empty daemon log file, writable by everyone
    # TODO: Limit the rights in the log to be writeable only by the dameon and create a communication between client scripts and daemon
    my $daemon_log_file = $self->get_cfg( 'daemon', 'log_file' );
    if ( not -e $daemon_log_file and -w dirname($daemon_log_file) ) {
        open my $log, '>>', "$daemon_log_file"
            or die();
        close $log;
        chmod 0666, $daemon_log_file
            or die();
    }

    # Creation of commands log, to be writable by all the scripts
    my $log_commands_file = $self->get_cfg( 'general', 'log_commands_file' );
    if ( not -e $log_commands_file ) {
        open my $log, '>>', "$log_commands_file"
            or die();
        close $log;
        chmod 0666, $log_commands_file
            or die();
    }

}

# Get config values
# Parameters: section and variable name of gesapl2.cnf
# If no parameters are given then an array is returned with all the values. If only the section is given then the values for the section are returned.
sub get_cfg {
    my ( $self, $section, $config_value ) = @_;
    if ( defined $section and defined $config_value ) {
        return $self->{cfg}->{v}->{$section}->{$config_value};
    }
    elsif ( defined $section ) {
        return $self->{cfg}->{v}->{$section};
    }
    else {
        return $self->{cfg}->{v};
    }
}

1;
