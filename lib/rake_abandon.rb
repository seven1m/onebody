class Rake::Task
  def abandon
    prerequisites.clear
    @actions.clear
  end
end
