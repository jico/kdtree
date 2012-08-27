require 'kdtree'
require 'kdtree/heap'

describe KDTree do
  before do
    @empty_2D_tree = KDTree.new([], 2)

    @node_2D_1 = KDNode.new [1,1]
    @node_2D_2 = KDNode.new [0,2]
    @node_2D_3 = KDNode.new [3,-1]

    @one_node_2D_tree = KDTree.new([@node_2D_1], 2)
    @two_node_2D_tree = KDTree.new([@node_2D_1, @node_2D_2], 2)

    @dp1_2D = KDNode.new [1,1]
    @dp2_2D = KDNode.new [2,2]
    @dp3_2D = KDNode.new [3,3]
    @dp4_2D = KDNode.new [-1,-1]
    @dp5_2D = KDNode.new [-2,-2]
    @depth0_2D_tree = KDTree.new([], 2) # balanced
    @depth1_2D_tree = KDTree.new([@dp1_2D], 2) # balanced
    @depth2_2D_tree_a = KDTree.new([@dp1_2D, @dp2_2D], 2) # balanced
    @depth2_2D_tree_b = KDTree.new([@dp1_2D, @dp2_2D, @dp3_2D], 2) # balanced

    @depth3_2D_tree_a = KDTree.new([@dp1_2D, @dp2_2D], 2) # unbalanced
    @depth3_2D_tree_a.insert_point @dp4_2D # unbalanced

    @depth3_2D_tree_b = KDTree.new([@dp1_2D], 2) # unbalanced
    @depth3_2D_tree_b.insert_point @dp4_2D # falls to left
    @depth3_2D_tree_b.insert_point KDNode.new([0,0]) # falls to right of @dp4_2D

    @depth3_2D_tree_c = KDTree.new(((1..6).to_a.map { |n| KDNode.new [n,n] }), 2)
  end

  describe 'for tree node removal' do
    it 'removes from a 2D 1-node tree' do
      @one_node_2D_tree.remove!
      @one_node_2D_tree.value.should be_nil
      @one_node_2D_tree.left.should be_nil
      @one_node_2D_tree.right.should be_nil
    end

    it 'removes from a 2D 2-node tree' do
      @two_node_2D_tree.remove!
      @two_node_2D_tree.value.should_not be_nil
      @two_node_2D_tree.left.should be_nil
      @two_node_2D_tree.right.should be_nil
    end

    it 'removes from a 2D 3-node tree' do
      @three_node_2D_tree = KDTree.new([@node_2D_1, @node_2D_2, @node_2D_3], 2)
      @three_node_2D_tree.remove!
      @three_node_2D_tree.value.should eql(@node_2D_3)
      @three_node_2D_tree.left.value.should eql(@node_2D_2)
      @three_node_2D_tree.right.should be_nil
    end

    it 'removes an interior node from a 2D depth 3 tree' do
      # Create an unbalanced tree that extends to the right
      # Then remove an interior node
      @top_node = KDNode.new [0,0]
      @interior_node = KDNode.new [1,0]
      @leaf_node = KDNode.new [1,1]
      @tree = KDTree.new([@top_node], 2)
      @tree.insert_point(@interior_node)
      @tree.insert_point(@leaf_node)

      # Verify tree structure
      @tree.value.should eql(@top_node)
      @tree.right.value.should eql(@interior_node)
      @tree.right.right.value.should eql(@leaf_node)

      # Remove the interior node
      @tree.right.remove!

      # Verify new tree structure
      @tree.value.should eql(@top_node)
      @tree.right.value.should eql(@leaf_node)
      @tree.right.left.should be_nil
      @tree.right.right.should be_nil
    end
  end

  describe 'balanced tree' do
    it 'determines if 2D tree are balanced' do
      @depth0_2D_tree.balanced?.should be_true
      @depth1_2D_tree.balanced?.should be_true
      @depth2_2D_tree_a.balanced?.should be_true
      @depth2_2D_tree_b.balanced?.should be_true
      @depth3_2D_tree_a.balanced?.should be_false
      @depth3_2D_tree_b.balanced?.should be_false
      @depth3_2D_tree_c.balanced?.should be_true
    end
  end

  describe 'for maximum depth' do
    it 'finds correct depths' do
      @depth0_2D_tree.max_depth.should == 0
      @depth1_2D_tree.max_depth.should == 1
      @depth2_2D_tree_a.max_depth.should == 2
      @depth2_2D_tree_b.max_depth.should == 2
      @depth3_2D_tree_a.max_depth.should == 3
      @depth3_2D_tree_b.max_depth.should == 3
      @depth3_2D_tree_c.max_depth.should == 3
    end
  end

  describe 'for tree rebuild' do
    it 'must rebuild as a balanced tree' do
      @depth0_2D_tree.rebuild
      @depth0_2D_tree.balanced?.should be_true

      @depth1_2D_tree.rebuild
      @depth1_2D_tree.balanced?.should be_true

      @depth3_2D_tree_a = @depth3_2D_tree_a.rebuild
      @depth3_2D_tree_a.balanced?.should be_true

      @depth3_2D_tree_b = @depth3_2D_tree_b.rebuild
      @depth3_2D_tree_b.balanced?.should be_true
    end
  end

  describe 'for insertion' do
    before do
      @insert_tree = KDTree.new([], 2)
    end

    it 'inserts into an empty tree to establish root' do
      @insert_tree.insert_point(@node_2D_1)
      @insert_tree.value.should eql(@node_2D_1)
      @insert_tree.right.should be_nil
      @insert_tree.left.should be_nil
    end

    it 'inserts into balanced 2D 1-node tree (insertion value same as root)' do
      @insert_tree.insert_point(@dp1_2D)
      @insert_tree.insert_point(@dp1_2D)
      @insert_tree.value.should eql(@dp1_2D)
      if @insert_tree.right # "side" of hyperplane it ends up on is arbitrary
        @insert_tree.right.value.should eql(@dp1_2D)
        @insert_tree.right.left.should be_nil
        @insert_tree.right.right.should be_nil
        @insert_tree.left.should be_nil
      else
        @insert_tree.left.value.should eql(@dp1_2D)
        @insert_tree.left.left.should be_nil
        @insert_tree.left.right.should be_nil
        @insert_tree.right.should be_nil
      end
    end

    it 'inserts into balanced 2D 1-node tree (insert right)' do
      @insert_tree.insert_point(@dp1_2D)
      @insert_tree.insert_point(@dp2_2D)
      @insert_tree.value.should eql(@dp1_2D)
      @insert_tree.right.value.should eql(@dp2_2D)
      @insert_tree.right.left.should be_nil
      @insert_tree.right.right.should be_nil
      @insert_tree.left.should be_nil
    end

    it 'inserts into balanced 2D 1-node tree (insert left)' do
      @insert_tree.insert_point(@dp2_2D)
      @insert_tree.insert_point(@dp1_2D)
      @insert_tree.value.should eql(@dp2_2D)
      @insert_tree.right.should be_nil
      @insert_tree.left.value.should eql(@dp1_2D)
      @insert_tree.left.left.should be_nil
      @insert_tree.left.right.should be_nil
    end
  end

  describe 'creation' do
    it 'creates an empty tree' do
      @empty_2D_tree.should_not be_nil
      @empty_2D_tree.left.should be_nil
      @empty_2D_tree.right.should be_nil
      @empty_2D_tree.value.should be_nil
    end

    it 'creates a tree with one point' do
      @one_node_2D_tree.should_not be_nil
      @one_node_2D_tree.left.should be_nil
      @one_node_2D_tree.right.should be_nil
      @one_node_2D_tree.value.should eql(@node_2D_1)
    end

    it 'creates a tree with two points' do
      @two_node_2D_tree.should_not be_nil
      @two_node_2D_tree.left.should_not be_nil
      @two_node_2D_tree.right.should be_nil
      @two_node_2D_tree.value.should eql(@node_2D_1)
    end

    it 'creates a tree with all the same points' do
      tree = KDTree.new([@node_2D_1, @node_2D_1, @node_2D_1, @node_2D_1, @node_2D_1], 2)
      tree.should_not be_nil
      tree.left.should_not be_nil
      tree.right.should_not be_nil
      tree.value.should eql(@node_2D_1)
      count = 0
      tree.each {|el| count += 1}
      count.should == 5
    end

    it 'splits first on axis 0' do
      a = KDNode.new([-1, 0])
      b = KDNode.new([0, 0])
      c = KDNode.new([1, 0])
      t1 = KDTree.new [a, b, c], 2
      t2 = KDTree.new [c, a, b], 2
      t3 = KDTree.new [b, a, c], 2
      [t1, t2, t3].each do |t|
        t.left.value.should eql(a)
        t.left.left.should be_nil
        t.left.right.should be_nil

        t.value.should eql(b)

        t.right.value.should eql(c)
        t.right.left.should be_nil
        t.right.right.should be_nil
      end
    end

    it 'splits second on axis 1' do
      a = KDNode.new([0, -2])
      b = KDNode.new([-1, 1])
      c = KDNode.new([ 1, 0])
      d = KDNode.new([-2, -1])
      e = KDNode.new([-3, 2])
      f = KDNode.new([ 2, -1])
      g = KDNode.new([ 3, 2])
      tree = KDTree.new [a, b, c, d, e, f, g], 2
      in_order_traversal = [d, b, e, a, f, c, g]
      tree.each { |el| el.should eql(in_order_traversal.shift) }
    end
  end

  describe 'finding and traversing fixed graphs' do
    before do
      @tree = KDTree.new(
        [@a = KDNode.new([ 0, -2], :a),
         @b = KDNode.new([-1,  1], :b),
         @c = KDNode.new([ 1,  0], :c),
         @d = KDNode.new([-2, -1], :d),
         @e = KDNode.new([-3,  2], :e),
         @f = KDNode.new([ 2, -1], :f),
         @g = KDNode.new([ 3,  2], :g)], 2)
    end

    it 'finds the nearest point in known graph' do
      target = KDNode.new([-2, 1], :target_point)
      v = @tree.nearest(target)
      v.value.should eql(@b)
    end

    it 'finds the nearest k points in known graph' do
      target = KDNode.new([-2, 1], :target_point)

      best = @tree.nearest_k(target, 3).map {|sr| sr.value }

      best.include?(@b).should eql(true)
      best.include?(@d).should eql(true)
      best.include?(@e).should eql(true)
    end

    it 'handles degenerate case of nearest_k' do
      # This test case sets up the situation where we will have a bestk of
      # 0, but we still need to search the other side of the splitting
      # plane, because we have not yet found k points.
      @tree = KDTree.new(
        [@a = KDNode.new( [ 0.0,  0.0], :a),
         @b = KDNode.new( [-1.0, -1.0], :b),
         @c = KDNode.new( [ 1.1,  1.1], :c)], 2)

      best = @tree.nearest_k(@a, 1).map {|sr| sr.value}
      best.include?(@a).should be_true

      best = @tree.nearest_k(@a, 2).map {|sr| sr.value}
      best.include?(@a).should be_true
      best.include?(@b).should be_true

      # The real danger for this test case, is that we don't find node c
      # (the worst), since it is a leaf on the other side of the splitting
      # plane, and we won't have a full bestk when we come time to decide
      # whether to search that side or not.
      best = @tree.nearest_k(@a, 100).map {|sr| sr.value}
      best.include?(@a).should be_true
      best.include?(@b).should be_true
      best.include?(@c).should be_true
    end
  end

  describe 'finding and iterating random graphs' do
    # Random data will be constrained by:
    NUM_DIMENSIONS = 2
    MAX_SCALAR  = 100
    MAX_DIST_SQ = MAX_SCALAR * MAX_SCALAR * NUM_DIMENSIONS

    before do
      @points = Array.new(1_000) do |i|
        KDNode.new([rand(MAX_SCALAR), rand(MAX_SCALAR)], "point #{i}")
      end
      @tree = KDTree.new @points, 2
      @target = KDNode.new([50.01 - rand(MAX_SCALAR), 49.87 - rand(MAX_SCALAR)], :target_point)
    end

    it 'traverses all nodes with each' do
      seen = Hash.new(0)
      @tree.each {|el| seen[el.data] += 1 }
      seen.size.should eql(@points.size)
    end

    it 'finds the nearest point (random float data)' do
      100.times do |i|
        expected = find_nearest_k(@target, @points, 1)[0]
        expected.value.should_not be_nil
        expected.distance.should_not be_nil
        actual = @tree.nearest(@target)
        actual.distance.should eql(expected.distance)
      end
    end

    it 'finds the same nodes with nearest and nearest_k' do
      500.times do |i|
        expected = find_nearest_k(@target, @points, 1)[0]
        expected.should_not be_nil

        actual   = @tree.nearest(@target)
        actual_k = @tree.nearest_k(@target, 1)[0]

        # With random data, we may have two nodes with the same
        # coordinates, or two points that are equidistant from the target.
        # Do not compare points, only the distances.
        expected.distance.should eql(actual.distance)
        expected.distance.should eql(actual_k.distance)
      end
    end

    it 'finds the nearest_k points (random float data)' do
      500.times do |i|
        k = 20
        expected = find_nearest_k(@target, @points, k)
        expected.should_not be_nil
        actual = @tree.nearest_k(@target, k)

        # With random data, we may have two nodes with the same
        # coordinates, or two points that are equidistant from the target.
        # Do not compare points, only the distances.
        actual.each do |a|
          exact_match   = expected.any?{ |e| a.value == e.value }
          same_distance = expected.any?{ |e| a.distance == e.distance }
          (exact_match || same_distance).should be_true
        end
      end
    end

    # Exhaustive search of points for nodes near target.  Returns an array
    # of at most k SearchResult objects.  Each SearchResult has a node and
    # the distance_squared of that node from the target.
    def find_nearest_k(target, points, k=1)
      points.inject(BestK.new(k)) do |b, current|
        b.add(SearchResult.new(current, current.distance_sq(target)))
      end.values
    end
  end
end
