# frozen_string_literal: true

require "shellwords"

namespace :deploy do
  desc "Create the deployer Postgres role (CREATEDB only, not a superuser) and the database if they do not exist"
  task :create_database do
    on primary(:db) do
      role_check = "SELECT 1 FROM pg_roles WHERE rolname = 'deployer'".shellescape
      has_role = capture(:sudo, "-u", "postgres", :psql, "-tAc", role_check).strip == "1"
      execute :sudo, "-u", "postgres", :createuser, "-d", "deployer" unless has_role

      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, "db:create"
        end
      end
    end
  end
end
