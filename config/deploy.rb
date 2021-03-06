set :application, 'coruscope'
set :repo_url, 'git@github.com:jrietema/coruscope.git'
set :branch, 'master'
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

set :deploy_to, '/opt/rails/coruscope'
set :scm, :git

set :format, :pretty
# set :log_level, :debug
# set :pty, true

set :rvm_ruby_string, '2.0.0'

set :linked_files, %w{config/database.yml config/initializers/secret_token.rb log/production.log}
set :linked_dirs, %w{bin log tmp/pids tmp/sockets public/assets public/images/ail public/system}

set :bundle_gemfile, -> { release_path.join('Gemfile') }
set :bundle_dir, -> { shared_path.join('bundle') }

SSHKit.config.command_map[:rake]  = "bundle exec rake"
SSHKit.config.command_map[:rails] = "bundle exec rails"

set :keep_releases, 5

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  after 'symlink:release', 'deploy:symlink:shared'

  after :finishing, 'deploy:cleanup'

end
