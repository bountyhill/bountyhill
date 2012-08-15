require_relative 'test_helper'
require 'vcr'

::Event::Listeners.add :console
::Event.route :all => :console

class Neo4jTest < Test::Unit::TestCase
  include Bountybase::TestCase

  Neo4j = Bountybase::Graph::Neo4j

  def setup
    Neo4j.purge!
  end

  def neo4j(url=nil)
    @neo4j = nil if url
    @neo4j ||= Neography::Rest.new(url || Bountybase.config.neo4j)
  end
  
  def test_ping
    assert_nothing_raised() { neo4j.ping }
  end

  def test_ping_fails
    VCR.use_cassette('test_neo4j_ping_fails', :record => :once, :allow_playback_repeats => true) do
      assert_raise(SocketError) do 
        neo4j("http://i.dont.exist.test").ping
      end
    end

    assert_raise(Errno::ECONNREFUSED) do
      neo4j("http://localhost:64642").ping
    end
  end

  def test_create_node_wo_attributes
    freeze_time(123456)
    
    node = Neo4j::Node.create "foo", 1
    assert! node => Neo4j::Node,
      node.url => /http:\/\/.*\/data\/node/,
      node.type => "foo"

    assert_equal node.attributes, "type"=>"foo", "uid"=>1, "created_at"=>123456

    assert_equal(1, Neo4j.count)

    # can create a different node
    Neo4j::Node.create "foo", 2
    assert_equal(2, Neo4j.count)

    # creating an already existing identical node is ignored.
    Neo4j::Node.create "foo", 1
    assert_equal(2, Neo4j.count)
  end

  def test_node_attributes
    freeze_time(123457)
    
    node = Neo4j::Node.create "foo", 1, :bar => "baz"
    assert_equal node.uid, 1
    assert_equal node.created_at, 123457
    assert_equal node.updated_at, nil
  end
  
  def test_create_node_w_attributes
    assert_equal(0, Neo4j.count)

    freeze_time(123457)
    
    node = Neo4j::Node.create "foo", 1, :bar => "baz"
    assert! node => Neo4j::Node,
      node.url => /http:\/\/.*\/data\/node/,
      node.type => "foo"

    assert_equal node.attributes, "type"=>"foo", "uid"=>1, "created_at"=>123457, "bar" => "baz"

    assert_equal(1, Neo4j.count)

    # can create a different node
    Neo4j::Node.create "foo", 2, :bar => "baz"
    assert_equal(2, Neo4j.count)

    # creating an already existing identical node is ignored.
    node2 = Neo4j::Node.create "foo", 1, :bar => "baz"
    assert_equal(2, Neo4j.count)
    assert_equal node2.attributes, "type"=>"foo", "uid"=>1, "created_at"=>123457, "bar" => "baz"

    # creating a node with identical key and different attributes fails.
    assert_raise(Neo4j::DuplicateKeyError) {  
      Neo4j::Node.create "foo", 1, :bar => "bazie"
    }
    assert_equal(2, Neo4j.count)

    # creating an already existing semi-identical node is ignored, if the only differences
    # are "created_at" and/or "updated_at" keys.

    freeze_time(123458)

    node2 = Neo4j::Node.create "foo", 1, :bar => "baz"
    assert_equal(2, Neo4j.count)
    assert_equal node2.attributes, "type"=>"foo", "uid"=>1, "created_at"=>123457, "bar" => "baz"
  end

  def test_node_crud
    assert_equal(0, Neo4j.count)

    # --- create node -------------------------------------------------
    
    freeze_time(123457)
    
    node = Neo4j::Node.create "foo", 1, :bar => "baz"
    assert_equal(node.created_at, 123457)
    assert_equal(node.updated_at, nil)

    # --- update node -------------------------------------------------

    freeze_time(123458)

    node.update :bar => "bazie"
    assert_equal node.attributes, "bar"=>"bazie",
                                  "type"=>"foo",
                                  "uid"=>1,
                                  "created_at"=>123457,
                                  "updated_at"=>123458
    assert_equal(node.created_at, 123457)
    assert_equal(node.updated_at, 123458)

    # --- find node ---------------------------------------------------

    freeze_time(123459)
    
    node2 = Neo4j::Node.find "foo", 1
    assert_equal(node2.attributes, "uid"=>1,
                                   "updated_at"=>123458,
                                   "created_at"=>123457,
                                   "type"=>"foo",
                                   "bar"=>"bazie")

    assert_equal(node.created_at, 123457)
    assert_equal(node.updated_at, 123458)
    
    # --- delete node -------------------------------------------------

    freeze_time(123460)

    assert_equal(1, Neo4j.count)
    
    node.destroy
    assert_equal(0, Neo4j.count)

    node2.destroy
    assert_equal(0, Neo4j.count)
  end

  def test_node_destroy_class_methods
    Neo4j::Node.create "foo", 1, :bar => "baz"
    assert_equal(1, Neo4j.count)

    Neo4j::Node.destroy "foo", 2
    assert_equal(1, Neo4j.count)

    Neo4j::Node.destroy "foo", 1
    assert_equal(0, Neo4j.count)

    Neo4j::Node.destroy "foo", 1
    assert_equal(0, Neo4j.count)
  end
  
  def test_node_cannot_find
    Neo4j::Node.create "foo", 1, :bar => "baz"
    assert_nil Neo4j::Node.find("foo", 2)
    
    assert_nil Neo4j::Node.find("foox", 1)
  end
end
