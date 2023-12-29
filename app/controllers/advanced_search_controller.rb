class AdvancedSearchController < ApplicationController

  def index
    @page_name = t("navigation.advanced_search")
    @forms = FormSection.by_order
    @search_form = Forms::SearchForm.new(ability: current_ability, params: params).execute
    @results = @search_form.results
  end

  def export_data
    RapidftrAddon::ExportTask.active.each do |export_task|
      if params[:commit] == t("addons.export_task.#{export_task.id}.selected")
        authorize! "export_#{export_task.id}".to_sym, Child
        process_export(export_task) and return
      end
    end
  end

  private

  def process_export(export_task)
    record_ids = []
    children = []

    if params["all"] == "Select all records"
      search_params = params[:search_params].merge(page: 1, per_page: 1000)
      @search_form = Forms::SearchForm.new(ability: current_ability, params: search_params).execute
      children = @search_form.results
      record_ids = @search_form.results.collect(&:id)
    else
      record_ids = Hash[params["selections"].sort].values rescue []
      children = record_ids.map { |id| Child.get id }
    end

    raise ErrorResponse.bad_request('You must select at least one record to be exported') if record_ids.empty?

    results = export_task.new.export(children)
    encrypt_exported_files results, export_filename(children, export_task)
  end

  def export_filename(children, export_task)
    (children.length == 1 ? children.first.short_id : current_user_name) + '_' + export_task.id.to_s + '.zip'
  end

end
