# frozen_string_literal: true

set :rails_env, "staging"
set :branch, ENV.fetch("BRANCH", "main")

# The central deploy workflow passes instance ids in DEPLOY_HOSTS; by hand, use the ssh alias.
hosts = ENV["DEPLOY_HOSTS"].to_s.split(",")
hosts = ["workbench-admin-staging.us-east-1"] if hosts.empty?
hosts.each { |host| server host, user: "deployer", roles: %w[app web db] }

# Postgres runs on the box and nothing else creates the database.
before "deploy:migrate", "deploy:create_database"
