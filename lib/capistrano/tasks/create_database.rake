# frozen_string_literal: true

namespace :deploy do
  desc "Create the database if it does not exist"
  task :create_database do
    on primary(:db) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, "db:create"
        end
      end
    end
  end
end
