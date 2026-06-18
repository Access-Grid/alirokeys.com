Rails.application.routes.draw do
  devise_for :users, controllers: { sessions: "users/sessions" }

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#landing"

  # --- Authenticated area ------------------------------------------------
  get "dashboard" => "dashboard#show", as: :dashboard

  resources :aliro_configs, except: [ :show, :index ] do
    resource :share, only: [ :create ], controller: "shares"
  end

  # --- One-time share retrieval ------------------------------------------
  get  "s/:token" => "shares#show",   as: :share
  post "s/:token" => "shares#reveal", as: :reveal_share
  post "api/v1/shares/:token/native" => "api/shares#show", as: :api_share

  # --- Public registry (domain-scoped; keep last, dotted-name constraint) -
  # NOTE: segment is :domain_name — :domain is a reserved Rails URL option.
  lang = /json|c|h|swift|py|rb|php|js|java/
  domain_re = /[a-z0-9][a-z0-9.\-]*\.[a-z]{2,}/i

  get ":domain_name/configs/samples/:id" => "configs#show", as: :sample_config,
      constraints: { domain_name: domain_re }, format: false
  get ":domain_name/configs/:id" => "configs#export", as: :config_export,
      constraints: { domain_name: domain_re, format: lang }
  get ":domain_name" => "domains#show", as: :domain_profile,
      constraints: { domain_name: domain_re }, format: false
end
