# encoding: UTF-8

# DEPRECATED
#
# View this to understand the code for nayose.
#
# After that, delete it.

require 'csv'

class Registrant < ActiveRecord::Base
  attr_accessible :affiliation, :first_name, :last_name, :middle_name, :password, :phon_first_name, :phon_last_name, :phon_middle_name, :registration_id, :salutation
  belongs_to  :user, :foreign_key => :registration_id, :primary_key => :login, :inverse_of => :registrant

  # Deletes all prior data so the data in the
  # database exactly represents the stuff in the
  # CSV files.
  #
  # We convert the xls file to UTF-16 tab delimited text in Excel,
  # and convert it to UTF-8 in BBEdit. I had to do this because
  # Mac Excel did wonky things to some Kanji when it wrote out in Mac ShiftJIS
  # We have to be careful because 﨑村 (as opposed to 崎村) for example doesn't transfer well.
  def self.import
    Registrant.delete_all
    filename = "user_ids.txt"
    filepath = File.expand_path("../../../data/#{filename}", __FILE__)
    CSV.foreach(filepath, :col_sep => "\t") do |row|
      next if row[4 - 1] !~ /^\d+$/ && row[4 - 1] !~ /^jbs\d+$/
      Registrant.create!(:registration_id => diet(row[4 - 1]),
                        :password => diet(row[5 - 1]),
                        :first_name => diet(row[7 - 1]),
                        :middle_name => diet(row[8 - 1]),
                        :last_name => diet(row[9 - 1]),
                        :phon_first_name => diet(row[10 - 1]),
                        :phon_middle_name => diet(row[11 - 1]),
                        :phon_last_name => diet(row[12 - 1]),
                        :salutation => diet(row[13 -1]),
                        :affiliation => diet(row[14 - 1])
                        )
    end
  end

  def self.diet(string)
    return nil unless string
    result = string.gsub(/　/, ' ').gsub(/\s+/, ' ').strip
    result = nil if result.blank?
    result
  end

  def self.activate_all_users_if_unique_and_create_user_if_not_existing
    puts "<html><head><style>table, td, tr, th {border: solid 1px #444}</style></head><body><table>"
    Registrant.find_each do |r|
      next if User.find_by_login(r.registration_id)
      if r.is_unique_registrant_name?
        r.find_and_activate_or_create_and_activate_user
      else
        r.registrants_with_same_name.all.each_with_index do |r, i|
          if User.find_by_login(r.registration_id)
          else
            puts "<tr><td>will defer due to multiple registrants with same name</td>" +
                 "<td>#{r.link_to_registrant}</td>" +
                 "<td>#{r.registrants_with_same_name.map{|r| index ||= 0; index += 1; "#{r.link_to_registrant(index)}"}.join('<br />')}</td></tr>"
          end
        end
      end
    end
    puts "</table></body></html>"

  end

  def find_and_activate_or_create_and_activate_user
    if find_users_by_name.size > 1
      puts "<tr><td>will defer due to namesakes in Users</td>" + 
           "<td>#{link_to_registrant}</td>"+
           "<td>#{find_users_by_name.map{|u| link_to_user(u)}.join('<br />')}</td></tr>"
    elsif user = find_users_by_name.first
      if user.whitelisted
        activate_user(user)
      else
        puts "<tr><td>will defer due to blacklisted</td><td>#{link_to_registrant}</td><td>#{link_to_user(user)}</td></tr>"
      end
    else          
      puts "<tr><td>will create new user due to non-existing</td><td>#{link_to_registrant}</td></tr>"
      create_and_activate_user
    end
  end

  def activate_user(user)
    unless user.login_active?
      user.activate_by!(:login => registration_id, :password => password)
    else
      puts "<tr><td>will defer due to matching user already activated</td><td>#{link_to_registrant}</td><td>#{link_to_user(user)}</td></tr>"
    end
  end

  def link_to_registrant(index = 0)
    "Registrant: <a href='/ja/registrants/#{self.id}' target='registrant_#{index}'>#{registration_id} #{first_name} #{middle_name} #{last_name} #{affiliation}</a>"
  end

  def link_to_user(user, index = 0)
    "User: <a href='/ja/users/#{user.id}' target='user_#{index}'>#{user.id} #{user.jp_name} #{user.en_name}</a>"
  end

  def create_and_activate_user
    if first_name =~ /^[ \.a-zA-Z0-9]+$/ && last_name =~ /^[ \.a-zA-Z0-9]+$/
      en_name = [first_name, middle_name, last_name].compact.join(' ')
      jp_name = nil
    else
      en_name = nil
      jp_name = [first_name, middle_name, last_name].compact.join(' ')
    end
    user = User.create!(:en_name => en_name, :jp_name => jp_name)
    activate_user(user)
  end

  def registrants_with_same_name
    Registrant.
      where(:first_name => first_name, :middle_name => middle_name, :last_name => last_name).
      order(:id)
  end

  def is_unique_registrant_name?
    registrants_with_same_name.count == 1
  end

  def find_users_by_name
    all_jp = all_users_by_jp_name
    if all_jp.empty?
      all_users_by_en_name
    else
      all_jp
    end
  end

  def all_users_by_jp_name
    User.find_all_by_jp_name("#{first_name} #{last_name}")
  end

  def all_users_by_en_name
    User.where("en_name = ? OR en_name = ? OR en_name = ? OR en_name = ?",
               "#{first_name} #{last_name}",
               "#{last_name} #{first_name}",
               "#{first_name} #{middle_name} #{last_name}",
               "#{last_name} #{middle_name} #{first_name}")
  end
end
