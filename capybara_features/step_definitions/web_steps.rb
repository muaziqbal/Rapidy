# IMPORTANT: This file is generated by cucumber-rails - edit at your own peril.
# It is recommended to regenerate this file in the future when you upgrade to a
# newer version of cucumber-rails. Consider adding your own code to a new file
# instead of editing this one. Cucumber will automatically load all capybara_features/**/*.rb
# files.

require 'uri'
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))

module WithinHelpers
  def with_scope(locator)
    locator ? within(:css, locator) { yield } : yield
  end
end
World(WithinHelpers)

Given /^(?:|I )am on (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )go to (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )press "([^\"]*)"(?: within "([^\"]*)")?$/ do |button, selector|
  with_scope(selector) do
    find("//input[@class='btn_submit']").click
    #click_button(button)
  end
end

When /^I search$/ do
  page.execute_script("$('input[value=\"#{Search}\"]').click();")
end

When /^(?:|I )(?:can )?follow "([^\"]*)"(?: within "([^\"]*)")?$/ do |link, selector|
  with_scope(selector) do
    click_link(link)
  end
end

When /^(?:|I )(?:can )?click "([^\"]*)"(?: within "([^\"]*)")?$/ do |selector, selector|
  with_scope(selector) do
    Page.find(selector).click
  end
end

When /^I follow "(.+)" span$/ do |locator|
  find(:xpath, "//span[text()='#{locator}']").click
end

When /^I cannot follow "([^\"]*)"(?: within "([^\"]*)")?$/ do |link, selector|
  exception=nil
  begin
    with_scope(selector) do
      click_link(link)
    end
  rescue Exception=>e
    exception=e
  end
  exception.should_not be_nil
  exception.class.should==Capybara::ElementNotFound
end

When /^(?:|I )fill in "([^\"]*)" with "([^\"]*)"(?: within "([^\"]*)")?$/ do |field, value, selector|
  with_scope(selector) do
    fill_in(field, :with => value)
  end
end

When /^(?:|I )(?:can )?fill in "([^\"]*)" for "([^\"]*)"(?: within "([^\"]*)")?$/ do |value, field, selector|
  with_scope(selector) do
    fill_in(field, :with => value)
  end
end

When /^(?:|I ) select "([^\"]*)" for "([^\"]*)"$/ do |value, field|
  page.execute_script "$('#{field}').trigger('focus')"
  page.execute_script "$('a.ui-datepicker-next').trigger('click')"
  page.execute_script "$(\"a.ui-state-default:contains('15')\").trigger(\"click\")"
  # fill_in(field, :with => value)
end

# Use this to fill in an entire form with data from a table. Example:
#
#   When I fill in the following:
#     | Account Number | 5002       |
#     | Expiry date    | 2009-11-01 |
#     | Note           | Nice guy   |
#     | Wants Email?   |            |
#
# TODO: Add support for checkbox, select og option
# based on naming conventions.
#
When /^(?:|I )fill in the following(?: within "([^\"]*)")?:$/ do |selector, fields|
  with_scope(selector) do
    fields.rows_hash.each do |name, value|
      step %{I fill in "#{name}" with "#{value}"}
    end
  end
end

When /^(?:|I )select "([^\"]*)" from "([^\"]*)"(?: within "([^\"]*)")?$/ do |value, field, selector|
  with_scope(selector) do
    select(value, :from => field)
  end
end

When /^(?:|I )(?:can )?check "([^\"]*)"(?: within "([^\"]*)")?$/ do |field, selector|
  with_scope(selector) do
    check(field)
  end
end

When /^(?:|I )uncheck "([^\"]*)"(?: within "([^\"]*)")?$/ do |field, selector|
  with_scope(selector) do
    uncheck(field)
  end
end

When /^(?:|I )(?:can )?choose "([^\"]*)"(?: within "([^\"]*)")?$/ do |field, selector|
  with_scope(selector) do
    choose(field)
  end
end

When /^(?:|I )attach the file "([^\"]*)" to "([^\"]*)"(?: within "([^\"]*)")?$/ do |path, field, selector|
  with_scope(selector) do
    attach_file(field, path)
  end
end

Then /^(?:|I )should see \/([^\/]*)\/$/ do |regexp|
  regexp = Regexp.new(regexp)
  if defined?(Spec::Rails::Matchers)
    page.should have_content(regexp)
  else
    page.text.should match(regexp)
  end
