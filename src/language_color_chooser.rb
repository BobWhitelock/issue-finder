
class LanguageColorChooser
  COLORS = [:red, :yellow, :green, :blue, :magenta, :cyan]

  def self.choose(repo_issues)
    ordered_languages = repo_issues.
      group_by {|result| result[:language]}.
      sort_by {|language, results| results.length }.
      reverse.
      map {|grouped_language| grouped_language.first}

    languages_without_colors = [ordered_languages.length - COLORS.length, 0].max
    colors_to_use = COLORS + [:default] * languages_without_colors

    ordered_languages.
      zip(colors_to_use).
      to_h
  end
end
