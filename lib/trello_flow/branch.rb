require "active_support/core_ext/string/inflections"
require "trello_flow/pull_request"

module TrelloFlow
  class Branch
    def initialize(name)
      @name = name
    end

    def self.current
      new Cli.read("git rev-parse --abbrev-ref HEAD")
    end

    def self.from_card(card)
      new("#{current.target}.#{card.to_param}.#{card.short_link}")
    end

    def checkout
      Cli.run "git checkout #{name} >/dev/null 2>&1 || git checkout -b #{name}"
    end

    def push
      Cli.run "git push origin #{name} -u"
    end

    def open_pull_request
      PullRequest.new(current_card, from: name, target: target).open
    end

    def open_trello(user)
      if current_card
        Cli.open_url current_card.url
      else
        Cli.open_url "https://trello.com/#{user.username}/cards"
      end
    end

    def target
      name.split('.').first
    end

    private

      attr_reader :name

      def current_card
        @_current_card ||= Api::Card.find(card_short_link) if card_short_link
      end

      def card_short_link
        name.split(".").last
      end
  end
end
