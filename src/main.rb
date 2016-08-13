
require_relative 'issues_retriever'
require_relative 'language_color_chooser'
require_relative 'issues_displayer'

def main
  repo_issues = IssuesRetriever.new.retrieve
  lang_colors = LanguageColorChooser.choose(repo_issues)
  IssuesDisplayer.new.display(repo_issues, lang_colors)
end

main
