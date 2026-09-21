require 'xcodeproj'
project_path = 'Telegram.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Telegram' }

phase = target.shell_script_build_phases.find { |p| p.name == "Fix Shallow Bundles" }
phase.shell_script = <<-SCRIPT
#!/bin/bash
# Restructure shallow bundles to deep bundles

fix_shallow_bundle() {
    FRAMEWORK_PATH="$TARGET_BUILD_DIR/$FULL_PRODUCT_NAME/Contents/Frameworks/$1.framework"
    if [ ! -d "$FRAMEWORK_PATH" ]; then
        return
    fi
    if [ -d "$FRAMEWORK_PATH/Versions" ]; then
        return
    fi
    
    echo "Fixing shallow bundle: $1"
    mkdir -p "$FRAMEWORK_PATH/Versions/A/Resources"
    
    # Move binary
    if [ -f "$FRAMEWORK_PATH/$1" ]; then
        mv "$FRAMEWORK_PATH/$1" "$FRAMEWORK_PATH/Versions/A/"
    fi
    
    # Move Info.plist
    if [ -f "$FRAMEWORK_PATH/Info.plist" ]; then
        mv "$FRAMEWORK_PATH/Info.plist" "$FRAMEWORK_PATH/Versions/A/Resources/"
    fi
    
    # Move other directories
    for dir in Headers Modules PrivateHeaders; do
        if [ -d "$FRAMEWORK_PATH/$dir" ]; then
            mv "$FRAMEWORK_PATH/$dir" "$FRAMEWORK_PATH/Versions/A/"
            ln -sf "Versions/Current/$dir" "$FRAMEWORK_PATH/$dir"
        fi
    done
    
    ln -sf "A" "$FRAMEWORK_PATH/Versions/Current"
    ln -sf "Versions/Current/$1" "$FRAMEWORK_PATH/$1"
    ln -sf "Versions/Current/Resources" "$FRAMEWORK_PATH/Resources"
}

fix_shallow_bundle "GoogleAppMeasurement"
fix_shallow_bundle "FirebaseAnalytics"
fix_shallow_bundle "GoogleAppMeasurementIdentitySupport"

SCRIPT
project.save
puts "Updated Fix Shallow Bundles phase"
