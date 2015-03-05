# encoding: utf-8
# Isolated authentication and permission concerns from the User object
#
# Include into the User class
module User::Authentication
  ## Roles for CanCan
  # add new roles on right end to preserve previous settings
  ROLES = %w[admin user_moderator organizer voter sponsor]

  def self.included(base)
    base.extend ClassMethods
    
    # Stuff that we would write directly in the class
    # definition
    base.instance_eval do
      acts_as_authentic do |c|
        # http://rdoc.info/github/binarylogic/authlogic/Authlogic/ActsAsAuthentic/ValidationsScope/Config
        # Scope everything to #conference_tag
        # This only seems to work on the configurations after
        # validations_scope has been set, so we have to set it early.
        # In fact, given that it's a bit finicky, we better set
        # scope independently whenever we need it.
        c.validations_scope = :conference_tag

        # upgrading crypto algorithms http://www.binarylogic.com/2008/11/23/tutorial-upgrade-passwords-easily-with-authlogic/
        c.transition_from_crypto_providers = Authlogic::CryptoProviders::Sha512,
        c.crypto_provider = Authlogic::CryptoProviders::SCrypt # the new default for Authlogic

        # The following tutorial outlines a sign-on scheme that looks pretty nice.
        # http://www.claytonlz.com/2009/07/authlogic-account-activation-tutorial/
        #
        # 1. New user first enters email only.
        # 2. Validate that with a tokenized link.
        # 3. On clicking the link, you are sent to a page where you enter
        #    futher information about yourself.
        # 4. Enter other stuff.
        #
        # The validations will support this scheme.

        c.validates_length_of_password_field_options = {:minimum => 4, :if => :has_no_credentials?}
        c.validates_length_of_password_confirmation_field_options = {:minimum => 4, :if => :has_no_credentials?}
 

        # https://gist.github.com/436707/        
        c.merge_validates_format_of_login_field_options({:unless => :login_not_set?})
        c.merge_validates_length_of_login_field_options({:unless => :login_not_set?})
        # c.merge_validates_uniqueness_of_login_field_options({:unless => :login_not_set?})
        
        c.merge_validates_length_of_email_field_options({:unless => :email_not_set?})
        c.merge_validates_format_of_email_field_options({:unless => :email_not_set?})
        # There seem to be cases where people are sharing email addresses. We
        # cannot always assume emails to be unique. However, going forward,
        # we will assume that emails are unique.
        # c.merge_validates_uniqueness_of_email_field_options({:unless => Proc.new{true}})
        c.merge_validates_uniqueness_of_email_field_options({:unless => :email_not_set?, scope: :conference_tag})

        # c.merge_validates_confirmation_of_password_field_options({:unless => :login_not_set?})
        # c.merge_validates_length_of_password_field_options({:unless => :login_not_set?})
        # c.merge_validates_length_of_password_confirmation_field_options({:unless => :login_not_set?})

        c.perishable_token_valid_for(24.hours)
      end

      # Validations that aren't provided by Authlogic
      # http://stackoverflow.com/a/2391466
      # We can't use the :has_no_credentials? check
      # because it seems that Authlogic sets the crypted_password before
      # regular validations are performed, and so :has_no_credentials?
      # always returns false.
      # Instead we :allow_blank and let Authlogic block blank passwords
      # depending on :has_no_credentials?
      validates_format_of :password, :with => /^[a-zA-Z0-9\x20-\x7E]+$/, :allow_blank => true, 
                          :message => "は半角英数字と半角記号を使ってください。"

      ## Scope for CanCan
      scope :with_role, lambda {|role|
        role_query_mask = 2**User::ROLES.index(role)
        where("roles_mask & ? != 0", role_query_mask)
      }

    end

    def email_not_set?
      email.blank?
    end

    def login_not_set?
      login.blank?
    end
  end
  

  # we need to make sure that a password gets set
  # it is previously empty.
  def has_no_credentials?
    self.crypted_password.blank?
  end

  # If this returns false, you will not be able to log into this account.
  # (Authlogic feature).
  #
  # In the Registration Engine, we allow anybody to sign-up but only if they
  # enter a valid email address. The email address is confirmed by sending them
  # a perishable token. Users cannot login unless they first activate their account
  # with the perishable token. 
  #
  # You can set whether or not you want to use this sign-up scheme in config/conferences.yml
  # http://www.rubydoc.info/github/binarylogic/authlogic/Authlogic/Session/MagicStates
  def confirmed?
    if conference.config(:email_confirmation_required) && respond_to?(:email_confirmed)
      email_confirmed
    else
      true
    end
  end


  ## Cancan roles  
  def roles=(roles)
    self.roles_mask = (roles & ROLES).map{|r| 2**ROLES.index(r)}.sum
  end
  
  def roles
    ROLES.reject{|r| ((roles_mask || 0) & 2**ROLES.index(r)).zero?}
  end
  
  def role?(role)
    roles.include? role.to_s
  end
  
  module ClassMethods
    # We have single_table_inheritance setup for the User object so
    # this should automatically return the appropriate User subclass.
    # However, we might have set up users before we created the User subclass
    # in which case the `type` field will not have been set. In this
    # case, we will not get the corrects subclass.
    #
    # To guard against these cases, we reset the type field and reload if necessary.
    def find_by_login_or_email_according_to_conference_setting(login)
      return nil if login.blank?
      if user = find_by_login(login)
        return reset_type_of_user_if_not_set(user)
      elsif (user = find_by_email(login)) && 
            user.conference.config(:allow_email_for_login)
        return reset_type_of_user_if_not_set(user)
      else
        return nil
      end
    end

    def reset_type_of_user_if_not_set(user)
      user_class = user.conference.user_class
      if user_class != user.class
        user.update_attribute("type", user_class.to_s)
        user.reload
      end
      return user
    end
  end

end