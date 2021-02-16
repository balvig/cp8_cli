require "cp8_cli/github/api"
require "cp8_cli/github/parsed_url"
require "cp8_cli/story"

module Cp8Cli
  module Github
    class Issue < Story
      include Api::Client

      def initialize(number:, repo:, **attributes)
        @number = number
        @repo = repo
        @attributes = attributes
      end

      def self.find_by_url(url)
        url = ParsedUrl.new(url)
        issue = client.issue(url.repo, url.number).to_h
        new(**issue.merge(number: url.number, repo: url.repo))
      end

      def title
        attributes[:title]
      end

      def summary
        "Closes #{short_link}"
      end

      private

        attr_reader :number, :repo, :attributes

        def assign
          client.add_assignees repo, number, [user.github_login]
        end

        def user
          CurrentUser.new
        end

        def short_link
          "#{repo}##{number}"
        end
    end
  end
end
