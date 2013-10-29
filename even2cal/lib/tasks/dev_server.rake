task :server do

  port = ENV['PORT'] ? ENV['PORT'] : '3000'
  puts 'start unicorn development'

  sh "cd #{Rails.root} && RAILS_ENV=development unicorn -p #{port}"
end

# an alias task
task :s => :server
