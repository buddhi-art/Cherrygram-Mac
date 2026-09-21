require 'xcodeproj'
project_path = 'Telegram.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Telegram' }

main_group = project.main_group['Telegram-Mac']

file_ref = main_group.files.find { |f| f.path == 'CherrygramConfiguration.swift' }
if file_ref
    target.source_build_phase.remove_file_reference(file_ref)
    file_ref.remove_from_project
    puts "Removed CherrygramConfiguration.swift from Xcode project."
else
    puts "Not found in project."
end

project.save
