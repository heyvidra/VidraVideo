.PHONY: windows macos

# Build for Windows (requires dart and flutter in PATH)
# Handles enabling fonts, building, and then disabling fonts.
windows:
	@echo "Enabling Windows fonts..."
	dart tool/fonts_manager.dart enable
	@echo "Building Windows release..."
	-flutter build windows --release --split-debug-info=debug-info
	@echo "Disabling Windows fonts..."
	dart tool/fonts_manager.dart disable

# Build for macOS
macos:
	@echo "Disabling Windows fonts..."
	dart tool/fonts_manager.dart disable
	
	@echo "Building macOS release..."
	flutter build macos --release --split-debug-info=debug-info
