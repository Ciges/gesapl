#!/bin/sh
cd /
chown -Rh root:root /usr/local
mv /etc/gesapl /etc/gesapl_SAVE
cp -a /usr/local/etc/gesapl /etc/gesapl
rm /etc/gesapl/services/* var/run/gesapld/* var/log/gesapld.log
(umask 0111; touch var/log/gesapld.log)
tar -czpvf gesapl.tar.gz usr/local/bin/gesapl* usr/local/lib/gesapl etc/gesapl var/run/gesapld var/log/gesapld.log

