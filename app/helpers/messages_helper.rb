module MessagesHelper
  def remove_bulk_quoting(message_body)
    message_body = message_body.strip.split(/[\-_]{10,}\n([^\n]+\n?)?http:\/\/[^\n]+/).first
    trimmed = []
    bulk = true
    message_body.strip.split(/\n/).reverse.each do |line|
      unless (line.strip.empty? or line =~ /^>/) and bulk
        trimmed << line
        bulk = false
      end
    end
    trimmed.reverse.join("\n").split(/\s*[\-_]+?.original.message.[\-_]+?/i).first.split(/[\-_]+\s*from:.*?\(via/i).first.strip
  end
end
