include ../../Makefile.incl

all: Zerg\ EA-noLock.ex4

Zerg\ EA-noLock.ex4: Zerg\ EA-noLock.mq4
	$(ML4) "Zerg EA-noLock.mq4"

install: all
	$(CP) "Zerg EA-noLock.mq4" $(EXP_DIR)
