Before do
  I18n.locale = I18n.default_locale = :en
  CouchRest::Model::Base.descendants.each do |model|
    docs = model.database.documents["rows"].map { |doc|
      { "_id" => doc["id"], "_rev" => doc["value"]["rev"], "_deleted" => true } unless doc["id"].include? "_design"
    }.compact
    RestClient.post "#{model.database.root}/_bulk_docs", { :docs => docs }.to_json, { "Content-type" => "application/json" } unless docs.empty?
  end

  RapidFTR::FormSectionSetup.reset_definitions
  RSpec::Mocks.space.proxy_for(Clock).reset

  Sunspot.remove_all!(Child)
  Sunspot.remove_all!(Enquiry)
end

Before('@roles') do |scenario|
  Role.create(:name => 'Field Worker', :permissions => [Permission::CHILDREN[:register]])
  Role.create(:name => 'Field Admin', :permissions => [Permission::CHILDREN[:view_and_search], Permission::CHILDREN[:create], Permission::CHILDREN[:edit]])
  Role.create(:name => 'Admin', :permissions => Permission.all_permissions)
end

Before('@no_expire') do |scenario|
  Rails.application.config.stub(:session_options).and_return({
    key: '_rftr_session',
    expire_after: 99.years,
    rapidftr: {
      web_expire_after: 99.years,
      mobile_expire_after: 99.years
    }
  })
end

After('@no_expire') do
  RSpec::Mocks.space.proxy_for(Rails.application.config).reset
end
