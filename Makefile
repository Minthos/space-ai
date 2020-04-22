
ARGS = -O
DEBUG = -g
CLANG_ARGS = -O
CLANG_DEBUG = -g
SRC = *.swift
OBJ = *.o
INCLUDES = -import-objc-header bithacks.h 

build:
	clang $(CLANG_ARGS) -c *.c
	swiftc $(INCLUDES) $(ARGS) $(SRC) $(OBJ)

debug:
	clang $(CLANG_DEBUG) -c *.c
	swiftc $(INCLUDES) $(DEBUG) $(SRC) $(OBJ)
	cp main space-ai/.build/x86_64-unknown-linux-gnu/debug/space-ai

profile:
	clang $(CLANG_ARGS) -fdebug-info-for-profiling -c *.c
	swiftc $(INCLUDES) -profile-coverage-mapping -profile-generate $(ARGS) $(SRC) $(OBJ)
	./main
	llvm-profdata merge default.profraw -o default.profdata

clean:
	rm default.prof* cachegrind.out.* *.o || echo 'no worries'
	git status

