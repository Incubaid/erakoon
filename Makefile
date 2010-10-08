LIBDIR=$(shell erl -evel 'io:format("~s~n", [code:lib_dir()])' -s init stop -noshell)
APP_NAME="erakoon"
VSN="0.1"

all: compile

compile:
	@mkdir -p ebin
	@erl -make

clean:
	rm -f ebin/*.beam
	rm -f erl_crash.dump

test: all
	prove -v t/*.t

install: all
	mkdir -p $(LIBDIR)/${APP_NAME}-${VSN}/ebin
	for i in ebin/*.beam; do
		install $$i $(LIBDIR)/${APP_NAME}-${VSN}/$$i;
	done
