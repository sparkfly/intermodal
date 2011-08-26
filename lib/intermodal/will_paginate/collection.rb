module Intermodal
  module WillPaginate
    module Collection
      def as_json(*args)
        options = args.extract_options!
        _collection_name = options.delete(:collection_name) || :collection
        { _collection_name => self.to_a.as_json(options),
          :page => self.current_page.to_i,
          :total_pages => self.total_pages,
          :total_entries => self.total_entries }
      end
    end
  end
end

