#!/bin/bash

# Graba el mensaje pasado como parámetro en en log, precedido de la fecha y hora
function log {
    now="$(date +'%b %e %T')"
    printf "%s %s\n" "${now}" "$1" >> ${log_file}
}
