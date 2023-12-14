class Child < CouchRest::Model::Base
  use_database :child

  require "uuidtools"
  include RecordHelper
  include RapidFTR::Model
  include RapidFTR::CouchRestRailsBackward
  include Extensions::CustomValidator::CustomFieldsValidator
  include AttachmentHelper
  include AudioHelper
  include PhotoHelper

  include Searchable

  Sunspot::Adapters::InstanceAdapter.register(DocumentInstanceAccessor, Child)
  Sunspot::Adapters::DataAccessor.register(DocumentDataAccessor, Child)

  before_save :update_history, :unless => :new?
  before_save :update_organisation
  before_save :update_photo_keys
  before_save :add_creation_history, :if => :new?

  property :short_id
  property :unique_identifier
  property :created_organisation
  property :created_by
  property :reunited, TrueClass
  property :flag, TrueClass
  property :duplicate, TrueClass
  property :investigated, TrueClass
  property :verified, TrueClass

  validate :validate_photos_size
  validate :validate_photos
  validate :validate_audio_size
  validate :validate_audio_file_name
  validates_with FieldValidator, :type => Field::NUMERIC_FIELD
  validate :validate_duplicate_of
  validates_with FieldValidator, :type => Field::TEXT_AREA
  validates_with FieldValidator, :type => Field::TEXT_FIELD
  validate :validate_created_at
  validate :validate_has_at_least_one_field_value
  validate :validate_last_updated_at

  def initialize *args
    self['photo_keys'] ||= []
    arguments = args.first

    if arguments.is_a?(Hash) && arguments["current_photo_key"]
      self['current_photo_key'] = arguments["current_photo_key"]
      arguments.delete("current_photo_key")
    end

    self['histories'] = []
    super *args
  end

  def self.new_with_user_name(user, fields = {})
    child = new(fields)
    child.create_unique_id
    child['short_id'] = child.short_id # TODO: Move this into create_unique_id
    child.set_creation_fields_for user
    child
  end

  design do
      view :by_protection_status_and_gender_and_ftr_status

      ['created_at', 'name', 'flag_at', 'reunited_at'].each do |field|
        view "by_all_view_with_created_by_#{field}",
                :map => "function(doc) {
                    var fDate = doc['#{field}'];
                    if (doc['couchrest-type'] == 'Child')
                    {
                      emit(['all', doc['created_by'], fDate], doc);
                      if (doc.hasOwnProperty('flag') && (doc['flag'] == 'true' || doc['flag'] == true)) {
                        emit(['flag', doc['created_by'], fDate], doc);
                      }
                      if (doc.hasOwnProperty('reunited')) {
                        if (doc['reunited'] == 'true' || doc['reunited'] == true) {
                          emit(['reunited', doc['created_by'], fDate], doc);
                        } else {
                          emit(['active', doc['created_by'], fDate], doc);
                        }
                      } else {
                        emit(['active', doc['created_by'], fDate], doc);
                      }
                   }
                }"

        view "by_all_view_#{field}",
                :map => "function(doc) {
                    var fDate = doc['#{field}'];
                    if (doc['couchrest-type'] == 'Child')
                    {
                      emit(['all', fDate], doc);
                      if (doc.hasOwnProperty('flag') && (doc['flag'] == 'true' || doc['flag'] == true)) {
                        emit(['flag', fDate], doc);
                      }

                      if (doc.hasOwnProperty('reunited')) {
                        if (doc['reunited'] == 'true' || doc['reunited'] == true) {
                          emit(['reunited', fDate], doc);
                        } else {
                         if (!doc.hasOwnProperty('duplicate') && !doc['duplicate']) {
                          emit(['active', fDate], doc);
                        }
                        }
                      } else {
                         if (!doc.hasOwnProperty('duplicate') && !doc['duplicate']) {
                                        emit(['active', fDate], doc);
                      }
                      }
                   }
                }"

        view "by_all_view_#{field}_count",
                :map => "function(doc) {
                    if (doc['couchrest-type'] == 'Child')
                   {
                      emit(['all', doc['created_by']], 1);
                      if (doc.hasOwnProperty('flag') && (doc['flag'] == 'true' || doc['flag'] == true)) {
                        emit(['flag', doc['created_by']], 1);
                      }
                      if (doc.hasOwnProperty('reunited')) {
                        if (doc['reunited'] == 'true' || doc['reunited'] == true) {
                          emit(['reunited', doc['created_by']], 1);
                        } else {
                          emit(['active', doc['created_by']], 1);
                        }
                      } else {
                        emit(['active', doc['created_by']], 1);
                      }
                   }
                }"

        view "by_all_view_with_created_by_#{field}_count",
                :map => "function(doc) {
                    if (doc['couchrest-type'] == 'Child')
                   {
                      emit(['all', doc['created_by']], 1);
                      if (doc.hasOwnProperty('flag') && (doc['flag'] == 'true' || doc['flag'] == true)) {
                        emit(['flag', doc['created_by']], 1);
                      }
                      if (doc.hasOwnProperty('reunited')) {
                        if (doc['reunited'] == 'true' || doc['reunited'] == true) {
                          emit(['reunited', doc['created_by']], 1);
                        } else {
                          emit(['active', doc['created_by']], 1);
                        }
                      } else {
                        emit(['active', doc['created_by']], 1);
                      }
                   }
                }"
      end

      view :by_flag,
              :map => "function(doc) {
                    if (doc.hasOwnProperty('flag'))
                   {
                     if (!doc.hasOwnProperty('duplicate') || !doc['duplicate']) {
                       emit(doc['flag'],doc);
                     }
                   }
                }"

      view :by_unique_identifier,
              :map => "function(doc) {
                    if (doc.hasOwnProperty('unique_identifier'))
                   {
                      emit(doc['unique_identifier'],doc);
                   }
                }"

      view :by_short_id,
              :map => "function(doc) {
                    if (doc.hasOwnProperty('short_id'))
                   {
                      emit(doc['short_id'],doc);
                   }
                }"

      view :by_duplicate,
              :map => "function(doc) {
                if (doc.hasOwnProperty('duplicate')) {
                  emit(doc['duplicate'], doc);
                }
              }"

      view :by_duplicates_of,
              :map => "function(doc) {
                if (doc.hasOwnProperty('duplicate_of')) {
                  emit(doc['duplicate_of'], doc);
                }
              }"

      view :by_user_name,
              :map => "function(doc) {
                    if (doc.hasOwnProperty('histories')){
                      for(var index=0; index<doc['histories'].length; index++){
                          emit(doc['histories'][index]['user_name'], doc)
                      }
                   }
                }"

      view :by_created_by

      view :by_ids_and_revs,
              :map => "function(doc) {
              if (doc['couchrest-type'] == 'Child'){
                emit(doc._id, {_id: doc._id, _rev: doc._rev});
              }
            }"
  end

  def compact
    self['current_photo_key'] = '' if self['current_photo_key'].nil?
    self
  end

  def self.fetch_all_ids_and_revs
    ids_and_revs = []
    all_rows = self.by_ids_and_revs({:include_docs => false})["rows"]
    all_rows.each do |row|
      ids_and_revs << row["value"]
    end
    ids_and_revs
  end

  def self.fetch_paginated(options, page, per_page)
    row_count = send("#{options[:view_name]}_count", options.merge(:include_docs => false))['rows'].size
    per_page = row_count if per_page == "all"
    [row_count, self.paginate(options.merge(:design_doc => 'Child', :page => page, :per_page => per_page, :include_docs => true))]
  end

  def self.build_solar_schema
    text_fields = build_text_fields_for_solar
    date_fields = build_date_fields_for_solar
    Sunspot.setup(Child) do
      text *text_fields
      date *date_fields
      date_fields.each { |date_field| date date_field }
      boolean :duplicate
    end
  end

  def self.build_text_fields_for_solar
    ["unique_identifier", "short_id", "created_by", "created_by_full_name", "last_updated_by", "last_updated_by_full_name", "created_organisation"] + Field.all_searchable_field_names
  end

  def self.build_date_fields_for_solar
    ["created_at", "last_updated_at"]
  end

  def validate_has_at_least_one_field_value
    return true if field_definitions.any? { |field| is_filled_in?(field) }
    return true if !@file_name.nil? || !@audio_file_name.nil?
    return true if deprecated_fields && deprecated_fields.any? { |key, value| !value.nil? && value != [] && value != {} && !value.to_s.empty? }
    errors.add(:validate_has_at_least_one_field_value, I18n.t("errors.models.child.at_least_one_field"))
  end

  def validate_age
    return true if age.nil? || age.blank? || !age.is_number? || (age =~ /^\d{1,2}(\.\d)?$/ && age.to_f > 0 && age.to_f < 100)
    errors.add(:age, I18n.t("errors.models.child.age"))
  end

  def validate_photos
    return true if @photos.blank? || @photos.all? { |photo| /image\/(jpg|jpeg|png)/ =~ photo.content_type }
    errors.add(:photo, I18n.t("errors.models.child.photo_format"))
  end

  def validate_photos_size
    return true if @photos.blank? || @photos.all? { |photo| photo.size < 10.megabytes }
    errors.add(:photo, I18n.t("errors.models.child.photo_size"))
  end

  def validate_audio_size
    return true if @audio.blank? || @audio.size < 10.megabytes
    errors.add(:audio, I18n.t("errors.models.child.audio_size"))
  end

  def validate_audio_file_name
    return true if @audio_file_name == nil || /([^\s]+(\.(?i)(amr|mp3))$)/ =~ @audio_file_name
    errors.add(:audio, "Please upload a valid audio file (amr or mp3) for this child record")
  end

  def has_valid_audio?
    validate_audio_size.is_a?(TrueClass) && validate_audio_file_name.is_a?(TrueClass)
  end

  def validate_created_at
    begin
      if self['created_at']
        DateTime.parse self['created_at']
      end
      true
    rescue
      errors.add(:created_at, '')
    end
  end

  def validate_last_updated_at
    begin
      if self['last_updated_at']
        DateTime.parse self['last_updated_at']
      end
      true
    rescue
      errors.add(:last_updated_at, '')
    end
  end

  def method_missing(m, *args, &block)
    self[m]
  end

  def self.all
    view('by_name', {})
  end

  def self.all_by_creator(created_by)
    self.by_created_by :key => created_by
  end

  # this is a helper to see the duplicates for test purposes ... needs some more thought. - cg
  def self.duplicates
    by_duplicate(:key => true)
  end

  def self.duplicates_of(id)
    by_duplicates_of(:key => id).all
  end

  def self.search_by_created_user(search, created_by, page_number = 1)
    created_by_criteria = [SearchCriteria.new(:field => "created_by", :value => created_by, :join => "AND")]
    search(search, page_number, created_by_criteria, created_by)
  end

  def self.search(search, page_number = 1, criteria = [], created_by = "")
    return [] unless search.valid?
    search_criteria = [SearchCriteria.new(:field => "short_id", :value => search.query)]
    search_criteria.concat([SearchCriteria.new(:field => "name", :value => search.query, :join => "OR")]).concat(criteria)
    SearchService.search page_number, search_criteria
  end

  def self.flagged
    by_flag(:key => true)
  end

  def self.all_connected_with(user_name)
     #TODO Investigate why the hash of the objects got different.
     (by_user_name(:key => user_name).all + all_by_creator(user_name).all).uniq {|child| child.unique_identifier}
  end

  def create_unique_id
    self['unique_identifier'] ||= UUIDTools::UUID.random_create.to_s
  end

  def short_id
    (self['unique_identifier'] || "").last 7
  end

  def unique_identifier
    self['unique_identifier']
  end

  def has_one_interviewer?
    user_names_after_deletion = self['histories'].map { |change| change['user_name'] }
    user_names_after_deletion.delete(self['created_by'])
    self['last_updated_by'].blank? || user_names_after_deletion.blank?
  end

  def mark_as_duplicate(parent_id)
    self['duplicate'] = true
    self['duplicate_of'] = Child.by_short_id(:key => parent_id).first.try(:id)
  end

  def self.schedule(scheduler)
    scheduler.every("24h") do
      Child.reindex!
    end
  end

  private

  def deprecated_fields
    system_fields = ["created_at",
                     "last_updated_at",
                     "last_updated_by",
                     "last_updated_by_full_name",
                     "posted_at",
                     "posted_from",
                     "_rev",
                     "_id",
                     "short_id",
                     "created_by",
                     "created_by_full_name",
                     "couchrest-type",
                     "histories",
                     "unique_identifier",
                     "current_photo_key",
                     "created_organisation",
                     "photo_keys"]
    existing_fields = system_fields + field_definitions.map { |x| x.name }
    self.reject { |k, v| existing_fields.include? k }
  end

  def key_for_content_type(content_type)
    Mime::Type.lookup(content_type).to_sym.to_s
  end

  def validate_duplicate_of
    return errors.add(:duplicate, I18n.t("errors.models.child.validate_duplicate")) if self["duplicate"] && self["duplicate_of"].blank?
  end
end
