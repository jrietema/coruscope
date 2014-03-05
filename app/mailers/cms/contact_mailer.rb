class Cms::ContactMailer < ActionMailer::Base
  default from: "from@example.com"

  def contact_mail(contact, locale)
    I18n.locale = locale.to_sym if I18n.available_locales.include?(locale.to_sym)
    @contact = contact
    @contact_form = contact.contact_form
    @about = t(@contact_form.identifier, :scope => 'cms.contact_form.subject')
    @message = @contact.message_body
    @sender = "\"#{@contact.first_name} #{@contact.last_name}\" <#{@contact.email}>"
    @mailer = "\"#{@contact_form.site.hostname.capitalize} Form-Mailer\" <contact@#{@contact_form.site.hostname}>"
    mail(to: @contact_form.addressee, from: @mailer, reply_to: @sender, subject: @about)
  end
end
