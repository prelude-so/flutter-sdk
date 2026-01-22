Pod::Spec.new do |s|
  s.name             = 'prelude_flutter_sdk'
  s.version          = '0.1.0'
  s.summary          = 'Prelude Flutter SDK.'
  s.description      = <<-DESC
Flutter SDK that allows Flutter applications to use the native Prelude SDKs for Android and iOS.
                       DESC
  s.homepage         = 'https://prelude.so/'
  s.license          = "Apache-2.0"
  s.author           = "Prelude <hello@prelude.so> (https://github.com/prelude-so)"
  s.source           = { git: 'https://github.com/prelude-so/flutter-sdk.git' }
  s.resource_bundles = {'prelude_flutter_sdk_privacy' => ['prelude_flutter_sdk/Sources/prelude_flutter_sdk/PrivacyInfo.xcprivacy']}
  s.platforms        = { :ios => '15.1' }
  s.static_framework = true
  s.swift_version    = '5.4'
  s.module_name      = 'prelude_flutter_sdk'
  
  apple_sdk_version = '0.2.5'
  sdk_path = File.join(__dir__, 'sdk')
  
  require 'fileutils'
  framework_dir = File.join(sdk_path, 'core', 'PreludeCore.xcframework')
  framework_valid = File.directory?(framework_dir) && File.directory?(File.join(framework_dir, 'ios-arm64'))
  
  unless framework_valid
    puts "Prelude Apple SDK not found. Downloading version #{apple_sdk_version}..."
    
    download_script = <<-SCRIPT
      set -e
      SDK_VERSION="#{apple_sdk_version}"
      SDK_PATH="#{sdk_path}"
      
      rm -rf "$SDK_PATH"
      mkdir -p "$SDK_PATH/core"
      mkdir -p "$SDK_PATH/Sources"
      
      echo "Downloading Prelude Apple SDK sources..."
      curl -L --fail "https://github.com/prelude-so/apple-sdk/archive/refs/tags/$SDK_VERSION.zip" -o "$SDK_PATH/apple-sdk.zip"
      unzip -q "$SDK_PATH/apple-sdk.zip" -d "$SDK_PATH/tmp"
      EXTRACTED_DIR=$(ls "$SDK_PATH/tmp")
      
      if [ -d "$SDK_PATH/tmp/$EXTRACTED_DIR/Sources/Prelude" ]; then
        mv "$SDK_PATH/tmp/$EXTRACTED_DIR/Sources/Prelude" "$SDK_PATH/Sources/"
      fi
      
      XCFRAMEWORK_URL=$(grep -o 'url:[[:space:]]*"[^"]*xcframework.zip"' "$SDK_PATH/tmp/$EXTRACTED_DIR/Package.swift" | sed 's/url:[[:space:]]*"//;s/"$//')
      
      echo "Downloading Prelude Apple SDK binaries..."
      curl -L --fail "$XCFRAMEWORK_URL" -o "$SDK_PATH/xcframework.zip"
      unzip -q "$SDK_PATH/xcframework.zip" -d "$SDK_PATH/core"
      
      rm -rf "$SDK_PATH/tmp" "$SDK_PATH/apple-sdk.zip" "$SDK_PATH/xcframework.zip"
      
      echo "Prelude Apple SDK downloaded successfully."
    SCRIPT
    
    system('/bin/sh', '-c', download_script)
    
    unless File.directory?(framework_dir) && File.directory?(File.join(framework_dir, 'ios-arm64'))
      raise "Failed to download Prelude Apple SDK. Please check your internet connection and try again."
    end
  end
  
  s.dependency 'Flutter'
  s.vendored_frameworks = 'sdk/core/PreludeCore.xcframework'
  
  # Include all source files
  s.source_files = '{sdk,prelude_flutter_sdk}/Sources/**/*.swift'
  s.exclude_files = '**/*.xcprivacy'
  
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_COMPILATION_MODE' => 'wholemodule',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
end
