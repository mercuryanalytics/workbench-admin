# frozen_string_literal: true

set :rails_env, "production"
set :branch, ENV.fetch("BRANCH", "main")

# The central deploy workflow passes instance ids in DEPLOY_HOSTS; by hand, use the ssh alias.
hosts = ENV["DEPLOY_HOSTS"].to_s.split(",")
hosts = ["workbench-admin-production.us-east-1"] if hosts.empty?
hosts.each { |host| server host, user: "deployer", roles: %w[app web db] }

# Postgres runs on the box (the AMI only has the client); nothing else creates the role or database.
set :required_packages, %w[postgresql]
before "deploy:migrate", "deploy:create_database"
