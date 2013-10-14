all:
	/bin/echo "Run \`make install\`"

install:
	/bin/mkdir /usr/local/vtundfix
	/bin/mkdir /var/vtundfix
	/bin/chown vtundfix:vtundfix /var/vtundfix
	/bin/cp ./vtundfix /usr/local/vtundfix/vtundfix
	/bin/cp ./vtundctl /usr/local/vtundfix/vtundctl
	/bin/cp ./vtundfix.conf /usr/local/vtundfix/vtundfix.conf
	/bin/cp ./vtundfix_init /usr/local/vtundfix/vtundfix_init
	/bin/cp ./vtundfix_cron /usr/local/vtundfix/vtundfix_cron
	/bin/cp ./vtundfix_crontab /usr/local/vtundfix/vtundfix_crontab
	/bin/cp ./vtundfix.8 /usr/local/vtundfix/vtundfix.8
	/bin/cp ./vtundfix_logrotate /usr/local/vtundfix/vtundfix_logrotate
	/bin/ln -s /usr/local/vtundfix/vtundfix.8 /usr/share/man/man8/vtundfix.8
	/bin/ln -s /usr/local/vtundfix/vtundfix /usr/sbin/vtundfix
	/bin/ln -s /usr/local/vtundfix/vtundctl /usr/sbin/vtundctl
	/bin/ln -s /usr/local/vtundfix/vtundfix_init /etc/init.d/vtundfix
	/bin/ln -s /usr/local/vtundfix/vtundfix_crontab /etc/cron.d/vtundfix
	/bin/ln -s /usr/local/vtundfix/vtundfix.conf /etc/vtundfix.conf
	/bin/ln -s /usr/local/vtundfix/vtundfix_logrotate /etc/logrotate.d/vtundfix
	/bin/touch /var/vtundfix/vtundfix.log

clean:
	/bin/rm -rf /usr/local/vtundfix
	/bin/rm -rf /var/vtundfix
	/bin/rm -f /etc/init.d/vtundfix /usr/sbin/vtund{fix,ctl} /etc/vtundfix.conf
	/bin/rm -f /usr/local/share/man/man8/vtundfix.8
	/bin/rm -f /usr/share/man/man8/vtundfix.8
	/bin/rm -f /etc/vtundfix.conf
	/bin/rm -f /etc/cron.d/vtundfix
	/bin/rm -f /etc/logrotate.d/vtundfix
