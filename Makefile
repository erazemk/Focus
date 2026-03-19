APP_NAME := Focus
APP_BUNDLE := $(APP_NAME).app
PACKAGE_DIR := src
BUILD_DIR := .build
APP_DIR := $(BUILD_DIR)/$(APP_BUNDLE)
INSTALL_DIR := $(HOME)/Applications
BUNDLE_DIR := $(PACKAGE_DIR)/Bundle

install: build
	@if pgrep -x "$(APP_NAME)" >/dev/null; then \
		killall "$(APP_NAME)"; \
	fi
	@if [ -d "$(INSTALL_DIR)/$(APP_BUNDLE)" ]; then \
		trash "$(INSTALL_DIR)/$(APP_BUNDLE)"; \
	fi
	mkdir -p "$(INSTALL_DIR)"
	cp -R "$(APP_DIR)" "$(INSTALL_DIR)/"
.PHONY: install

build:
	swift build --package-path $(PACKAGE_DIR) --scratch-path $(BUILD_DIR) -c release
	mkdir -p $(APP_DIR)/Contents/MacOS
	mkdir -p $(APP_DIR)/Contents/Resources
	cp $(BUILD_DIR)/release/$(APP_NAME) $(APP_DIR)/Contents/MacOS/$(APP_NAME)
	cp $(BUNDLE_DIR)/Info.plist $(APP_DIR)/Contents/Info.plist
	cp $(BUNDLE_DIR)/Resources/AppIcon.icns $(APP_DIR)/Contents/Resources/AppIcon.icns
.PHONY: build
