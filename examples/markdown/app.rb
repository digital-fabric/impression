require 'bundler/setup'
require 'impression'
require 'tipi'

pages = Impression::Pages.new(File.join(__dir__, 'docs'))
app = pages.method(:serve).to_proc

opts = {
  reuse_addr:  true,
  dont_linger: true
}

puts "pid: #{Process.pid}"
puts 'Listening on port 4411...'

Tipi.serve('0.0.0.0', 4411, opts) do |req|
  app.call(req)
rescue Exception => e
  p e
  puts e.backtrace.join("\n")
  status = e.respond_to?(:http_status) ? e.http_status : 500
  req.respond(e.inspect, ':status' => status)
end
p 'done...'
