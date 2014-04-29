# http://stackoverflow.com/questions/9807827/preventing-warning-toplevel-constant-b-referenced-by-ab-with-namespaced-cla

# require_dependency File.join(Ponzu::Engine.root, "app", "models", "like.rb")
require_dependency File.join(Ponzu::Engine.root, "app", "models", "like", "like.rb")
