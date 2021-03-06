class CreatePullRequestService
  PR_REGEX = /https:\/\/github.com\/\S*\/\S*\/\s*(pull|issues)\/[0-9]*/

  attr_reader :params

  def self.call(params)
    self.new(params).call
  end

  def initialize(params)
    @params = params
  end

  def call
    channel = "##{params['channel_name']}"
    channel_id = params['channel_id']
    author_user_name = params['user_name']

    return unless valid_user(author_user_name) && non_threaded?

    urls = URI.extract(params['text'])
    author_id = params['user_id']
    thread_ts = params['timestamp']
    if urls
      urls.each do |url|
        next if URI(url).host != 'github.com'
        url.chomp!("/")

        PullRequest.create(
          url: url.match(PR_REGEX)[0],
          author_id: author_id,
          author_user_name:  author_user_name,
          thread_ts: thread_ts,
          channel: channel,
          channel_id: channel_id
          )
      end
    end
  end

  private

  def non_threaded?
    params['thread_ts'].nil?
  end

  def valid_user(user_name)
    !ENV['BLACK_LIST_SLACK_USER'].to_s.split(',').include?(user_name)
  end
end
