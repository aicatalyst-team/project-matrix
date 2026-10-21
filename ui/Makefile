.PHONY: dev-bff dev-frontend build type-check validate-host

dev-bff:
	BFF_USER_HEADER=X-Forwarded-User go run ../controller/cmd/bff

dev-frontend:
	cd frontend && npm run start:dev

build:
	cd frontend && npm run build

type-check:
	cd frontend && npm run type-check

validate-host:
	bash ./validate-host-integration.sh --require-build

