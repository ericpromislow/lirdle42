Rails.application.routes.draw do
  get 'password_resets/new'
  get 'password_resets/edit'
  # get 'external_invitations/edit'
  get 'sessions/new'
  # root 'users#index'
  root 'static_pages#home'
  get '/about', to: 'static_pages#about'
  # get 'static_pages/home'
  get '/help', to: 'static_pages#help'
  get '/contact', to: 'static_pages#contact'

  get '/signup', to: 'users#new'
  get '/login', to: 'sessions#new'
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  resources :users
  get '/waiting_users', to: 'users#waiting_users'
  get '/who_am_i', to: 'users#who_am_i'

  resources :account_activations, only: [:create, :edit]
  resources :password_resets, only: [:new, :create, :edit, :update]
  resources :invitations, only: [:create, :destroy, :update]
  resources :external_invitations, only: [:create, :destroy, :edit, :update]
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  resources :chatrooms, param: :slug
  resources :messages

  resources :games
  get 'games/join'
  # patch '/perturb_guess', to: 'games#perturb_guess' # perturb_guess/game_id?my_gs=gsx_id&their_gs=gsy_id&lie=coords
  resources :game_states, only: [:show, :update]
  resources :guesses, only: [:create]

  get '/is_valid_word', to: 'guesses#is_valid_word'
  get '/is_duplicate_guess', to: 'game_states#is_duplicate_guess'

  get '/join', to: 'external_invitations#edit'


  # Serve websocket cable requests in-process
  mount ActionCable.server => '/cable'
end
