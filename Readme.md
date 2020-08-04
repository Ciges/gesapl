# GesApl:  Aplicación de gestión de servicios

- *Versión: 1.00*
- *Autor: José Manuel Ciges Regueiro <jmanuel@ciges.net>*

---

En este repositorio está el código fuente de una aplicación para monitorizar y controlar los servicios de un sistema Linux.

Disponemos de los siguientes scripts:
- `gesapl`: Permite configurar los servicios a monitorizar
- `gesaplctl`:  Permite arrancar y detener servicios del sistema
- `gesapld`:  Demonio que una vez arrancado monitoriza los servicios del sistema en background, controlando su estado cada 60 segundos
- `gesaplinfo`:  Genera un informe del estado del demonio y los servicios configurados y los comandos ejecutados por los usuarios

Si se ejecuta cualquiera de estos scripts con la opción `-a` se mostrará una ayuda completa con las distintas opciones.

La configuración de la aplicación está en el archivo `/etc/gesapl/gesapl.conf`.

En la configuración por defecto:
- Los binarios de la aplicación se encuentran en `/usr/local/bin`
- La configuración de los servicios se encuentra en `/etc/gesapl/services`
- El demonio escribe toda la información en el archivo log `/var/log/gesapld.log`
- Los archivos temporales se almacenan en `/tmp/gesapl`

Los parámetros admitidos por los scripts son los indicados a continuación ...

---

## gesapl:  configuración de servicios

Permite configurar los servicios a monitorizar

Uso del script: `gesapl orden parámetros`

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
gesapl --registrar_servicio apache apache2 /var/run/apache2/apache2.pid /usr/sbin/apache2
gesapl --registrar_servicio mysql mysql /run/mysqld/mysql.pid /usr/sbin/mysqld
```

Dejar de monitorizar MySQL

```
gesapl --borrar_servicio mysql
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

En el repositorio hay un .tar.gz que permite desplegar rápidamente la aplicación. 

Los scripts han sido desarrollados y probados en un servidor **Linux Debian 10**. Para instalarlo y configurarlo en un servidor en el que, por ejemplo, tuviéramos corriendo tres servicios: Apache, MySQL y OpenSSH, haríamos lo siguiente:

Como root, descargamos y descomprimimos el paquete gesapl.tar.gz  en `/`

```bash
cd /
wget https://github.com/Ciges/gesapl/raw/master/gesapl.tar.gz
tar -xzpvf gesapl.tar.gz
```

Si ejecutamos `gesapl -ls` obtendremos el mensaje:
```
Ningún servicio está siendo monitorizado por gesapl
```

Añadimos la monitorización de los tres servicios que tenemos en el sistema

```bash
gesapl --registrar_servicio apache apache2 /var/run/apache2/apache2.pid /usr/sbin/apache2
gesapl --registrar_servicio mysql mysql /run/mysqld/mysqld.pid /usr/sbin/mysqld
gesapl --registrar_servicio ssh ssh /var/run/sshd.pid /usr/sbin/sshd
```

Y arrancamos el demonio

```bash
gesapld start
```

A partir de aquí podríamos ver cómo están siendo monitorizados los servicios visualizando el log `/var/log/gesapld.log`, lanzar una monitorización con el comando

```bash
gesapl -ms
```

U obtener un informe completo del estado de la aplicación con

```
gesaplinfo
```
