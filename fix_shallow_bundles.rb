require 'xcodeproj'
project_path = 'Telegram.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Telegram' }

# Check if phase already exists
existing_phase = target.shell_script_build_phases.find { |p| p.name == "Fix Shallow Bundles" }
if existing_phase
    puts "Phase already exists"
else
    phase = target.new_shell_script_build_phase("Fix Shallow Bundles")
    phase.shell_script = <<-SCRIPT
# Remove Info.plist from shallow bundles before validation
rm -f "$TARGET_BUILD_DIR/$FULL_PRODUCT_NAME/Contents/Frameworks/GoogleAppMeasurement.framework/Info.plist"
rm -f "$TARGET_BUILD_DIR/$FULL_PRODUCT_NAME/Contents/Frameworks/FirebaseAnalytics.framework/Info.plist"
rm -f "$TARGET_BUILD_DIR/$FULL_PRODUCT_NAME/Contents/Frameworks/GoogleAppMeasurementIdentitySupport.framework/Info.plist"
SCRIPT
    # Move it to the very end
    target.build_phases.delete(phase)
    target.build_phases << phase
    project.save
    puts "Added Fix Shallow Bundles phase"
end
