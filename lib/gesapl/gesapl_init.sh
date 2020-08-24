#!/bin/bash

# Script "de transición" entre la versión 1.00 y la 2.00 de GesApl
# La nueva versión de GesApl 2.00, en perl, utiliza archivos de configuración .ini distintos a la original
#
# Los scripts gesapld, gesaplctl y gesaplinfo no se han migrado a Perl.
# El objetivo de este script es evitar tener dos configuraciones. Este script permite cargar los valores de configuración del nuevo archivo .ini gesapl2.cnf y realiza las mismas funciones de inicialización que se hacían en la antigua configuración.

# CONFIGURACIÓN

CONFIG_FILE="/etc/gesapl/gesapl2.cnf"
LOGS_CONFIG_FILE="/etc/gesapl/log4perl.cnf"


# -----------------------------------

# CARGA DE LOS VALORES DE CONFIGURACIÓN DE LOS ARCHIVOS DE GESAPL V2.00

# Carga de los valores de configuración de la versión 2.00 gesapl2.cnf
if ! [[ -r ${CONFIG_FILE} ]];  then
    printf "ERROR: %s!\n\n" "Archivo de configuración ${CONFIG_FILE} no encontrado o imposible de leer"
    exit 1
fi;
eval $(cat ${CONFIG_FILE}|grep =|sed s/=/=\"/g|sed s/\$/\"/g|tr -s \")
# Carga de los valores de configuración del arhivo .ini para log4perl (los nombres de las variables tienen punto, se lo quitamos)
if ! [[ -r ${LOGS_CONFIG_FILE} ]];  then
    printf "ERROR: %s!\n\n" "Archivo de configuración ${LOGS_CONFIG_FILE} no encontrado o imposible de leer"
    exit 1
fi;
cat ${LOGS_CONFIG_FILE}|grep =|sed s/=/=\"/g|sed s/\$/\"/g|tr -s \"|while read l; do 
    variable="$(echo ${l}|cut -f1 -d'='|tr -d '.')"
    valor="$(echo ${l}|cut -f2 -d'=')"
    echo "${variable}=${valor}" 
done > ${LOGS_CONFIG_FILE}.sh
if [[ $? -ne 0 ]]; then
    printf "ERROR: %s!\n\n" "No se cargar el archivo ${LOGS_CONFIG_FILE}, error al escribir ${LOGS_CONFIG_FILE}.sh"
    exit 1
fi;
if ! [[ -r ${LOGS_CONFIG_FILE}.sh ]];  then
    printf "ERROR: %s!\n\n" "Archivo de configuración ${LOGS_CONFIG_FILE} no encontrado o imposible de leer"
    exit 1
fi;
eval $(cat ${LOGS_CONFIG_FILE}.sh)

# Hacemos le equivalencia entre los valores de configuración de la versión 1 y la versión 2 para aquellos que tienen nombres distintos
INSTALLATION_DIR="${installation_dir}"
log_commands_file="${log4perlappenderCOMMANDSFILEfilename}"
log_file="${log4perlappenderLOGFILEfilename}"

# Mensaje de monitorización del servicio
log_monitor_service_format="Monitorización del servicio %s: \n"


# -----------------------------------

# Inicialización de GESAPL

# Carga de las funciones comunes
gesapl_lib="${INSTALLATION_DIR}/lib/gesapl/gesapl_functions.sh"
if ! [[ -r "${gesapl_lib}" ]];  then
    printf "ERROR: %s!\n\n" "Fichero ${gesapl_lib} no encontrado o imposible de leer"
    exit 1
fi;
source ${gesapl_lib}

# Creamos el directorio para el demonio si somos 'root'
if [[ `id -u` -eq 0 ]] && ! [[ -d ${tmp_dir_gesapld} ]]; then
    mkdir -p ${tmp_dir_gesapld}
    if [[ $? -ne 0 ]]; then
        msg_error="No se ha podido crear el directorio temporal ${tmp_dir_gesapld}"
        printf "ERROR: %s!\n\n" "${msg_error}"
        log "${msg_error}"
        exit 1
    fi;
fi;

# Creamos el directorio temporal si no existe
if ! [[ -d ${tmp_dir} ]]; then
    (umask 0000; mkdir -p ${tmp_dir})
    if [[ $? -ne 0 ]]; then
        msg_error="No se ha podido crear el directorio temporal ${tmp_dir}"
        printf "ERROR: %s!\n\n" "${msg_error}"
        log "${msg_error}"
        exit 1
    fi;
fi;

# Creamos archivos log vacíos con los derechos adecuados si es necesario
# Log del demonio. Además del demonio también una monitorización lanzada manualmente será registrada
# Abrimos los permisos por tanto (TODO: Mejorar la gestión de los logs)
if ! [[ -e ${log_file} ]]; then
    if [[ -w $(dirname ${log_file}) ]]; then
        (umask 0111; touch ${log_file} 2>/dev/null)
        if [[ $? -ne 0 ]]; then
            printf "ERROR: %s!\n\n" "No es posible escribir en el archivo ${log_file}"
            exit    
        fi;
    fi;
fi;

# Log de comandos, a usar por todos los scripts y a ejecutar por usuarios no root
if ! [[ -w ${log_commands_file} ]]; then
    (umask 0111; touch ${log_commands_file} 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        printf "ERROR: %s!\n\n" "No es posible escribir en el archivo ${log_commands_file}"
        exit    
    fi;
fi;
