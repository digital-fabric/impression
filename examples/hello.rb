require 'impression'

app = Impression.app do
  mount '/' => text_response('Hello, world!')
end

# class App < Impression::Resource
#   def route(req)
#     @response ||= text_response('Hello, world!')
#   end
# end

# run { |req| req.respond_text('Hello, world!') }
