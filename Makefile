
build:
	clang -O -c bithacks.c
	swiftc -import-objc-header bithacks.h -O hexacontatetra.swift world.swift main.swift bithacks.o

