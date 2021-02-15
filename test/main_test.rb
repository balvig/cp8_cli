require "test_helper"

module Cp8Cli
  class MainTest < Minitest::Test
    def setup
      stub_shell
      stub_request(:get, /rubygems\.org/).to_return_json({})
      stub_request(:get, /pulls/).to_return_json([])
    end

    def test_start_adhoc_story
      pr_endpoint = stub_github(:post, "/repos/balvig/cp8_cli/pulls").
        with(body: { base: "main", head: "jb/fix-bug", title: "Fix bug", draft: true })

      stub_github_user("John Bobson")
      stub_repo("git@github.com:balvig/cp8_cli.git")

      expect_question("Branch name: jb/", default: "fix-bug", answer: "fix-bug")
      expect_checkout("jb/fix-bug")
      expect_commit("Fix bug")
      expect_push("jb/fix-bug")
      expect_title "Created draft PR, run `cp8 open` to view."

      cli.start("Fix bug")

      shell.verify
      assert_requested pr_endpoint
    end

    def test_start_with_blank_name
      expect_error("No name/url provided")

      cli.start(nil)
    end

    def test_start_github_issue
      create_pr_endpoint = stub_github(:post, "/repos/balvig/cp8_cli/pulls").with(
        body: {
          base: "main",
          head: "jb/issue-title",
          title: "ISSUE TITLE",
          body: "Closes balvig/cp8_cli#ISSUE_NUMBER\n\n_Release note: ISSUE TITLE_",
          draft: true
        }
      )

      issue_endpoint = stub_github(:get, "/repos/balvig/cp8_cli/issues/ISSUE_NUMBER").to_return_json(github_issue)
      user_endpoint = stub_github(:get, "/user").to_return_json(github_user)
      assign_endpoint = stub_github(:post, "/repos/balvig/cp8_cli/issues/ISSUE_NUMBER/assignees").
        with(body: { assignees: ["GITHUB_USER"] })
      stub_github_user("John Bobson")
      stub_repo("git@github.com:balvig/cp8_cli.git")

      expect_question("Branch name: jb/", default: "issue-title", answer: "issue-title")
      expect_checkout("jb/issue-title")
      expect_commit("ISSUE TITLE")
      expect_push("jb/issue-title")
      expect_title "Created draft PR, run `cp8 open` to view."

      cli.start("https://github.com/balvig/cp8_cli/issues/ISSUE_NUMBER")

      shell.verify

      assert_requested issue_endpoint
      assert_requested user_endpoint
      assert_requested assign_endpoint
      assert_requested create_pr_endpoint
    end

    def test_open_main
      stub_branch("main")
      stub_repo("git@github.com:balvig/cp8_cli.git")
      stub_repo("git@github.com:balvig/cp8_cli.git") # erm

      expect_pr(
        repo: "balvig/cp8_cli",
        from: "main",
        to: "main",
        expand: 1
      )

      cli.open

      shell.verify
    end

    def test_open_branch
      stub_branch("jb/adhoc-story")
      stub_repo("git@github.com:balvig/cp8_cli.git")
      stub_repo("git@github.com:balvig/cp8_cli.git") # erm

      expect_pr(
        repo: "balvig/cp8_cli",
        from: "jb/adhoc-story",
        to: "main",
        expand: 1
      )

      cli.open

      shell.verify
    end

    def test_submit_branch_with_pr
      find_pr_endpoint = stub_github(:get, "/repos/balvig/cp8_cli/pulls").
        with(query: { head: "balvig:jb/fix-bug" }).
        to_return_json([github_pr])
      stub_branch("jb/fix-bug")
      stub_repo("git@github.com:balvig/cp8_cli.git")

      expect_push("jb/fix-bug")

      expect_open_url("https://github.com/balvig/cp8_cli/pull/PR_NUMBER")

      cli.submit

      shell.verify

      assert_requested find_pr_endpoint
    end

    def test_submit_plain_branch
      stub_branch("fix-this")
      stub_repo("git@github.com:balvig/cp8_cli.git")
      stub_repo("git@github.com:balvig/cp8_cli.git") # erm

      expect_push("fix-this")
      expect_pr(
        repo: "balvig/cp8_cli",
        from: "fix-this",
        to: "main",
        expand: 1
      )

      cli.submit

      shell.verify
    end

    def test_ci
      stub_branch("jb.issue-title.main.balvig/cp8_cli#ISSUE_NUMBER")
      stub_repo("git@github.com:balvig/cp8_cli.git")

      expect_open_url("https://circleci.com/gh/balvig/cp8_cli/tree/jb.issue-title.main.balvig%2Fcp8_cli%23ISSUE_NUMBER")

      cli.ci

      shell.verify
    end

    def test_suggest
      stub_branch("jb.card-name.main.CARD_SHORT_LINK")
      stub_repo("git@github.com:balvig/cp8_cli.git")

      expect_checkout("suggestion-HEX")
      expect_push("suggestion-HEX")
      expect_pr(
        repo: "balvig/cp8_cli",
        from: "suggestion-HEX",
        to: "jb.card-name.main.CARD_SHORT_LINK"
      )
      expect_checkout("jb.card-name.main.CARD_SHORT_LINK")
      expect_reset("jb.card-name.main.CARD_SHORT_LINK")

      SecureRandom.stub :hex, "HEX" do
        cli.suggest
      end

      shell.verify
    end

    private

      def label
        { id: "LABEL_ID", name: "LABEL NAME" }
      end

      def github_pr
        { number: "PR_NUMBER", title: "PR TITLE", html_url: "https://github.com/balvig/cp8_cli/pull/PR_NUMBER" }
      end

      def github_issue
        { number: "ISSUE_NUMBER", title: "ISSUE TITLE", html_url: "https://github.com/balvig/cp8_cli/issues/ISSUE_NUMBER" }
      end

      def github_user
        { login: "GITHUB_USER" }
      end

      def cli
        @_cli ||= Main.new global_config
      end

      def global_config
        GlobalConfig.new(key: "PUBLIC_KEY", github_token: "GITHUB_TOKEN")
      end
  end
end
