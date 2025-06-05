# config/initializers/pagy.rb
require 'pagy/extras/items'

Pagy::DEFAULT[:items] = 10
Pagy::DEFAULT[:max_items] = 100
Pagy::DEFAULT[:overflow] = :empty_page
