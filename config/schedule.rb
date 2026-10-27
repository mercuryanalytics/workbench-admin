# frozen_string_literal: true

# Cron has no rbenv; a login shell finds ruby and bundler.
set :job_template, "bash -l -c ':job'"

# Intuit refresh tokens lapse after about 100 days unused; refreshing weekly keeps an idle app connected.
every :wednesday, at: "6am" do
  rake "quickbooks:keep_alive"
end

# Early Monday ET, so the week that just ended (Monday to Sunday) is complete.
every :monday, at: "6am" do
  rake "report:weekly"
end
