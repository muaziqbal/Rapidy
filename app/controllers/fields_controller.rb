class FieldsController < ApplicationController

  before_filter { authorize! :manage, Field }
  before_filter :read_form_section

  FIELD_TYPES = %w{ text_field textarea check_box select_box radio_button numeric_field date_field }

  def read_form_section
    @form_section = FormSection.get_by_unique_id(params[:form_section_id])
  end

  def new
    @body_class = 'forms-page'
    @suggested_fields = SuggestedField.all_unused
    @field = Field.new(:type => params[:type])
    @page_name = t("new")+" #{@field.type.humanize}"
    render params[:fieldtype]
  end

  def edit
    @body_class = 'forms-page'
    @field = @form_section.fields.detect { |field| field.name == params[:id] }
    render :template => "form_section/edit", :locals => {:show_add_field => true}
  end

  def choose
    @body_class = 'forms-page'
    @suggested_fields = SuggestedField.all_unused
  end

  def create
    @field = Field.new params[:field]

    FormSection.add_field_to_formsection @form_section, @field
    if (@field.errors.length == 0)
      SuggestedField.mark_as_used(params[:from_suggested_field]) if params.has_key? :from_suggested_field
      flash[:notice] = "Field successfully added"
      redirect_to(edit_form_section_path(params[:form_section_id]))
    else
      render :template => "form_section/edit", :locals => {:show_add_field => true}
    end
  end

  #def update
  #  @field = @form_section.fields.detect { |field| field.name == params[:id] }
  #  @field.attributes = params[:field] unless params[:field].nil?
  #  if params[:destination_form_id] == params[:form_section_id]
  #    @form_section.save
  #  else
  #    @form_section.delete_field @field.name
  #    destination_form = FormSection.get_by_unique_id(params[:destination_form_id]) || @form_section
  #    destination_form.add_field @field
  #    destination_form.save
  #  end
  #
  #  if (@field.errors.length == 0)
  #    flash[:notice] = "Field updated"
  #    message = {"status" => "ok"}
  #    if (request.xhr?)
  #      render :json => message
  #    else
  #      redirect_to(edit_form_section_path(params[:form_section_id]))
  #    end
  #  else
  #    render :action => "edit"
  #  end
  #end
  def update
    @field = fetch_field params[:id]
    @field.attributes = params[:field] unless params[:field].nil?
    @form_section.save
    if (@field.errors.length == 0)
      flash[:notice] = "Field updated"
      message = {"status" => "ok"}
      if (request.xhr?)
        render :json => message
      else
        render :template => "form_section/edit"
      end
    else
      @show_add_fields = {:show_add_field => true}
      render :template => "form_section/edit", :locals => @show_add_fields
    end
  end

  def move_up
    @form_section.move_up_field(params[:field_name])
    redirect_to(edit_form_section_path(params[:form_section_id]))
  end


  def move_down
    @form_section.move_down_field(params[:field_name])
    redirect_to(edit_form_section_path(params[:form_section_id]))
  end

  def destroy
    field = @form_section.fields.find { |field| field.name == params[:field_name] }
    @form_section.delete_field(field.name)
    flash[:notice] = "Field '#{field.display_name}' has been deleted."
    redirect_to(edit_form_section_path(params[:form_section_id]))
  end

  def toggle_fields
    field =  fetch_field params[:id]
    field.visible = !field.visible
    @form_section.save
    render :text => "OK"
  end

  private
  def fetch_field field_name
    @form_section.fields.detect { |field| field.name == field_name }
  end
end
