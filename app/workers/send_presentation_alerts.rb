# encoding: UTF-8

class SendPresentationAlerts
  NOTIFY_TIME = 15 # notify at NOTIFY_TIME (secs) before presentation starts_at

  begin
    include SendPresentationAlertsExtensions
  rescue
  end

  # Provide the time as string. (useful for testing)
  # Defaults to Time.now.
  def self.perform(time = "2013-12-03 9:00:00 +0900")
    puts "Presentation Alert batch job start: #{Time.zone.now.strftime('%Y-%m-%d %H:%M:%S')}"
    if time
      time = Time.zone.parse(time)
    else
      time = Time.zone.now
    end

    starts_at_from = time.advance(:minutes => NOTIFY_TIME)
    starts_at_till = time
    # Will send alerts for any presentations that started prior to starts_at_from
    # unless :email_alert_sent is true.
    # Ensures that emails will be send even if resque skips a beat.
    # However, cuts off with presentations that have already started.
    #
    # Send email in batches per presentation.
    # Checks Schedule#email_alert_sent so that we don't send alerts twice.
    presentations = Presentation::TimeTableable.includes(:schedules).
                      where("? <= starts_at AND starts_at <= ?", time, starts_at_from)
    presentations.each do |p|
      schedules = p.schedules.select{|s| !s.email_alert_sent && s.user.email_notifications}
      schedules.each do |s|
        # Reconfirm that the email hasn't been sent
        s.reload
        next if s.email_alert_sent

        recipient = s.user
        p.send_email(:receivers => [recipient], :mailer_method => :presentation_alert)
        s.update_column(:email_alert_sent, true)
        puts "Presentation Alert Email sent out for #{p.session.number} - #{p.number}: to user #{recipient.email}"
        Rails.logger.info("Presentation Alert Email sent out for #{p.session.number} - #{p.number}: to user #{recipient.email}")
      end

    end
    puts "Presentation Alert batch job end: #{Time.zone.now.strftime('%Y-%m-%d %H:%M:%S')}"
  end

end