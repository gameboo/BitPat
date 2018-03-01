# BSV compiler flags
BSC = bsc
RECIPEDIR = /home/aj443/devstuff/Recipe
BSVPATH = +:$(RECIPEDIR)
BSCFLAGS = -p $(BSVPATH) -wait-for-license -suppress-warnings S0015 \
           -suppress-warnings G0023 \
           -steps-warn-interval 400000 -check-assert \
           +RTS -K32M -RTS

# Top level module
TOPFILE = Top.bsv
TOPMOD = top

.PHONY: sim
sim: $(TOPMOD)

.PHONY: verilog
verilog: $(TOPMOD).v

$(TOPMOD): *.bsv
	$(BSC) $(BSCFLAGS) $(DEFS) -D SIMULATE -sim -g $(TOPMOD) -u $(TOPFILE)
	$(BSC) $(BSCFLAGS) -sim -o $(TOPMOD) -e $(TOPMOD)

$(TOPMOD).v: *.bsv $(QP)/InstrMem.mif
	$(BSC) $(BSCFLAGS) -opt-undetermined-vals -unspecified-to X \
         $(DEFS) -u -verilog -g $(TOPMOD) $(TOPFILE)

.PHONY: clean
clean:
	rm -f *.cxx *.o *.h *.ba *.bo *.so *.ipinfo *.v $(TOPMOD)
