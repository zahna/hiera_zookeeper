class Hiera
  module Backend
    class Zookeeper_backend
      # ZooKeeper backend for Hiera. Recognizes :server and :datadir config options. If no :server is specified, uses localhost:2181.
      # The node data is expected to be in YAML or JSON (YAML is the default).

      def initialize
        require 'rubygems'
        require 'zookeeper'
        # Set default values
        Config[:zookeeper] = Hash.new() if Config[:zookeeper].nil?
        Config[:zookeeper][:timeout] = 1 if Config[:zookeeper][:timeout].nil?
        Config[:zookeeper][:datadir] = '/hiera' if Config[:zookeeper][:datadir].nil? 
        Config[:zookeeper][:format] = 'yaml' if Config[:zookeeper][:format].nil?
        Config[:zookeeper][:format].downcase!
        if Config[:zookeeper][:server].nil? then
          Config[:zookeeper][:servers] = ['localhost:2181'] if Config[:zookeeper][:servers].nil?
        else
          Hiera.warn("The :server option is deprecated.  Use :servers.  Option :server will go away very soon.") 
          Config[:zookeeper][:servers] = Config[:zookeeper][:server]
        end

        case Config[:zookeeper][:format]
        when 'json'
          require 'json'
        else
          require 'yaml'
        end

        Hiera.debug("Hiera ZooKeeper backend starting")
      end

      def lookup(key, scope, order_override, resolution_type)
        answer = nil
        Hiera.debug("Looking up #{key} in ZooKeeper backend")
        # Establish server(s) to check
        servers = []
        Config[:zookeeper][:servers].shuffle!
        Config[:zookeeper][:servers].each do |s|
          servers.push(Backend.parse_string(s, scope))
        end
        # Establish connection
        zk = nil
        servers.each do |s|
          begin 
            zk = Zookeeper.new(s, Config[:zookeeper][:timeout])
            break if zk.connected?
          rescue => e
            Hiera.debug(e.message)
            next
          end
        end
        # If it did not work, raise that exception!
        if zk.nil? or not zk.connected? then
          raise(ZookeeperExceptions::ZookeeperException, "Could not connect to any zookeeper server in configuration")
        end

        Backend.datasources(scope, order_override) do |source|
          Hiera.debug("Looking for data source #{source}")
          # Determine the zookeeper path to get data from
          datadir = "#{Backend.parse_string(Config[:zookeeper][:datadir], scope)}/#{source}"
          data = zk.get(:path => "#{datadir}/#{key}")
          if data[:stat].exists then
            Hiera.debug("Found #{key} in #{source}")
            case Config[:zookeeper][:format]
            when 'json'
              new_answer = Backend.resolve_answer(JSON.load(data[:data]), resolution_type)
            else
              new_answer = Backend.resolve_answer(YAML.load(data[:data]), resolution_type)
            end
            case resolution_type
            when :array
              raise(Exception, "Hiera type mismatch: expected Array and got #{new_answer.class}") unless new_answer.kind_of?(Array) or new_answer.kind_of?(String)
              answer ||= []
              answer << new_answer
            when :hash
              raise(Exception, "Hiera type mismatch: expected Hash and got #{new_answer.class}") unless new_answer.kind_of?(Hash)
              answer ||= {}
              answer = new_answer.merge(answer)
            else
              answer = new_answer
              break
            end
          end
        end
        zk.close if not zk.nil? and zk.connected?
        return answer
      end
    end
  end
end
