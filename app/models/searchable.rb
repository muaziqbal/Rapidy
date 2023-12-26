module Searchable
  class DocumentInstanceAccessor < Sunspot::Adapters::InstanceAdapter
    def id
      @instance.id
    end
  end

  class DocumentDataAccessor < Sunspot::Adapters::DataAccessor
    def load(id)
      Child.get(id)
    end
  end

  def self.included(klass)
    klass.extend ClassMethods
    klass.class_eval do
      include Sunspot::Rails::Searchable
      Sunspot::Adapters::InstanceAdapter.register(DocumentInstanceAccessor, klass)
      Sunspot::Adapters::DataAccessor.register(DocumentDataAccessor, klass)
      after_create :index_record
      after_update :index_record
      after_save :index_record

      def index_record
        begin
          Sunspot.index!(self)
        rescue
          Rails.logger.error "***Problem indexing record for searching, is SOLR running?"
        end
        true
      end
    end
  end

  module ClassMethods
    def reindex!
      Child.update_solr_indices
      Sunspot.remove_all(self)
      self.all.each { |record| Sunspot.index!(record) }
    end

    def sunspot_matches(query = "")
      begin
        return get_matches(query).results
      rescue
        self.reindex!
        Sunspot.commit
        return get_matches(query).results
      end
    end

    def get_matches(criteria)
      Sunspot.search(self) do
        fulltext(criteria, :minimum_match => 1)
        adjust_solr_params do |params|
          params[:defType] = "dismax"
        end
      end
    end
  end

end
