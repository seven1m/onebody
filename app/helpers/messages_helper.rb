module MessagesHelper
  def remove_bulk_quoting(message_body)
    trimmed = []
    bulk = true
    message_body.strip.split(/\n/).reverse.each do |line|
      unless line =~ /^>/ and bulk
        trimmed << line
        bulk = false
      end
    end
    trimmed.reverse.join("\n")
  end
end
