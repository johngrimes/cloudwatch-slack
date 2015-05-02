require 'bundler/setup'
require 'sinatra/base'
require 'json'
require 'slack-notifier'

class CloudwatchSlack < Sinatra::Base
  def slack
    Slack::Notifier.new ENV['SLACK_WEBHOOK_URL'],
      :channel => ENV['SLACK_CHANNEL'], :username => 'Amazon Web Services'
  end

  post '/notify' do
    sns = JSON.parse(request.body.read)
    if sns['Type'] == 'Notification'
      cw = JSON.parse(sns['Message'])
      url = "https://console.aws.amazon.com/cloudwatch/home?region=" +
        "#{ENV['AWS_REGION']}#alarm:alarmFilter=ANY;name=#{cw['AlarmName']}"
      attachments = [{
        :fallback => sns['Subject'],
        :title => sns['Subject'],
        :title_link => url,
        :text => cw['NewStateReason'],
        :color => 'danger'
      }]
      slack.ping 'CloudWatch alert triggered', :attachments => attachments,
        :icon_url => ENV['ICON_URL']
    elsif sns['Type'] == 'SubscriptionConfirmation'
      url = URI.parse(sns['SubscribeURL'])
      response = Net::HTTP.get_response(url)
    end
  end
end
