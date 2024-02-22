class Permission

  def self.to_ordered_hash(*hashes)
    ordered = ActiveSupport::OrderedHash.new

    hashes.each do |hash|
      hash.each { |key, value| ordered[key] = value }
    end
    ordered
  end

  CHILDREN = Permission.to_ordered_hash({:register => "Register Child"},
                                        {:edit => "Edit Child"},
                                        {:view_and_search => "View And Search Child"},
                                        {:export_photowall => "Export to Photowall"},
                                        {:export_csv => "Export to CSV"},
                                        {:export_pdf => "Export to PDF"},
                                        {:export_cpims => "Export to CPIMS"}
  )
  ENQUIRIES = Permission.to_ordered_hash({:create => "Create Enquiry"},
                                         {:update => "Update Enquiry"}
  )
  FORMS = Permission.to_ordered_hash(:manage => "Manage Forms")
  USERS = Permission.to_ordered_hash({:create_and_edit => "Create and Edit Users"}, {:view => "View Users"},
                                     {:destroy => "Delete Users"}, {:disable => "Disable Users"})
  DEVICES = Permission.to_ordered_hash(:black_list => "BlackList Devices", :replications => "Manage Replications")
  REPORTS = Permission.to_ordered_hash(:view => 'View and Download Reports')
  ROLES = Permission.to_ordered_hash({:create_and_edit => "Create and Edit Roles"}, {:view => "View roles"})
  SYSTEM = Permission.to_ordered_hash(:highlight_fields => "Highlight Fields",
                                      :system_users => "Users for synchronisation")

  def self.all
    {"Children" => CHILDREN, "Forms" => FORMS, "Users" => USERS, "Devices" => DEVICES, "Reports" => REPORTS, "Roles" => ROLES, "System" => SYSTEM, "Enquiries" => ENQUIRIES}
  end

  def self.all_permissions
    all.values.map(&:values).flatten
  end

  def self.hashed_values
    {"Children" => CHILDREN.values, "Forms" => FORMS.values, "Users" => USERS.values, "Devices" => DEVICES.values, "Reports" => REPORTS.values, "Roles" => ROLES.values, "System" => SYSTEM.values, "Enquiries" => ENQUIRIES.values}
  end

end
