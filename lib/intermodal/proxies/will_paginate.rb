module Intermodal
  module Proxies
    module WillPaginate
      module Collection

        def pagination_info
          { :page => self.current_page.to_i,
            :per_page => self.per_page.to_i,
            :total_pages => self.total_pages,
            :total_entries => self.total_entries }
        end

        # TODO: This needs its own spec
        def as_json(*args)
          options = args.extract_options!
          _collection_name = options.delete(:root) || :collection

          # Scrub out everything else
          presenter_options = {
            :root => (options[:always_nest_collections] ? _collection_name.to_s.singularize : nil),
            :always_nest_collections => options[:always_nest_collections],
            :scope => options[:scope],
            :presenter => options[:presenter] }
          pagination_info.merge({ _collection_name => self.to_a.as_json(presenter_options)})
        end

        # TODO: This needs its own spec
        # TODO: Should be refactored to have clearer code
        def to_xml(*args)
          options = args.extract_options!
          _collection = self

          # For a paginated collection of say, books, we want the following output:
          #
          # <books>
          #   <collection>
          #     <book>
          #       <title> ... </title>
          # ...
          #
          # Since Rails 3.0 magically assumes that a hash
          # 
          #   { :collection => [ {:title => ' ... ' } ] } 
          #
          # outputs to
          #
          #   <collection>
          #     <collection>
          #       <title> ... </title>
          #
          # We need to use a custom builder. We use very kludgy code, by calling #to_xml
          # again, but override builder so it will nest things properly.
          #
          # Actually, it is also depending on some magic. Presenter/API options are saved
          # in the builder class, so it uses that. Which means this isn't side-effect-free
          # code. Ugh.
          #
          # Ultimately, this needs to be more modular so that API writers can specify their
          # own builder. For now, we'll dictate the auto-generated XML and wait until someone
          # complains about it in the Github Issues tracker.
          collection_builder = proc do |opts, key|
            _builder = opts[:builder]

            _builder.collection do
              _collection.to_a.map do |r| 
                r.presentation(options.except(:root)).
                  to_xml(
                    :root => r.class.name.demodulize.underscore,
                    :builder => opts[:builder],
                    :skip_instruct => true )
              end
            end
          end

          # Merge information such as current page, total pages, total entries, etc.
          pagination_info.
            merge({ :collection => collection_builder }).
            to_xml(options)
        end
      end
    end
  end
end

