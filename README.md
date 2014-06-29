# TEST APP

This is the 'TEST APP', dead simple client for SponsorPay API.

## Prerequisites

  * Ruby 2.0.0

## Installation

```sh
$ git clone 
$ cd /path/to/test_app
$ bundle install
```

## Configure

Please copy `sponsor_pay_sample.yml` as `sponsor_pay.yml` like this:

```sh
$ cd /path/to/test_app
$ cp config/sponsor_pay_sample.yml config/sponsor_pay.yml
```

And then make sure that every param has its value.

**NOTE**: These params are needed it tests as well, so please make sure that params are set for `TEST` environment.

## Starting application

```sh
$ cd /path/to/test_app
$ bundle exec rails s
$ open http://localhost:3000
```

## Running the tests

```sh
$ bundle exec rspec spec
```

