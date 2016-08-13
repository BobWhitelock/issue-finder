
require 'octokit'
require 'parallel'
require 'ruby-progressbar'

class IssuesRetriever
  GITHUB_USER = ENV['GITHUB_USER']
  GITHUB_PASSWORD = ENV['GITHUB_PASSWORD']

  def initialize
    Octokit.auto_paginate = true
    Octokit.configure do |c|
      c.login = GITHUB_USER
      c.password = GITHUB_PASSWORD
    end
  end

  def retrieve
    puts 'Getting stars...'
    retrieve_stars
    puts

    puts 'Getting issues for stars...'
    Parallel.map(stars, in_threads: 50) do |starred_repo|
      issues = Octokit.list_issues(
        starred_repo.full_name,
        {state: 'open', type: 'issue', since: (DateTime.now - 7).iso8601}
      )
      .select do |issue|
        !issue.pull_request && issue.comments == 0
      end

      languages = Octokit.languages(starred_repo.full_name)
      main_language = languages.first && languages.first[0] || :Text

      increment_progress_bar

      {
        repo: starred_repo.full_name,
        language: main_language,
        issues: issues
      }
    end
    .reject do |issue_results|
      issue_results[:issues].empty?
    end
  end

  private

  def retrieve_stars
    @stars = Octokit.starred(GITHUB_USER)
  end

  def stars
    @stars
  end

  def progress_bar
    @progress_bar ||= ProgressBar.create(
      title: 'Stars retrieved',
      total: stars.length
    )
  end

  def progress_bar_mutex
    @progress_bar_mutex ||= Mutex.new
  end

  def increment_progress_bar
    progress_bar_mutex.synchronize {
      progress_bar.increment
    }
  end
end
