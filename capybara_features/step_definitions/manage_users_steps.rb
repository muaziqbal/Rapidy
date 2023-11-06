Then /^I should see the following users:$/ do |user_table|
  user_names = user_table.hashes.collect { |user| user['name'] }
  manage_users_page.should_show_users_in_order(user_names)
end

private

def manage_users_page
  ManageUsersPage.new(Capybara.current_session)
end
