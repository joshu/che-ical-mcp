BINARY_NAME := CheICalMCP

# Swift 6 Concurrency Guard:
# Try native build first; fall back to Swift 5 language mode if upstream
# dependencies have strict concurrency errors (swift-sdk#214).
# Remove FALLBACK_FLAGS once the upstream issue is fixed.
FALLBACK_FLAGS := $(shell swift build 2>&1 | grep -q "SendingRisksDataRace" && echo "-Xswiftc -swift-version -Xswiftc 5")

.PHONY: build release install clean test

build:
	swift build $(FALLBACK_FLAGS)

release:
	swift build -c release $(FALLBACK_FLAGS)

install: release
	cp .build/release/$(BINARY_NAME) ~/bin/$(BINARY_NAME)
	chmod +x ~/bin/$(BINARY_NAME)
	codesign --force --sign - ~/bin/$(BINARY_NAME)
	@echo "Installed: ~/bin/$(BINARY_NAME)"

test:
	swift test $(FALLBACK_FLAGS)

clean:
	swift package clean
