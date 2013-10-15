include ../../Makefile.incl

all: AntiZerg.ex4

AntiZerg.ex4: AntiZerg.mq4
	$(ML4) "AntiZerg.mq4"

install: all
	$(CP) "AntiZerg.mq4" $(EXP_DIR)
