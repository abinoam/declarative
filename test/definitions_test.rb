require "test_helper"
require "declarative/schema"

# module Definitions
#   module Inspect
#     def inspect
#       each { |n, dfn|
#         dfn.extend(::Inspect)
#         dfn[:nested].extend(::Inspect) if dfn[:nested]
#         dfn[:nested].extend(::Definitions::Inspect) if dfn[:nested]
#       }
#       super
#     end

#     def get(*)
#       super.extend(::Inspect)
#     end
#   end
# end

class DefinitionsTest < Minitest::Spec
  NestedBuilder = ->(options) {
    base = options[:base] || Declarative::Definitions.new(Declarative::Definitions::Definition)
    base.instance_eval do # this doesn't copy and writes to the original!
      def module_eval(&block) # FIXME: that's because build_nested calls #module_eval.
        instance_exec(&block)
      end
      self
    end
  }

  let (:schema) { Declarative::Definitions.new(Declarative::Definitions::Definition).extend(Definitions::Inspect) }

  it "what" do
    # #add works with name
    schema.add :id
    # get works with symbol
    schema.get(:id).inspect.must_equal '#<Declarative::Definitions::Definition: @options={}, @name="id">'
    # get works with string
    schema.get("id").inspect.must_equal '#<Declarative::Definitions::Definition: @options={}, @name="id">'

    # #add with name and options
    schema.add(:id, unique: true)
    schema.get(:id).inspect.must_equal '#<Declarative::Definitions::Definition: @options={:unique=>true}, @name="id">'

    pp schema
  end

  it "overwrites old when called twice" do
    schema.add :id
    schema.add :id, cool: true
    schema.inspect.must_equal '{"id"=>#<Declarative::Definitions::Definition: @options={:cool=>true}, @name="id">}'
  end

  class Decorator
    def self.add(*args, &block)
      Declarative::Definitions.new(Declarative::Definitions::Definition)
    end
  end

  it "#add with block" do
    schema.add :artist, build_nested: NestedBuilder do
      add :name
      add :band, build_nested: NestedBuilder do
        add :location
      end
    end

    schema.inspect.must_equal '{"artist"=>#<Declarative::Definitions::Definition: @options={:nested=>{"name"=>#<Declarative::Definitions::Definition: @options={}, @name="name">, "band"=>#<Declarative::Definitions::Definition: @options={:nested=>{"location"=>#<Declarative::Definitions::Definition: @options={}, @name="location">}}, @name="band">}}, @name="artist">}'

    pp schema
  end


  it "#add with inherit: true and block" do
    schema.add :artist, cool: true, build_nested: NestedBuilder do
      add :name
      add :band, crazy: nil, build_nested: NestedBuilder do
        add :location
      end
    end

    schema.add :id, unique: true, value: 1

    schema.add :artist, uncool: false, build_nested: NestedBuilder, inherit: true do
      add :band, normal: false, build_nested: NestedBuilder, inherit: true do
        add :genre
      end
    end

    schema.add :id, unique: false, inherit: true

    pp schema


    schema.inspect.must_equal '{"artist"=>#<Declarative::Definitions::Definition: @options={:cool=>true, :nested=>{"name"=>#<Declarative::Definitions::Definition: @options={}, @name="name">, "band"=>#<Declarative::Definitions::Definition: @options={:crazy=>nil, :nested=>{"location"=>#<Declarative::Definitions::Definition: @options={}, @name="location">, "genre"=>#<Declarative::Definitions::Definition: @options={}, @name="genre">}, :normal=>false}, @name="band">}, :uncool=>false}, @name="artist">, "id"=>#<Declarative::Definitions::Definition: @options={:unique=>false, :value=>1}, @name="id">}'

  end
end