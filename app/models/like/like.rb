# http://stackoverflow.com/questions/9807827/preventing-warning-toplevel-constant-b-referenced-by-ab-with-namespaced-cla
class Like::Like < Like
  def schedulize
    update_attribute('type', 'Like::Schedule')
  end

  def unschedulize
    update_attribute('type', 'Like::Like')
  end
end