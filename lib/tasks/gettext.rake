# lib/tasks/gettext.rake

desc "Update pot/po files."
task :updatepo do
  require 'gettext_rails/tools'
  GetText.update_pofiles("application",
                         Dir.glob("{app,config,components,lib}/**/*.{rb,erb,rjs}"),
                         "application 1.0.0"
                         )
end

desc "Create mo-files"
task :makemo do
  require 'gettext_rails/tools'
  GetText.create_mofiles
end