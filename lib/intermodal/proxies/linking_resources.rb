module Intermodal
  module Proxies
    # This class is necessary to create the correct output for linked resources. 
    # Example:
    #
    #   books n-to-n authors
    #   Book #1 has 3 authors, Author #1, #2, and #3
    #
    #   Expected output:
    #
    #   { "books": { "author_ids": [ 1, 2, 3 ] } }
    #
    #   <books>
    #     <author_ids>
    #       <author_id>1</author_id>
    #       <author_id>2</author_id>
    #       <author_id>3</author_id>
    #     </author_ids>
    #   </books>
    #
    class LinkingResources
      attr_accessor :parent_resource_name, :linked_resource_name, :collection, :parent_id
      delegate :to_a, :to => :collection

      # USAGE:
      #   Intermodal::Proxies::LinkingResources.new(:parent, :to => :linked_resources, :with => collection)
      def initialize(parent_resource_name, options = {})
        @parent_resource_name = parent_resource_name
        @collection = options[:with]
        @linked_resource_name = options[:to]
        @parent_id = (options[:parent_id] ? options[:parent_id].to_i : nil ) # nil should be nil, not 0
      end

      def to_json(options = {})
        as_json(options).to_json
      end

      def as_json(options = {})
        root = options[:root] || parent_resource_name
        (root ? { root => presentation } : presentation)
      end

      def to_xml(options = {})
        root = options[:root] || parent_resource_name
        presentation.to_xml(:root => root)
      end

      def presentation
        { linked_resource_element_name => collection.to_a, :id => parent_id }
      end

      def linked_resource_element_name
        "#{linked_resource_name.to_s.singularize}_ids"
      end

    end
  end
end
