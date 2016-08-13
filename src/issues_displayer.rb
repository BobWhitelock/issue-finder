
require 'colorize'
require 'terminal-table'
require 'highline'
require 'word_wrap'
require 'word_wrap/core_ext'

class IssuesDisplayer

  def initialize
    Terminal::Table::Style.defaults = {width: terminal_width}
  end

  def display(repo_issues, lang_colors)
    @lang_colors = lang_colors

    puts
    puts 'Found issues:'
    puts

    repo_issues.map do |issue_results|
      display_repos_issues(issue_results)
    end
  end

  private

  def display_repos_issues(issue_results)
    lang = issue_results[:language]
    color = @lang_colors[lang]

    title = "#{issue_results[:repo]} -- #{lang.to_s.colorize(color)}"
    issues_table = Terminal::Table.new(title: title) do |table|
      issue_results[:issues].map do |issue|
        table << [issue.created_at, issue.title.fit(30), issue.html_url]
        table.add_separator unless issue == issue_results[:issues].last
      end
    end

    puts issues_table
    puts
  end

  def terminal_width
    HighLine::SystemExtensions.terminal_size[0]
  end
end
