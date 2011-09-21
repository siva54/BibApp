require 'omniauth/core'
module OmniAuth
  module Strategies
    class Shibboleth
      include OmniAuth::Strategy

      attr_accessor :base_url, :entity_id

      #receive and save any needed parameters for the strategy
      def initialize(app, base_url, entity_id,  options = {})
        self.base_url = base_url
        self.entity_id = entity_id
        super(app, :shibboleth, options)
      end

      #redirect to shibboleth login
      def request_phase
        r = Rack::Response.new
        r.redirect shibboleth_login_url
        r.finish
      end

      #check to see if we have a successful authentication
      def callback_phase
        if request.env["REMOTE_USER"]
          super
        else
          fail!('No REMOTE_USER from shibboleth authentication')
        end
      end

      def auth_hash
        remote_user = request.env["REMOTE_USER"]
        OmniAuth::Utils.deep_merge(super, {
            'user_info' => {'email' => remote_user},
            'uid' => remote_user
        })
      end

      protected

      def shibboleth_login_url
        url = self.base_url
        return "#{url}?target=#{shibboleth_target()}&entityID=#{shibboleth_entity_id}"
      end

      def shibboleth_target
        root = URI.parse($APPLICATION_URL)
        root.scheme = 'https'
        root.merge!('/auth/shibboleth/callback')
        CGI.escape(root.to_s)
      end

      def shibboleth_entity_id
        return CGI.escape(self.entity_id)
      end

    end

  end
end