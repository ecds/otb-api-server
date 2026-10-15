# frozen_string_literal: true

set :branch, 'develop'

# server '44.192.30.237', user: 'deploy', roles: %w{app db web}, primary: :my_value
role :app, ['3.86.138.59', '3.236.252.227'], user: 'deploy'
role :web, ['3.86.138.59', '3.236.252.227'], user: 'deploy'
role :db,  ['3.86.138.59', '3.236.252.227'], user: 'deploy'

set :deploy_to, '/data/otb-api-server'

set :ssh_options, {
  forward_agent: false,
  auth_methods: ['publickey'],
}
