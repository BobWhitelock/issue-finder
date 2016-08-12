
require 'octokit'
require 'parallel'
require 'ruby-progressbar'
require 'colorize'

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

progress_bar = ProgressBar.create(
  title: 'Getting repo issues',
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

repo_issues.map do |issue_results|
  lang = issue_results[:language]
  color = lang_color[lang] || :default
  puts "#{issue_results[:repo]} -- #{lang}".colorize(color)
  puts '==============='.colorize(color)
  issue_results[:issues].map do |issue|
    puts "#{issue.title} -- #{issue.html_url}".colorize(color)
  end
  puts
end
