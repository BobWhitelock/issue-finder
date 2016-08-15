
.PHONY: all test

all: test

test:
	rspec -I src/
