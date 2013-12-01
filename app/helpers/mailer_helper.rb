module MailerHelper
  def ksp_and_galapagos_email_links(*ksp_args)
    raise "must set @bootloader_path" unless @bootloader_path
    "#{ksp_email_link(*ksp_args)}\n(imode: #{galapagos_email_link(*ksp_args)})"
  end

  def ksp_email_link(*ksp_args)
    raise "must set @bootloader_path" unless @bootloader_path
    ksp_link_args = ksp_args.dup.push({:force_kamishibai => true, :bootloader_path => @bootloader_path})
    ksp_link = ksp(*ksp_link_args)
  end

  def galapagos_email_link(*ksp_args)
    raise "must set @bootloader_path" unless @bootloader_path
    galapagos_link_args = ksp_args.dup.push({:force_galapagos => true, :bootloader_path => @bootloader_path})
    galapagos_link = ksp(*galapagos_link_args)
  end

  def linkify(url)
    "<a href=\"#{url}\">#{url}</a>"
  end

  # options :text => true/false
  def mail_footer(options = {})
    t('message_mailer.footer', :namespace => @conference.tag)
  end
end
