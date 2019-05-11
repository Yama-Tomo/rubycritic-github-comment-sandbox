require 'net/http'
require 'uri'
require 'openssl'
require 'aws-sdk-kms'
require 'json'

def main(event:, context:)
  return unless %w[opened synchronize].include? event['action']

  repo = event['pull_request']['head']['repo']['full_name']
  branch = event['pull_request']['head']['ref']
  uri = URI.parse("https://circleci.com/api/v1.1/project/github/#{repo}/tree/#{branch}?circle-token=#{circleci_token}")

  request = Net::HTTP::Post.new(uri.request_uri, initheader = { 'Content-Type' =>'application/json' })

  body = {
    build_parameters: { CIRCLE_JOB: 'rubycritic' }
  }
  body[:build_parameters][:BEFORE_REVISION] = event['before'] unless event['before'].nil?
  body[:build_parameters][:AFTER_REVISION] = event['after'] unless event['after'].nil?

  request.body = body.to_json

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  http.set_debug_output $stderr

  http.start do |h|
    response = h.request(request)
  end

  return 'OK'
end

def circleci_token
  Aws::KMS::Client.new.decrypt({ ciphertext_blob: Base64.decode64(ENV['CIRCLE_CI_TOKEN']) }).plaintext
end


