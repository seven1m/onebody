File.open(File.dirname(__FILE__)+'/README') { |f| puts f.read.split(/=+/)[0..1].join }
puts "Please view the README for more instructions."
