#!/bin/bash

if [[ $XDEBUG_ENABLED == true ]]; then
	echo "zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20151012/xdebug.so" | sudo tee -a /usr/local/etc/php/conf.d/xdebug.ini
	echo "xdebug.var_display_max_depth=5" | sudo tee -a /usr/local/etc/php/conf.d/xdebug.ini
fi

if [[ $NR_ENABLED == true ]]; then
	sudo sed -i -e "s/"REPLACE_WITH_REAL_KEY"/$NR_LICENSE_KEY/g" /scripts/newrelic.ini
	sudo sed -i -e "s/PHP Application/$NR_APP_NAME/g" /scripts/newrelic.ini
	sudo cp /scripts/newrelic.ini /usr/local/etc/php/conf.d/newrelic.ini
fi

if [[ $SESSION_HANDLER == true ]]; then
	echo "session.save_handler = $SESSION_HANDLER_NAME" | sudo tee -a /usr/local/etc/php/conf.d/session-handler.ini
	echo "session.save_path = $SESSION_HANDLER_PATH" | sudo tee -a /usr/local/etc/php/conf.d/session-handler.ini
fi

apache2-foreground