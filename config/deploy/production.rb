set :branch, 'develop'

server '44.192.30.237', user: 'deploy', roles: %w{app db web}, primary: :my_value

set :deploy_to, '/data/otb-api-server'

set :ssh_options, {
  forward_agent: false,
  auth_methods: %w(publickey)
}
