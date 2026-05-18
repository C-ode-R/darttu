ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: server client pubget

pubget:
	dart pub get

server:
	cd $(ROOT) && dart packages/darttu_server/bin/darttu_server.dart

client:
	cd $(ROOT) && dart packages/darttu_client/bin/darttu_client.dart
