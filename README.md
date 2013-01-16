# Joker DMAPI client library

Description of the API can be found at https://joker.com/faq/category/33/22-dmapi.html

## Installation

Add this line to your application's Gemfile:

    gem 'joker-dmapi'

or this line:

    gem 'joker-dmapi', git: 'https://github.com/kolodovskyy/joker-dmapi.git'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install joker-dmapi

## Usage (example)

    require "joker-dmapi"

    ENV['JOKER_DMAPI_DEBUG'] = 'yes'

    JokerDMAPI::Client.with_connection('LOGIN', 'PASSWORD') do |j|
        j.contact_info 'CCOM-000000'
        j.domain_info 'joker.com'

        j.contact_create {
            tld: 'com',
            name: 'Test name',
            email: 'test@tes.com',
            address: ['Test str.'],
            city: 'Kiev',
            postal_code: '00000',
            country: 'UA',
            phone: '+380.443063232',
        }

        # handle returted
        j.contact_create_result '51930786'

        j.contact_delete 'CCOM-000000'
        j.complete? '51930793'

        j.domain_registrant_update 'ukrtoday.com', {
            tld: 'com',
            name: 'Test name',
            organization: 'Test org',
            address: [ 'Test str.' ],
            city: 'Kiev',
            postal_code: '00000',
            country: 'UA',
            phone: '+380.442063232',
            fax: '+380.442063233',
            email: 'test@test.com'
        }

        j.complete? '51931047'

        j.domain_update 'ukrtoday.com', {
            admin: 'CCOM-000000',
            tech: 'CCOM-000000',
            billing: 'CCOM-000000',
            nservers: %w(ns1.test.com ns2.test.com)
        }
    end

## Maintainers and Authors

Yuriy Kolodovskyy (https://github.com/kolodovskyy)

## License

MIT License. Copyright 2012 [Yuriy Kolodovskyy](http://twitter.com/kolodovskyy)
