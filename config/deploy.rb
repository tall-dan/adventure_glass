require "rvm/capistrano"
require 'bundler/capistrano' 
require "whenever/capistrano"

set :application, "Genesys Dashboard"
set :repository,  "https://git.enova.com/dynamo/adventure_glass.git"
set :deploy_to, "/export/web/adventure_glass"
server 'gendashboard01.chi.enova.com', :app, :web, :db, :primary => true
server 'gendashboard01.gur.enova.com', :app, :web, :primary => false

set :user, "deployuser"
set :rails_env, :production

set :scm, :git
set :use_sudo, false
set :ssh_options, { :forward_agent => true }
set :deploy_via, :remote_cache
set :rvm_type, :system
set :bundle_gemfile,  "Gemfile"
set :bundle_cmd,      "bundle"
set :bundle_dir,      File.join(fetch(:shared_path), 'bundle')
set :bundle_flags, "--deployment "

set :whenever_command, "RAILS_ENV=#{rails_env} bundle exec whenever" 

set :branch do
  default_tag = `git tag`.split("\n").last

  tag = Capistrano::CLI.ui.ask "Tag to deploy (make sure to push the tag first): [#{default_tag}] "
  tag = default_tag if tag.empty?
  tag
end

BP = 'bundle exec bluepill --no-privileged'

after "deploy:update", "bluepill:quit", "bluepill:start", "whenever:write"
namespace :bluepill do
  desc "Stop processes that bluepill is monitoring and quit bluepill"
  task :quit, :roles => [:app] do
    run "cd #{latest_release} && #{BP} adventure_glass stop && sleep 2 && #{BP} adventure_glass quit && sleep 2"
  end

  desc "Load bluepill configuration and start it"
  task :start, :roles => [:app] do
    run "cd #{release_path} && #{BP} load #{latest_release}/config/unicorn.pill"
  end

  desc "Prints bluepills monitored processes statuses"
  task :status, :roles => [:app] do
    run "bundle exec bluepill status"
  end
end

namespace :whenever do
  desc "write crontab"
  task :write, :roles => :db do
      run "cd /export/web/adventure_glass/current && RAILS_ENV=#{rails_env} bundle exec whenever -w"
  end
end

namespace :bundle do
  task :install, :roles => :app do
    shared_dir = File.join(shared_path, 'bundle')
    run "cd #{release_path} && export BUNDLE_ENV=#{rails_env}  && bundle check 2>&1 > /dev/null; if [ $? -ne 0 ] ; then  bundle install --gemfile #{release_path}/Gemfile --path  #{shared_dir} --deployment --without development test ; fi"
    on_rollback do
      if previous_release
        run "cd #{previous_release}  && bundle check 2>&1 > /dev/null; && if [ $? -ne 0 ] ; then bundle install #{shared_dir} --without test && bundle install #{shared_dir} --binstubs; fi"
      else
        logger.important "no previous release to rollback to, rollback of bundler:install skipped"
      end
    end
  end
end

before "deploy:assets:precompile", "db:migrate"
namespace :db do
  desc "setup db"
  task :setup, :roles => :db do
    run "cd #{release_path} && export BUNDLE_ENV=deployment && RAILS_ENV=deployment bundle exec rake db:setup"
    run "cd #{release_path} && script/rails runner -e production \"CallRep.update_all_reps('us')\""
    run "cd #{release_path} && script/rails runner -e production \"CallRep.update_all_reps('uk')\""
    run "cd #{release_path} && script/rails runner -e production \"CallRep.update_all_reps('jv')\""
    run "cd #{release_path} && script/rails runner -e production \"CallRep.set_active_reps('us')\""
    run "cd #{release_path} && script/rails runner -e production \"CallRep.set_active_reps('uk')\""
    run "cd #{release_path} && script/rails runner -e production \"CallRep.set_active_reps('jv')\""
  end
  task :migrate, :roles => :db do
    run "cd #{release_path} && RAILS_ENV=#{rails_env} bundle exec rake db:migrate"
  end
end