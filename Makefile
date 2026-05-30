# Grand Pattern Fibonacci Dual-Direction Architecture - Chapel
CHPL = chpl
CHPLFLAGS = --main-module TestGP -O2
SRCDIR = src
TESTDIR = tests

SRCS = $(SRCDIR)/GPTypes.chpl $(SRCDIR)/GPOps.chpl
TEST_SRC = $(TESTDIR)/test_gp.chpl

.PHONY: all test clean

all: test_gp

test_gp: $(SRCS) $(TEST_SRC)
	$(CHPL) $(CHPLFLAGS) $(SRCS) $(TEST_SRC) -o test_gp

test: test_gp
	./test_gp

clean:
	rm -f test_gp
