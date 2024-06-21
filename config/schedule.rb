# frozen_string_literal: true

# set :output, "/path/to/my/cron_log.log"

every :sunday, at: "6am" do
  command "passenger-config restart-app /var/www/workbench-admin/current"
end
