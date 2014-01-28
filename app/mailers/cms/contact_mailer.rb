class Cms::ContactMailer < ActionMailer::Base
  default from: "from@example.com"

  def contact_mail(contact)
    @contact = contact
    @contact_form = contact.contact_form
    @about = t(@contact_form.identifier, :scope => 'cms.contact_form.subject')
    @message = @contact.message_body
    mail(to: @contact_form.addressee, from: "cms@#{@contact_form.site.hostname}", reply_to: @contact.email, subject: @about)
  end
end
