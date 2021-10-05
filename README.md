# OpenTourBuilder API Server

The OpenTourBuilder API server provides a multi-tenant REST API for geographic tours.

## Requirements

- rbenv
- Ruby 3.0.2

## Install PostgreSQL client

~~~bash
sudo apt install postgresql-client
~~~

## Install GDAL

~~~bash
sudo apt install libpq-dev gdal-bin libgdal-dev
~~~

## Install Headless Chrome

This is mostly taken from [this blog post](https://geekflare.com/install-chromium-ubuntu-centos/) and works on Ubuntu 20.04

~~~bash
sudo apt update
sudo apt install -y libappindicator1 fonts-liberation
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome*.deb
~~~

I always get some errors about missing/mis-matched dependencies. The following will fix that.

~~~bash
sudo apt install -f
~~~

And try to install it again.

~~~bash
sudo dpkg -i google-chrome*.deb
~~~

Assuming all went well, verify the install be running:

~~~bash
google-chrome-stable -version
~~~

You should see something like:

~~~bash
Google Chrome 91.0.4472.106
~~~

## Build Status

TODO: Add CircleCI

## Installation

TODO: How does cloning work with submodules?
TODO: Note about rbenv.

~~~bash
bundle install
bundle exec rake db:create
bundle exec rake db:schema:load
bundle exec rake db:migrate
~~~

## Running local development server

Run the development under https to avoid mix content errors. Note: this will generate a self-signed certificate. There are ways to tell your browser to trust these certs, but that is beyond the scope of this README.

~~~bash
bundle exec puma -b 'ssl://0.0.0.0:3000?key=<path to key>&cert=<path to cert>
~~~

## Running tests

[![Coverage Status](https://coveralls.io/repos/github/ecds/otb-api-server/badge.svg?branch=develop)](https://coveralls.io/github/ecds/otb-api-server?branch=develop)

~~~bash
bundle exec rspec ./spec
~~~

## Multitenancy

The OTB API sever uses the [Apartment](https://github.com/influitive/apartment) gem to support multitenancy.
TODO: Write blog post and link here.

## Endpoints

TODO: List REST endpoints

## Deployment

Use [Capistrano](https://capistranorb.com/) for deployment. General deployment configuration is defined in [deploy.rb](config/deploy.rb). Environment specific configurations can be found in [config/deploy](config/deploy).

Example:

~~~bash
cap deploy staging
~~~

## Contribute

We use the [Git-Flow](https://danielkummer.github.io/git-flow-cheatsheet/) branching model. Please submit pull requests against the develop branch.

### Code of conduct

[Code of Conduct](CODE_OF_CONDUCT.md)

## License

OpenTourBuilder API Server is released under the [MIT License](https://opensource.org/licenses/MIT).
