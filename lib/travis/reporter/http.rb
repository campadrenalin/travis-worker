require 'uri'

module Travis
  module Reporter
    class Http < Base
      protected
        def message(type, data)
          path = "/builds/#{build.id}#{'/log' if data.delete(:incremental)}"
          messages.add(type, path, :_method => :put, :build => data)
        end

        def deliver_message(message)
          register_connection(http(message.target).post(:body => message.data, :head => header))
        end

        def http(path)
          # EventMachine::HttpRequest.new([host, path].join('/'))
        end

        def host
          @host ||= config.url || 'http://127.0.0.1'
        end

        def uri
          @uri ||= URI.parse(host)
        end

        def header
          @header ||= { 'authorization' => [uri.user, uri.password] }
        end

        def config
          @config ||= Travis::Worker.config.reporter.http || Hashie::Mash.new
        end
    end
  end
end

