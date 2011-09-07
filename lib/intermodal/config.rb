module Intermodal
  @max_per_page = 100
  @default_per_page = 10

  #TODO: Refactor to create a config DSL for modules
  def self.max_per_page(value = nil)
    return @max_per_page unless value
    @max_per_page = value
  end

  def self.default_per_page(value = nil)
    return @default_per_page unless value
    @default_per_page = value
  end
end
