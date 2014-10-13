# encoding: UTF-8

# Don't accept requests with invalid byte sequence
# see: http://dev.mensfeld.pl/2014/03/rack-argument-error-invalid-byte-sequence-in-utf-8/
class Utf8SanitizerMiddleware
  SANITIZE_ENV_KEYS = %w(
    HTTP_REFERER
    PATH_INFO
    REQUEST_URI
    REQUEST_PATH
    QUERY_STRING
  )
 
  def initialize(app)
    @app = app
  end
 
  def call(env)
    SANITIZE_ENV_KEYS.each do |key|
      string = env[key].to_s
      valid = URI.decode(string).force_encoding('UTF-8').valid_encoding?
      # Don't accept requests with invalid byte sequence
      return [ 400, { }, [ 'Bad request' ] ] unless valid
    end
 
    @app.call(env)
  end
end