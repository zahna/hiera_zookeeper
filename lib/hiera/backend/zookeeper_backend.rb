class Hiera
  module Backend
    class Zookeeper_backend
      # ZooKeeper backend for Hiera. Recognizes :server and :datadir config options. If no :server is specified, uses localhost:2181.
      # The node data is expected to be in YAML.

      def initialize
        require 'rubygems'
        require 'yaml'
        require 'zookeeper'

        Hiera.debug("Hiera ZooKeeper backend starting")
      end

      def lookup(key, scope, order_override, resolution_type)
        answer = nil
        Hiera.debug("Looking up #{key} in ZooKeeper backend")
        # Establish server(s) to check
        servers = []
        unless Config[:zookeeper].nil? or Config[:zookeeper][:server].nil? then
          if Config[:zookeeper][:server].kind_of?(Array) then
            Config[:zookeeper][:server].shuffle!
            Config[:zookeeper][:server].each do |server|
              servers.push(Backend.parse_string(server, scope))
            end
          else
            servers.push(Backend.parse_string(Config[:zookeeper][:server], scope))
          end
        else
          servers.push('localhost:2181')
        end 
        # Establish connection timeout
        if Config[:zookeeper].nil? or Config[:zookeeper][:timeout].nil? then
          timeout = 1
        else
          timeout = Config[:zookeeper][:timeout]
        end
        # Establish connection
        zk = nil
        servers.each do |s|
          begin 
            zk = Zookeeper.new(s, timeout)
            break if zk.connected?
          rescue => e
            Hiera.debug(e.message)
            next
          end
        end
        # If it did not work, raise that exception!
        if zk.nil? or not zk.connected? then
          raise(ZookeeperExceptions::ZookeeperException, "Could not connect to any server in configuration")
        end

        Backend.datasources(scope, order_override) do |source|
          Hiera.debug("Looking for data source #{source}")
          # Determine the zookeeper path(s) to get data from
          unless Config[:zookeeper].nil? or Config[:zookeeper][:datadir].nil? then
            datadir = "#{Backend.datadir(Config[:zookeeper][:datadir], scope)}/#{source}"
          else
            datadir = "/hiera/#{source}"
          end
          data = zk.get(:path => "#{datadir}/#{key}")
          if data[:stat].exists then
            Hiera.debug("Found #{key} in #{source}")
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
        zk.close if not zk.nil? and zk.connected?
        return answer
      end
    end
  end
end
