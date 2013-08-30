module MailerHelper
  def ksp_and_galapagos_email_links(*ksp_args)
    raise "must set @bootloader_path" unless @bootloader_path
    ksp_link_args = ksp_args.dup.push({:force_kamishibai => true, :bootloader_path => @bootloader_path})
    galapagos_link_args = ksp_args.dup.push({:force_galapagos => true, :bootloader_path => @bootloader_path})
    ksp_link = ksp(*ksp_link_args)
    galapagos_link = ksp(*galapagos_link_args)
    "#{ksp_link}\n(imode: #{galapagos_link})"
  end

  # options :text => true/false
  def mail_footer(options = {})
    t('message_mailer.footer', :namespace => @conference.tag)
  end
end
