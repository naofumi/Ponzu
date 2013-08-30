class PrivateMessage

  # extend ActiveModel::Translation
  # extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations
  validates_presence_of :body, :to_id, :from
  include ActiveModel::MassAssignmentSecurity
  attr_accessor :subject, :body, :to_id, :from
  attr_reader :to

  attr_accessible :subject, :body, :to_id, :from

  def initialize(values = {})
    assign_attributes values
  end
  
  # Copied from rdoc in ActiveModel::MassAssignmentSecurity::ClassMethods
  def assign_attributes(values, options = {})
    sanitize_for_mass_assignment(values, options[:as]).each do |k, v|
      send("#{k}=", v)
    end
  end

  # Because a single Author might have multiple Users associated with it,
  # we need to send messages to each of the Users when we send a PrivateMessage
  # to an Author.
  #
  # Hence to_id parameter may be a single string or an array of strings.
  # In all cases, we return an array of Integers.
  def to_id=(id)
    @to_id = [].push(id).flatten.map{|e| e.to_i} unless id.blank?
  end

  def to
    @to ||= User.find(to_id)
  end

  # Returns the message on success
  def save
    if valid?
      from.send_message(:to => to,
                        :subject => subject,
                        :body => body,
                        :mailer_method => :private_message)
    else
      false
    end
  end

  def self.create(*args)
    self.new(*args).save
  end
  
  def persisted?
    false
  end

  def self.threads(user)
    user.threads(Receipt.from_type('User'))
  end

end