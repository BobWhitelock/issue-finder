
require 'octokit'
require 'parallel'
require 'ruby-progressbar'

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

issues_for_repos = Parallel.map(stars, in_threads: 50) do |starred_repo|
  issues = Octokit.list_issues(
    starred_repo.full_name,
    {state: 'open', type: 'issue', since: (DateTime.now - 7).iso8601}
  )
  .select do |issue|
    !issue.pull_request && issue.comments == 0
  end

  progress_bar_mutex.synchronize {
    progress_bar.increment
  }

  [starred_repo.full_name, issues]
end
.to_h
.reject do |repo, issues|
  issues.empty?
end

puts
puts 'Found issues:'
puts

issues_for_repos.map do |repo, issues|
  puts repo
  puts '==============='
  issues.map do |issue|
    puts "#{issue.title} -- #{issue.html_url}"
  end
  puts
end