end

Then /^(?:|I )should see "([^\"]*)"(?: within "([^\"]*)")?$/ do |text, selector|
  with_scope(selector) do
    if defined?(Spec::Rails::Matchers)
      page.should have_content(text)
    else
      assert page.has_content?(text)
    end
  end
end

Then /^(?:|I )should not see "([^\"]*)"(?: within "([^\"]*)")?$/ do |text, selector|
  with_scope(selector) do
    if defined?(Spec::Rails::Matchers)
      page.should have_no_content(text)
    else
      assert page.has_no_content?(text)
    end
  end
end

Then /^(?:|I )should not see \/([^\/]*)\/(?: within "([^\"]*)")?$/ do |regexp, selector|
  regexp = Regexp.new(regexp)
  with_scope(selector) do
    if defined?(Spec::Rails::Matchers)
      page.should have_no_xpath('//*', :text => regexp)
    else
      assert page.has_no_xpath?('//*', :text => regexp)
    end
  end
end

Then /^the "([^\"]*)" field(?: within "([^\"]*)")? should contain "([^\"]*)"$/ do |field, selector, value|
  with_scope(selector) do
    if defined?(Spec::Rails::Matchers)
      find_field(field).value.should =~ /#{value}/
    else
      assert_match(/#{value}/, field_labeled(field).value)
    end
  end
end

Then /^the "([^\"]*)" field(?: within "([^\"]*)")? should not contain "([^\"]*)"$/ do |field, selector, value|
  with_scope(selector) do
    if defined?(Spec::Rails::Matchers)
      find_field(field).value.should_not =~ /#{value}/
    else
      assert_no_match(/#{value}/, find_field(field).value)
    end
  end
end



Then /^the "([^"]*)" radio-button(?: within "([^"]*)")? should be checked$/ do |label, selector|
  with_scope(selector) do
    field_checked = find_field(label)['checked']
    if field_checked.respond_to? :should
      ["true", "checked", true].should include field_checked
    else
      field_checked
    end
  end
end

Then /^the "([^"]*)" radio-button(?: within "([^"]*)")? should not be checked$/ do |label, selector|
  with_scope(selector) do
    field_checked = find_field(label)['checked']
    if field_checked.respond_to? :should
      field_checked.should == nil
    else
      !field_checked
    end
  end
end

Then /^the "([^"]*)" checkbox(?: within "([^"]*)")? should be checked$/ do |label, selector|
  with_scope(selector) do
    field_checked = find_field(label)['checked']
    if field_checked.respond_to? :should
      ["true", true].should include field_checked
    else
      field_checked
    end
  end
end

Then /^the "([^"]*)" checkbox(?: within "([^"]*)")? should not be checked$/ do |label, selector|
  with_scope(selector) do
    field_checked = find_field(label)['checked']
    if field_checked.respond_to? :should
      [nil, false].should include field_checked
    else
      !field_checked
    end
  end
end

Then /^(?:|I )should be on (.+)$/ do |page_name|
  if defined?(Spec::Rails::Matchers)
    URI.parse(current_url).path.should == path_to(page_name)
  else
    assert_equal path_to(page_name), URI.parse(current_url).path
  end
end

Then /^(?:|I )should have the following query string:$/ do |expected_pairs|
  actual_params   = CGI.parse(URI.parse(current_url).query)
  expected_params = Hash[expected_pairs.rows_hash.map{|k,v| [k,[v]]}]

  if defined?(Spec::Rails::Matchers)
    actual_params.should == expected_params
  else
    assert_equal expected_params, actual_params
  end
end

Then /^show me the page$/ do
  save_and_open_page
end

When /^I fill in a (\d+) character long string for "([^"]*)"$/ do |length, field|
  fill_in field, :with=>("x" * length.to_i)
end

Then /^I should see the order (.+)$/ do |input|
  current = 0
  input.split(',').each{ |match|
    index = page.body.index(match)
    assert index > current, "The index of #{match} was not greater than #{current}"
    current = index
  }
end

Then /^(.+) button is disabled$/ do |text|
  assert !find_button(text).visible?
end

When /^I click on dialogue box$/ do
  #page.driver.browser.switch_to.alert.accept
  #page.driver.wait_until(page.driver.browser.switch_to.alert.accept)
end
