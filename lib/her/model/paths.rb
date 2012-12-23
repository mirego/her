module Her
  module Model
    module Paths
      extend ActiveSupport::Concern
      # Return a path based on the collection path and a resource data
      #
      # @example
      #   class User
      #     include Her::Model
      #     collection_path "/utilisateurs"
      #   end
      #
      #   User.find(1) # Fetched via GET /utilisateurs/1
      def request_path
        parameters = respond_to?(:request_path_parameters, true) ? request_path_parameters : {}
        self.class.build_request_path(parameters.merge(@data))
      end

      module ClassMethods
        # Defines a custom path prefix for the resource
        #
        # @example
        #  class User
        #    include Her::Model
        #    path_prefix "/sites/:site_id"
        #  end
        def path_prefix(prefix=nil)
          @her_path_prefix ||= begin
            superclass.collection_path.dup if superclass.respond_to?(:path_prefix)
          end

          return @her_path_prefix unless prefix
          @her_path_prefix = prefix
        end

        # Defines a custom collection path for the resource
        #
        # @example
        #  class User
        #    include Her::Model
        #    collection_path "/users"
        #  end
        def collection_path(path=nil)
          @her_collection_path ||= begin
            superclass.collection_path.dup if superclass.respond_to?(:collection_path)
          end

          return @her_collection_path unless path
          @her_resource_path = "#{path}/:id"
          @her_collection_path = path
        end

        # Defines a custom resource path for the resource
        #
        # @example
        #  class User
        #    include Her::Model
        #    resource_path "/users/:id"
        #  end
        def resource_path(path=nil)
          @her_resource_path ||= begin
            superclass.resource_path.dup if superclass.respond_to?(:resource_path)
          end

          return @her_resource_path unless path
          @her_resource_path = path
        end

        # Return a custom path based on the collection path and variable parameters
        #
        # @example
        #   class User
        #     include Her::Model
        #     collection_path "/utilisateurs"
        #   end
        #
        #   User.all # Fetched via GET /utilisateurs
        def build_request_path(path=nil, parameters={})
          unless path.is_a?(String)
            parameters = path || {}
            path = parameters.include?(:id) && !parameters[:id].nil? ? resource_path : collection_path
            path = File.join(path_prefix, path) if path_prefix
          end

          parameters = request_path_parameters.merge(parameters) if respond_to?(:request_path_parameters, true)

          path.gsub(/:([\w_]+)/) do
            # Look for :key or :_key, otherwise raise an exception
            parameters.delete($1.to_sym) || parameters.delete("_#{$1}".to_sym) || raise(Her::Errors::PathError.new("Missing :_#{$1} parameter to build the request path (#{path})."))
          end
        end
      end
    end
  end
end
