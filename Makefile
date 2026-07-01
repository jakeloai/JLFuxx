.PHONY: build install clean test run

BINARY_NAME=jfuxx
INSTALL_PATH=/usr/local/bin
GO=go

build:
	$(GO) build -ldflags="-s -w" -o $(BINARY_NAME) ./cmd/jfuxx

install: build
	@echo "Installing $(BINARY_NAME) to $(INSTALL_PATH)..."
	@cp $(BINARY_NAME) $(INSTALL_PATH)/
	@chmod +x $(INSTALL_PATH)/$(BINARY_NAME)
	@echo "Done! Run 'jfuxx -h' to verify."

uninstall:
	@rm -f $(INSTALL_PATH)/$(BINARY_NAME)
	@echo "Uninstalled."

clean:
	@rm -f $(BINARY_NAME)
	@rm -rf output/

test:
	$(GO) test ./...

run: build
	./$(BINARY_NAME) -h

dev:
	$(GO) run ./cmd/jfuxx -h
