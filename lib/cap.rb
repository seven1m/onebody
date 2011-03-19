class Capistrano::Configuration
  def render_erb_template(filename)
    template = File.read(filename)
    result   = ERB.new(template).result(binding)
  end

  def get_db_password
    @db_password ||= HighLine.new.ask('Password to use for the new "onebody" MySQL user: ') { |q| q.echo = false }
  end

  def run_and_return(cmd, options={})
    output = []
    run cmd, options do |ch, st, data|
      output << data
    end
    return output.to_s
  end
end
