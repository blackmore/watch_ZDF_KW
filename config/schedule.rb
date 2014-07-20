require './config/enviroment'
# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# run this comand from inside the root folder of this project to create
# a crontab
# ~$ whenever --update-crontab watch_AD

set :output, { :standard => "#{ROOT}/log/watch.log", :error => "#{ROOT}/log/watch.errors.log" }

every 1.minute do
  command "ruby #{ROOT}/watch.rb"
end
