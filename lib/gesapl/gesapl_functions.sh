#!/bin/bash

# Funciones comunes a varios scripts de GesApl

# Graba el mensaje pasado como parámetro en en log, precedido de la fecha y hora
function log {
    now="$(date +'%b %e %T')"
    printf "%s %s\n" "${now}" "$1" >> ${log_file}
}

# Graba el mensaje pasado en el log de comandos, precedido de la fecha y hora y con el usuario que lo ejecuta a continuación
# Este log está pensado para llevar un registro de los comandos iniciados por los usuarios
function log_command {
	if [[ $SHLVL -le 3 ]]; then		# Only log command when called directly by an user
    	now="$(date +'%b %e %T')"
    	printf "%s %s (%s)\n" "${now}" "$1"  ${USER} >> ${log_commands_file}
    fi;
}

# Devuelve el listado de ficheros de configuración de servicios
function services_configs {
	find "${services_data}" -type f|grep -v '\.'|sort
}

# Devuelve el listado de servicios configurados
function configured_services {
    for c in $(services_configs); do printf "%s " ${c##*/}; done;
    printf "\n"
}

# Devuelve el listado de servicios monitorizados
function active_services {
	for c in $(services_configs); do 
		! [[ -e ${c}.stop ]] && printf "%s " ${c##*/}
	done;
	printf "\n"
}

# Dado un servicio, devuelve su configuración, en una cadena de texto por la salida estandard
function service_configuration {
    if [[ -r ${services_data}/${1} ]]; then
        service_info="$(cat ${services_data}/${1} )"
        service_script="$(echo ${service_info}|cut -f1 -d',')"
        pid_file="$(echo ${service_info}|cut -f2 -d',')"
        service_executable="$(echo ${service_info}|cut -f3 -d',')"
        printf "%s :  script de arranque=/etc/init.d/%s, fichero pid=%s, service_executable=%s\n" ${1} ${service_script} ${pid_file} ${service_executable}
    else
        printf "ERROR: No se puede leer la configuración del servicio % (%)\n" ${1} "${services_data}/${1}"
        exit 1
    fi;
}

# Función de control, si el usuario no es root interrumpe la ejecución
function must_be_root {
    if [[ `id -u` -ne 0 ]]; then
        printf "ERROR: Este comando debe de ser ejecutado con derechos de root\n"
        exit 1
    fi;
}
