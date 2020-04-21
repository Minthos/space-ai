
CLANG_ARGS = -O
ARGS = -O
IMPORTS = -import-objc-header bithacks.h 
SRC = *.swift
OBJ = *.o

build:
	clang $(CLANG_ARGS) -c *.c
	swiftc $(IMPORTS) $(ARGS) $(SRC) $(OBJ)

profile:
	clang $(CLANG_ARGS) -fdebug-info-for-profiling -c *.c
	swiftc $(IMPORTS) -profile-coverage-mapping -profile-generate $(ARGS) $(SRC) $(OBJ)
	./main
	llvm-profdata merge default.profraw -o default.profdata

clean:
	rm default.prof* cachegrind.out.* *.o || echo 'no worries'
	git status

