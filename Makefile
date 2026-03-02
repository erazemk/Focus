APP_NAME := Focus
APP_BUNDLE := $(APP_NAME).app
BUILD_DIR := .build
APP_DIR := $(BUILD_DIR)/$(APP_BUNDLE)
INSTALL_DIR := $(HOME)/Applications
BIN_PATH := .build/release/$(APP_NAME)
ICON_FILE := AppIcon.icns

.PHONY: all build install

all: install

build:
	swift build -c release
	mkdir -p $(APP_DIR)/Contents/MacOS
	mkdir -p $(APP_DIR)/Contents/Resources
	cp $(BIN_PATH) $(APP_DIR)/Contents/MacOS/$(APP_NAME)
	cp Info.plist $(APP_DIR)/Contents/Info.plist
	cp $(ICON_FILE) $(APP_DIR)/Contents/Resources/$(ICON_FILE)

install: build
	@if pgrep -x "$(APP_NAME)" >/dev/null; then \
		killall "$(APP_NAME)"; \
	fi
	@if [ -d "$(INSTALL_DIR)/$(APP_BUNDLE)" ]; then \
		trash "$(INSTALL_DIR)/$(APP_BUNDLE)"; \
	fi
	mkdir -p "$(INSTALL_DIR)"
	cp -R "$(APP_DIR)" "$(INSTALL_DIR)/"

release: build
	ditto -c -k --sequesterRsrc --keepParent "$(APP_DIR)" "$(BUILD_DIR)/$(APP_NAME).zip"
