
build:
	clang -O -c bithacks.c
	swiftc -import-objc-header bithacks.h -O hexacontatetra.swift world.swift main.swift bithacks.o

profile:
	clang -O -fdebug-info-for-profiling -c bithacks.c
	swiftc -import-objc-header bithacks.h -profile-coverage-mapping -profile-generate -O hexacontatetra.swift world.swift main.swift bithacks.o


