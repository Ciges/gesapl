# GesApl:  Aplicación de gestión de servicios

- *Versión: 2.00*
- *Autor: José Manuel Ciges Regueiro <jmanuel@ciges.net>*


---

En este repositorio está el código fuente de una aplicación para monitorizar y controlar los servicios de un sistema Linux.

Disponemos de los siguientes scripts:
- `gesapl2`: Permite configurar los servicios a monitorizar, esta es la versión 2, desarrollada en perl del original gesapl
- `gesaplctl`:  Permite arrancar y detener servicios del sistema
- `gesapld`:  Demonio que una vez arrancado monitoriza los servicios del sistema en background, controlando su estado cada 60 segundos
- `gesaplinfo`:  Genera un informe del estado del demonio y los servicios configurados y los comandos ejecutados por los usuarios

Si se ejecuta cualquiera de estos scripts con la opción `-a` se mostrará una ayuda completa con las distintas opciones.

La configuración de la aplicación está en el archivo `/etc/gesapl/gesapl2.cnf`.

En la configuración por defecto:
- Los binarios de la aplicación se encuentran en `/usr/local/bin`
- La configuración de los servicios se encuentra en `/etc/gesapl/services`
- El demonio escribe toda la información en el archivo log `/var/log/gesapld.log`
- Los archivos temporales se almacenan en `/tmp/gesapl`

Los parámetros admitidos por los scripts son los indicados a continuación ...

---

## gesapl:  configuración de servicios

Permite configurar los servicios a monitorizar

Uso del script: `gesapl2 orden parámetros`

Siendo orden una de las siguientes: `--monitorizar_servicios` (o `-ms` ), `--registrar_servicio` (o `-rs`), `--borrar_servicio` (o `-bs`),  `--listar_servicios` (o `-ls`), `--ayuda` (o `-a`)

* `-ms` | `--monitorizar_servicios` :  Monitoriza los servicios configurados

* `-rs` | `--registrar_servicio nombre script_de_arranque ruta_pid_file service_executable` :  Registra un servicio e inicia su monitorización

    - El nombre de servicio es arbitrario, es el nombre con el que gesapl lo va a tratar
    - El script de arranque es el nombre del script de arranque/parada en `/etc/init.d`
    - El último parámetro es la ruta del binario con el que se le ve en la lista de procesos del sistema

    Si el servicio ya ha sido configurado y no se desea cambiarla sólo se necesita el nombre

* `-bs` | `--borrar_servicio nombre` :  Borra el servicio indicado

* `-ls` | `--listar_servicios` :  Lista los servicios monitorizados y los parámetros registrados para cada uno

* `-a` | `--ayuda` :  Muestra la ayuda para este script

Ejemplos: 

Monitorizar Apache y MySQL

```
gesapl2 --registrar_servicio apache apache2 /var/run/apache2/apache2.pid /usr/sbin/apache2
gesapl2 --registrar_servicio mysql mysql /run/mysqld/mysql.pid /usr/sbin/mysqld
```

Dejar de monitorizar MySQL

```
gesapl2 --borrar_servicio mysql
```

## gesapctl:  control de servicios

Permite arrancar y detener servicios del sistema configurados

Uso del script: `gesaplctl orden parámetros`

Siendo orden una de las siguientes: `--arrancar_servicio` (o `-as`), `--detener_servicio`  (o `-ds`), `--reiniciar_servicio` (o `-rs`), `--listar-servicios` (o `-ls`), `--ayuda` (o `-a`)

* `-as` | `--arrancar_servicio nombre` :  arranca el servicio configurado con ese nombre

* `-ds` | `--detener_servicio nombre` :  detieene el servicio configurado con ese nombre

* `-rs` | `--reiniciar_servicio nombre` :  reinicia el servicio configurado con ese nombre

* `-ls` | `--listar_servicios` :  Lista los servicios configurados y los parámetros registrados para cada uno

* `-a` | `--ayuda` :  Muestra la ayuda para este script

Este script se debe de ejecutar con derechos de 'root'


## gesapld:  demonio de monitorización

Demonio para monitorizar los servicios

Uso del script : `gesapld start | stop | status`

El demonio vuelca toda la información en el log `/var/log/gesapld.log`

Este script solo inicia o detiene la monitorización. Para gestionar los servicios hay que usar `gesapl`


## gesaplinfo:  informe de estado de la aplicación

Muestra un informe completo del estado de la aplicación y, si se indica un correo electrónico, se envía por correo.

Uso del script: `gesaplinfo [ email ]`

El informe consta de
- Una relación de servicios monitorizados
- Estado de cada uno de estos servicios. Fecha y hora del último control realizado
- Últimos 20 comandos ejecutados en GesApl, con sus parámetros, fecha y hora de ejecución y usuario que lo lanzó
- Configuración registrada de cada servicio

## Instrucciones de instalación y ejemplo de configuración y uso

Los scripts han sido desarrollados y probados en un servidor **Linux Debian 10**. 

Para instalarlo y configurarlo en un servidor en el que, por ejemplo, tuviéramos corriendo tres servicios: Apache, MySQL y OpenSSH, haríamos lo siguiente:

El script principal `gesapl2` está desarrollado en Perl y es necesario instalar los siguientes **módulos Perl**, normalmente no incluídos en una instalación estándar:
- Proc::ProcessTable
- Log::Log4Perl

En Debian la instalación se hace con el siguiente comando:
```bash
apt install libproc-processtable-perl liblog-log4perl-perl
```

Una vez instaladas las dependencias de Perl, lo más práctico sería clonar directamente el código del repositorio de Github y como root ejecutar el script install.sh

```bash
git clone https://github.com/Ciges/gesapl
./gesapl/install.sh
```

Este script instala los archivos en las siguientes rutas del sistema
- `/etc/gesapl` :  Configuración de la aplicación
- `/usr/local/bin` :  Scripts ejecutables
- `/usr/local/lib/gesapl` :  Clases de Perl y scripts de la shell desarrollados para GesApl

Ya está configurado por defecto en el registro la monitorización de Apache, MySQL y SSH, con los parámetros de scripts en /etc/init.d, fichero pid y proceso que encontramos en una Debian 10.

Si ejecutamos `gesapl2 -ls` deberiamos obtener el siguiente mensje:
```
Servicios monitorizados: apache mysql ssh 

Configuración de los servicios:
    - apache:  script de arranque=/etc/init.d/apache2, fichero pid=/var/run/apache2/apache2.pid, proceso=/usr/sbin/apache2
    - mysql:  script de arranque=/etc/init.d/mysql, fichero pid=/var/run/mysqld/mysqld.pid, proceso=/usr/sbin/mysqld
    - ssh:  script de arranque=/etc/init.d/ssh, fichero pid=/var/run/sshd.pid, proceso=/usr/sbin/sshd
```

Suponiendo que Apache y MySQL estén arrancados


Y arrancamos el demonio

```bash
gesapld start
```

A partir de aquí podríamos ver cómo están siendo monitorizados los servicios visualizando el log `/var/log/gesapld2.log`, lanzar una monitorización con el comando

```bash
gesapl2 -ms
```

U obtener un informe completo del estado de la aplicación con

```
gesaplinfo
```
