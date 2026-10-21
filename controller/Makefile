GO ?= go

.PHONY: test vet fmt

test:
	$(GO) test ./...

vet:
	$(GO) vet ./...

fmt:
	$(GO)fmt -w api controllers internal cmd
