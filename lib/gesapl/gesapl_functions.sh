#!/bin/bash

# Funciones comunes a varios scripts de GesApl

# Graba el mensaje pasado como parámetro en el log del demonio, precedido de la fecha y hora
function log {
    now="$(date +'%b %e %T')"
    if [[ -w ${log_file} ]]; then
        printf "%s %s\n" "${now}" "$1" >> ${log_file}
    fi;
}

# Graba el mensaje pasado en el log de comandos, precedido de la fecha y hora y con el usuario que lo ejecuta a continuación
# Este log está pensado para llevar un registro de los comandos iniciados por los usuarios
function log_command {
	if [[ $SHLVL -le 3 ]]; then		# Only log command when called directly by an user
    	now="$(date +'%b %e %T')"
    	printf "%s %s (%s)\n" "${now}" "$(echo $@|tr -d \\n)"  ${USER} >> ${log_commands_file}
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

# Devuelve un valor de retorno 0 si el demonio está arrancado y de 1 si no lo está
function gesapld_started {

    # Buscamos por el pid del fichero
    if [[ -r ${pid_gesapld} ]]; then
        if ps -hq `cat ${pid_gesapld}` -o cmd|grep ${gesapld_bin}|grep -v grep|grep -q 'refork_daemon'; then
            return 0
        fi;
    fi

    # Y si no es posible buscamos procesos en el sistema
    ps -ef|grep ${gesapld_bin}|grep -v grep|grep -q 'refork_daemon'
}

# Monitoriza el servicio indicado
# Devuelve un valor de retorno 0 si está presente, 1 en caso contrario
# Por la salida estandar devuelve un mensaje de error si lo hubiera
function monitor {
    local service
    local service_info
    local service_pid
    local service_script
    local pid_file
    local service_executable
    local status
    local status_message

    service="${1}"
    if ! [[ -f ${services_data}/${service} ]]; then
        printf "ERROR: %s\n\n" "El servicio ${nombre} no está siendo monitorizado por gesappl"
        exit 1
    fi;

    # Status KO por defecto
    status=1
    status_message=""

    service_info="$(cat ${services_data}/${service})"
    service_script="$(echo ${service_info}|cut -f1 -d',')"
    pid_file="$(echo ${service_info}|cut -f2 -d',')"
    service_executable="$(echo ${service_info}|cut -f3 -d',')"

    # Verificamos el pid indicado en el fichero PID y si corresponde a proceso en ejecución del servicio
    if [[ -r ${pid_file} ]]; then
        local service_pid=`cat ${pid_file}`
    
        # Corresponde el PID a un proceso del sistema?
        if ps -hq ${service_pid} > /dev/null; then
            # El PID corresponde al ejecutable del servicio?
            if [[ $(ps -hq ${service_pid} -o cmd|awk '{ print $1 }') == ${service_executable} ]]; then
                status=0    # OK
            else
                status_message="El proceso con PID ${service_pid} existe pero no corresponde al servicio ${service_executable}"
            fi;
        else
            status_message="No hay ningún proceso en el sistema con PID ${service_pid}"
        fi;
    else    
        if ps -e -o cmd|awk '{ print $1 }'|grep -q ${service_executable}; then
            status_message="El servicio está arrancado pero el fichero PID ${pid_file} no existe o no se puede leer"
        fi;
    fi;

    # Si el fichero PID no existe, o no es coherente buscamos procesos en ejecución del servicio
    if [[ ${status} -ne 0 ]]; then
        ps -e -o cmd|awk '{ print $1 }'|grep -q ${service_executable}
        status=$?
    fi;

    [[ -n ${status_message} ]] && printf "%s\n" "${status_message}"

    return ${status}
}