# frozen_string_literal: true

lock "~> 3.16.0"

set :application, "workbench-admin"
set :repo_url, "git@github.com:mercuryanalytics/workbench-admin.git"

set :branch, "main"

set :rbenv_ruby, "3.1.0"

# Default value for :linked_files is []
append :linked_files, "config/master.key"

append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"
