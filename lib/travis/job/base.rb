module Travis
  module Job
    # Job base class. Implements an observer pattern so Reporters can hook in
    # unobstrusively, holds the payload data and provides the main public `work!`
    # method.
    class Base
      class << self
        def base_dir
          @@base_dir ||= Pathname.new('/tmp/travis/builds')
        end

        def base_dir=(base_dir)
          @@base_dir = Pathname.new(base_dir)
        end
      end

      include Travis::Shell

      attr_reader :payload, :observers

      def initialize(payload)
        @payload   = Hashie::Mash.new(payload)
        @observers = []
      end

      def work!
        start
        result = perform
        finish(result)
      end

      protected

        def repository
          @repository ||= Repository.new(payload.repository.url, build.config)
        end

        def config
          repository.config ||= Hashie::Mash.new
        end

        def build
          payload.build ||= Hashie::Mash.new
        end

        def start
          notify(:start, :started_at => Time.now)
        end

        def finish(data = {})
          notify(:finish, :finished_at => Time.now)
        end

        def notify(event, *args)
          observers.each do |observer|
            observer.send(:"on_#{event}", self, *args) if observer.respond_to?(:"on_#{event}")
          end
        end

        def chdir(&block)
          FileUtils.mkdir_p(build_dir)
          Dir.chdir(build_dir, &block)
        end

        def build_dir
          @build_dir ||= self.class.base_dir.join(repository.path[1..-1])
        end
    end
  end
end
