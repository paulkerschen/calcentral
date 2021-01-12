module HtmlSanitizer
  extend self

  def sanitize_html(str)
    if str
      stripped = ActionController::Base.helpers.strip_tags str
      #ActionController's strip_tags doesn't unescape HTML, and CGI.unescape_html doesn't convert the space entity
      CGI.unescape_html(stripped).gsub('&nbsp;', ' ')
    end
  end

end
