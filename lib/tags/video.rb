class ComfortableMexicanSofa::Tag::Video
  include ComfortableMexicanSofa::Tag

  VIDEO_PROVIDERS = { 'youtube' => 'http://youtube.com/embed/',
                      'vimeo' => 'http://vimeo.com/video/' }
  
  def self.regex_tag_signature(identifier = nil)
    identifier ||= /[\w\/\-]+/
    /\{\{\s*cms:video:(#{identifier}):?(.*?)\s*\}\}/
  end
  
  def content
    provider = ([identifier] & VIDEO_PROVIDERS.keys).first
    return '' if provider.nil?
    video_id = params.shift
    width = params.shift
    height = params.shift
    url = "#{VIDEO_PROVIDERS[provider]}#{video_id}"
    "<iframe#{width.blank? ? " class='default'" : " width='#{width}'"}#{height.blank? ? '' : " height='#{height}'"} src='#{url}' frameborder='0' allowfullscreen></iframe>"
  end
  
end