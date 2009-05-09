BIN_INSTALL_DIR= /usr/local/sbin
CONF_INSTALL_DIR= /etc

all: bin/autodrop

bin/autodrop: bin/autodrop.rb
	cp -f bin/autodrop.rb bin/autodrop
	chmod +x bin/autodrop

clean:
distclean: clean
	rm -f bin/autodrop
	rm -rf pkg

install: all
	mkdir -p ${BIN_INSTALL_DIR}
	mkdir -p ${CONF_INSTALL_DIR}
	cp -f autodrop ${BIN_INSTALL_DIR}/autodrop
	cp -f conf/autodrop.conf.default \
		${CONF_INSTALL_DIR}/autodrop.conf.default

uninstall:
	rm -f ${BIN_INSTALL_DIR}/autodrop
	rm -f ${CONF_INSTALL_DIR}/autodrop.conf.default

gem:
	rake gem
