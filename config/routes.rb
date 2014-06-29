Rails.application.routes.draw do
  resources :offers, only: :index

  root 'offers#index'
end
