# Rails upgrades — workbench-admin intentional-config log

After `bin/rails app:update` rewrites the generated config, this file tells "ours, keep it" from
"Rails' template, took it back." Same idea as thoth's `doc/rails-upgrades.md`.

**Process:** follow the Rails Guide "Upgrading Ruby on Rails", one minor version at a time (7.0 → 7.1 → 7.2 →
8.0 → 8.1): bump the `rails` constraint, `bundle update rails`, run the specs, `yes a | bin/rails app:update:configs`
(and `app:update:bin`), then re-apply the items below, set `config.load_defaults`, and delete
`config/initializers/new_framework_defaults_*.rb`.

**Convention:** accept the regenerated files as-is. Mercury changes live in a block at the bottom of
`config/environments/*.rb`, under the `Mercury customizations follow` banner (keep the literal token so grep matches).
Generated files also get `# frozen_string_literal: true` back (rubocop enforces it): run
`rubocop -A --only Style/FrozenStringLiteralComment,Layout/EmptyLineAfterMagicComment config bin`.
Style cops that disagree with generated code are excluded in `.rubocop.yml` instead of rewriting the files.

Last reviewed at the **7.0 → 8.1** upgrade.

| File | Decision | What's intentional / why |
|---|---|---|
| `config/environments/development.rb` | Re-append block | `config.hosts` for `workbench-admin.test` and ngrok. |
| `config/environments/production.rb` | Re-append block | `config.assume_ssl = true` (ALB terminates TLS and redirects HTTP; see thoth). `public_file_server.enabled` from `RAILS_SERVE_STATIC_FILES`. `config.logger = nil` keeps Rails' default file logger (stock 7.1+ logs to STDOUT; Passenger + Capistrano's linked `log/` expect a file). |
| `config/environments/test.rb` | Keep stock | No customizations. |
| `bin/dev` | Restore ours | jsbundling's foreman launcher for `Procfile.dev`; stock is a Rails-only launcher. |
| `config/ci.rb`, `bin/ci` | Delete | Stock 8.1 CI runner assumes importmap and minitest; we use rspec. |
| `config/application.rb`, other initializers, `config/puma.rb`, `bin/setup`, `bin/rubocop` | Keep stock | No customizations (Passenger ignores `puma.rb`). |
