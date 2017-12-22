require 'omniauth'

module OmniAuth
  module Strategies
    autoload :Identity, 'omniauth/strategies/identity'
  end

  module Identity
    autoload :Model,               'omniauth/identity/model'
    autoload :SecurePassword,      'omniauth/identity/secure_password'
    module Models
      autoload :ActiveRecord,      'omniauth/identity/models/active_record'
      autoload :MongoMapper,       'omniauth/identity/models/mongo_mapper'
      autoload :Mongoid,           'omniauth/identity/models/mongoid'
      autoload :DataMapper,        'omniauth/identity/models/data_mapper'
      autoload :CouchPotatoModule, 'omniauth/identity/models/couch_potato'
    end
  end
end
