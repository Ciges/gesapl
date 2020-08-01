#!/bin/bash

# Graba el mensaje pasado como parámetro en en log, precedido de la fecha y hora
function log {
    now="$(date +'%b %e %T')"
    printf "%s %s\n" "${now}" "$1" >> ${log_file}
}

# Devuelve el listado de ficheros de configuración de servicios
function services_configs {
	find "${services_data}" -type f|grep -v '\.'|sort
}