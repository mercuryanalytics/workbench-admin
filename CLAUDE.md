# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Small Rails 8.1 app (Ruby 3.3.4, PostgreSQL) that bridges Workbench projects to QuickBooks Online. Given a project name, it finds the matching QuickBooks customer and returns its invoice. The README is the unmodified Rails stub.

## Commands

- Setup: `bundle install && yarn install`, then `bin/rails db:setup`
- Dev server (Rails + JS/CSS watchers): `bin/dev` (runs `foreman start -f Procfile.dev`)
- One-off asset builds: `yarn build`, `yarn build:css` (output goes to `app/assets/builds`, which is gitignored)
- Tests: `bundle exec rspec`; single file/example: `bundle exec rspec spec/requests/invoices_spec.rb:12`. Run the asset builds first, because `spec/requests/layout_spec.rb` expects built, digested assets. Specs block network access (WebMock, localhost allowed) and reset the memoized `IntuitAccount.instance` before each example.
- Lint: `bundle exec rubocop` (rubocop-rails and rubocop-rspec; double-quoted strings enforced; Bundler/OrderedGems is off)
- Deploy: Capistrano (`bundle exec cap staging deploy` / `cap production deploy`), from `main`, to the hg-packer AMI. `capistrano-hgpacker` restarts Passenger as the systemd unit `passenger@workbench-admin`. `config/schedule.rb` (whenever) restarts the app early every Sunday.

## Architecture

- **Flow:** `InvoicesController#show` (`GET /invoices/:id`, where `:id` is the project name) → `before_action :acquire_token` → `LocateInvoiceForProject` interactor (`app/interactors`, `interactor-rails` gem) → QuickBooks via `quickbooks-ruby`. The interactor first queries Customer by `DisplayName LIKE "<project_name> %"` with `MAXRESULTS 2`. It fails with `:not_found` for 0 matches and `:ambiguous` for more than 1. It then looks up the customer's invoices and fails with `:not_invoiced` if there are none. The controller maps `:ambiguous` to 409 and every other failure to 404. A success renders the customer name as plain text.
- **OAuth lives in `ApplicationController`:** it holds the Intuit auth actions (`intuit_authenticate`, `intuit_callback`), and `GET /api/oauth_callback` routes to `application#intuit_callback`. If there is no stored access token, `acquire_token` redirects to Intuit's grant URL. The callback saves the token and redirects back to `invoice_path(session[:target])`. `intuit_authenticate` is not currently routed.
- **Token storage:** `OauthToken` (single-table inheritance via `type`, unique per type) includes `QuickbooksOauth` (`app/models/concerns`), which holds the OAuth2 client, grant URL, and refresh logic. `IntuitAccount` is the singleton row (`IntuitAccount.instance`). `with_token` yields an `OAuth2::AccessToken`, refreshing and retrying up to 3 times on `OAuth2::Error` or `Quickbooks::AuthorizationFailure`, then raises `TooManyRetries`.
- **Credentials:** client id, secret, and realm come from `Rails.application.credentials.intuit[:live]` (see `intuit_app` in the concern). `config/initializers/quickbooks.rb` also sets a separate `intuit_realm` per environment and leaves `Quickbooks.sandbox_mode` off, so even dev and test talk to live QuickBooks unless changed.
- **Frontend:** Hotwired (Turbo and Stimulus), esbuild via jsbundling-rails and Bootstrap via sass (cssbundling), both writing to `app/assets/builds`, served by Propshaft. Slim templates. It is nearly empty; `IntegrationController` only serves the QuickBooks TOS and privacy pages (`app/views/integration`). `/` redirects to researchresultswebsite.com.
- **Gem pin:** `quickbooks-ruby` is held at `~> 1.0` (2.x moves to oauth2 2.x). Rails and Ruby versions are pinned in `Gemfile`, `.rubocop.yml` and `config/deploy.rb` (`rbenv_ruby`), so the deploy host needs that Ruby (Fullstaq `-jemalloc` build in `deploy.rb`). Rails upgrade conventions and intentional config are logged in `doc/rails-upgrades.md`.
