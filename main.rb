
require 'octokit'
require 'parallel'
require 'ruby-progressbar'
require 'colorize'
require 'terminal-table'
require 'highline'
require 'word_wrap'
require 'word_wrap/core_ext'

github_user = ENV['GITHUB_USER']
github_password = ENV['GITHUB_PASSWORD']

Octokit.auto_paginate = true
Octokit.configure do |c|
  c.login = github_user
  c.password = github_password
end

puts 'Getting stars...'
stars = Octokit.starred(github_user)
puts

puts 'Getting issues for stars...'

progress_bar = ProgressBar.create(
  title: 'Stars retrieved',
  total: stars.length
)
progress_bar_mutex = Mutex.new

repo_issues = Parallel.map(stars, in_threads: 50) do |starred_repo|
  issues = Octokit.list_issues(
    starred_repo.full_name,
    {state: 'open', type: 'issue', since: (DateTime.now - 7).iso8601}
  )
  .select do |issue|
    !issue.pull_request && issue.comments == 0
  end

  languages = Octokit.languages(starred_repo.full_name)
  main_language = languages.first && languages.first[0] || :Text

  progress_bar_mutex.synchronize {
    progress_bar.increment
  }

  {
    repo: starred_repo.full_name,
    language: main_language,
    issues: issues
  }
end
.reject do |issue_results|
  issue_results[:issues].empty?
end

colors = [:red, :yellow, :green, :blue, :magenta, :cyan]

ordered_languages = repo_issues.
  group_by {|result| result[:language]}.
  sort_by {|language, results| results.length }.
  reverse.
  map {|grouped_language| grouped_language.first}

lang_color = ordered_languages.zip(colors).to_h

puts
puts 'Found issues:'
puts

terminal_width = HighLine::SystemExtensions.terminal_size[0]
Terminal::Table::Style.defaults = {width: terminal_width}

repo_issues.map do |issue_results|
  lang = issue_results[:language]
  color = lang_color[lang] || :default

  title = "#{issue_results[:repo]} -- #{lang.to_s.colorize(color)}"
  issues_table = Terminal::Table.new(title: title) do |table|
    issue_results[:issues].map do |issue|
      table << [issue.created_at, issue.title.fit(30), issue.html_url]
      table.add_separator
    end
  end

  puts issues_table
  puts
end
