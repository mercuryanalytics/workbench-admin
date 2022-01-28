# frozen_string_literal: true

server "workbench-admin.us-east-1", user: "deployer", roles: %w[app web]

set :ssh_options, forward_agent: true
set :log_level, :info
