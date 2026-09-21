require 'xcodeproj'
project_path = 'Telegram.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Telegram' }

main_group = project.main_group['Telegram-Mac']
unless main_group
    puts "Error finding Telegram-Mac group"
    exit 1
end

files_to_add = ['Telegram-Mac/GeminiService.swift', 'Telegram-Mac/CherrygramConfiguration.swift', 'Telegram-Mac/CherrygramSettingsViewController.swift']

files_to_add.each do |file_path|
    file_name = file_path.split('/').last
    unless main_group.files.any? { |f| f.path == file_name }
        file_reference = main_group.new_file(file_name)
        target.source_build_phase.add_file_reference(file_reference)
        puts "Added #{file_name} to Xcode project."
    else
        puts "#{file_name} already in project."
    end
end

project.save
