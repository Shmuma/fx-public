include ../../Makefile.incl

all: Zerg\ EA-M1.ex4

Zerg\ EA-M1.ex4: Zerg\ EA-M1.mq4
	$(ML4) "Zerg EA-M1.mq4"

install: all
	$(CP) "Zerg EA-M1.mq4" $(EXP_DIR)
