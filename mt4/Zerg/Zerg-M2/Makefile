include ../../Makefile.incl

all: Zerg\ EA-M2.ex4

Zerg\ EA-M2.ex4: Zerg\ EA-M2.mq4
	$(ML4) "Zerg EA-M2.mq4"

install: all
	$(CP) "Zerg EA-M2.mq4" $(EXP_DIR)
