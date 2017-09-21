module Lita
  module Handlers
    class Api < Handler
      config :api_key, required: true
      config :api_url, required: true

      route(/^api|_\s+(.+)/, :reply, command: true, help: {
        "api|_" => "Returns a JSON representation of the API query."
      })

      def reply(input)
        query = input.match_data[1] # the user's actual query
        server_response = call_api(query) # receive a JSON response
        input.reply format_reply(server_response) # reply with a formatted message for Slack
      end

      private

        def api_key
          Lita.config.handlers.api.api_key
        end

        def api_url
          Lita.config.handlers.api.api_url
        end

        def format_reply(response)
          begin
            body_hash = MultiJson.load(response.body)

            if body_hash['response'] # did not return an Array or Hash
              if body_hash['response'].is_a?(String)
                format_as_slack_code("=> \"#{body_hash['response']}\"")
              else # Numbers
                format_as_slack_code("=> #{body_hash['response']}")
              end
            else # Array or Hash
              format_as_slack_code(body_hash.map{|k,v| "#{k}: #{v}"}.flatten)
            end
          rescue # Catch all
            format_as_slack_code("=> #{response.body}")
          end
        end

        def format_as_slack_code(text)
          ['```',text,'```'].join('
')
        end

        def call_api(query)
          payload = {api_key: api_key, query: query}
          http.post(api_url, payload)
        end

      Lita.register_handler(self)
    end
  end
end


# '{
# "attachments": [
# {
# "fallback": "Required plain-text summary of the attachment.",
# "color": "#36a64f",
# "pretext": "Optional text that appears above the attachment block",
# "author_name": "Bobby Tables",
# "author_link": "http://flickr.com/bobby/",
# "author_icon": "http://flickr.com/icons/bobby.jpg",
# "title": "Slack API Documentation",
# "title_link": "https://api.slack.com/",
# "text": "Optional text that appears within the attachment",
# "fields": [
#     {
#         "title": "Priority",
#         "value": "High",
#         "short": false
#     }
# ],
# "image_url": "http://my-website.com/path/to/image.jpg",
# "thumb_url": "http://example.com/path/to/thumb.png",
# "footer": "Slack API",
# "footer_icon": "https://platform.slack-edge.com/img/default_application_icon.png",
# "ts": 123456789
# }
# ]
# }'
