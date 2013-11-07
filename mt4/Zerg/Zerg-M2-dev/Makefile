include ../../Makefile.incl

all: Zerg\ EA-M2-dev.ex4

Zerg\ EA-M2-dev.ex4: Zerg\ EA-M2-dev.mq4
	$(ML4) "Zerg EA-M2-dev.mq4"

install: all
	$(CP) "Zerg EA-M2-dev.mq4" $(EXP_DIR)
