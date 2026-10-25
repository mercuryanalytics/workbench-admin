# frozen_string_literal: true

lock "~> 3.18"

set :application, "workbench-admin"
set :repo_url, "git@github.com:mercuryanalytics/workbench-admin.git"

set :branch, "main"

set :ssh_options, forward_agent: true
set :log_level, :info

set :rbenv_type, :fullstaq
set :rbenv_ruby, "3.3.4-jemalloc"
set :default_env, path: "/usr/lib/fullstaq-ruby/versions/3.3.4-jemalloc/bin:$HOME/.npm-global/bin:$PATH"

# Default value for :linked_files is []
append :linked_files, "config/credentials/production.key"

append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"
