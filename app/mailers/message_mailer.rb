class MessageMailer < ActionMailer::Base
  helper :kamishibai_path, :mailer, :i18n

  def private_message(options)
    @to, @subject, @body, @obj = options[:to], options[:subject], options[:body], options[:obj]
    @bootloader_path = default_bootloader_path(@obj)
    @conference = conference(@to)
    mail(:to => email_addresses(@to), 
         :from => email_sender_address(@to),
         :subject => I18n.t('message_mailer.private_message.subject', 
                            :name => @obj.en_name, 
                            :namespace => @conference.tag))
  end

  def presentation_modified(options)
    @to, @subject, @body, @obj = options[:to], options[:subject], options[:body], options[:obj]
    @bootloader_path = default_bootloader_path(@obj)
    @conference = conference(@to)
    mail(:to => email_addresses(@to), 
         :from => email_sender_address(@to),
         :subject => I18n.t('message_mailer.presentation_modified.subject', 
                            :number => @obj.number,
                            :namespace => @conference.tag))
  end

  # Here, :to is a list of Authors instead of a list of Users.
  def comment_added(options)
    @to, @subject, @body, @obj = options[:to], options[:subject], options[:body], options[:obj]
    @bootloader_path = default_bootloader_path(@obj)
    @conference = conference(@to)
    mail(:to => email_addresses(@to),
         :from => email_sender_address(@to),
         :subject => I18n.t('message_mailer.comment_added.subject', 
                            :number => @obj.presentation.number,
                            :namespace => @conference.tag))
  end

  private

  def conference(objects)
    [objects].flatten.first.conference
  end

  def email_sender_address(objects)
    "#{conference(objects).tag}-no-reply@castle104.com"
  end

  # The +objects+ argument is an array of objects that
  # respond to #email. Normally, this would be a set of Users.
  def email_addresses(objects)
    conference = [objects].flatten.first.conference
    if !conference.send_all_emails_to.blank?
      conference.send_all_emails_to.split(' ')
    else
      objects.map{|o| o.email}.uniq.compact
    end
  end

  # Gets the bootloder path from the conference associated with the obj
  def default_bootloader_path(obj) # :doc:
    subdomain = obj.conference.subdomain
    if %w(test development).include? Rails.env
      "http://#{subdomain}.ponzu.local:3000"
    else
      "http://#{subdomain}.castle104.com"
    end
    # Rails.configuration.message_mailer_bootstrap
  end
end
