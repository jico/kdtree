# KDTree based on the MagLev version:
# - https://github.com/MagLev/maglev/blob/master/examples/persistence/kdtree/lib/treekd.rb
# Ported from Adam Doppelt's C/Ruby 2D kd-tree:
# - http://gurge.com/blog/2009/10/22/ruby-nearest-neighbor-fast-kdtree-gem/
#
# This class is optimized for up to 3D cases (KDNode accessor methods for are
# used over direct indexing when possible to yield better perfomance.

require 'matrix'
require 'kdtree/heap'
require 'kdtree/version'

# KDTree is a KD-Tree of dimension K. Points in the tree exist in
# Euclidean space and distance calculations are performed as such.
class KDTree
  attr_reader :left, :right, :value, :dimension

  # Creates a new +KDTree+ for the given points that lie in Euclidean space.
  # Points should derive from class #KDNode (extend from it).
  # If +euclidean_points+ is nil or empty, will return an empty tree.
  # +#left+ and +#right+ may return nil, if there is no data on that side
  # of the tree.
  def initialize(euclidean_points, dimension, depth=0)
    @dimension = dimension
    @axis = depth % @dimension # Cycle through axis as we descend down the tree
    return if euclidean_points.nil? or euclidean_points.empty?

    # Sort and split tree by median point
    # NOTE: There is a big performance boost if use the x and y
    # accessors, rather than the [@axis] approach of:
    #    sorted = points.sort {|a,b| a[@axis] <=> b[@axis] }
    sorted = case @axis
      when 0 then euclidean_points.sort { |a,b| a.x <=> b.x }
      when 1 then euclidean_points.sort { |a,b| a.y <=> b.y }
      when 2 then euclidean_points.sort { |a,b| a.z <=> b.z }
      else euclidean_points.sort { |a,b| a[@axis] <=> b[@axis] }
    end

    pivot = sorted.size / 2
    left_points = sorted[0...pivot]
    right_points = sorted[pivot+1..-1]
    @left = KDTree.new(left_points, @dimension, depth+1) unless left_points.nil? or left_points.empty?
    @right = KDTree.new(right_points, @dimension, depth+1) unless right_points.nil? or right_points.empty?
    @value = sorted[pivot]
  end

  # Returns maximum node depth of tree.
  # An empty tree has a depth of 0.  A tree with just one point has a depth of 1,
  # a balanced tree with three points has a depth of 2, and so on.
  # This is expensive; it explores the entire tree.
  def max_depth
    if @value.nil? then
      0 # Empty tree
    elsif leaf? then
      1 # Non-nil @value and is leaf
    else 
      # We already know this is not a leaf node; find the max depth
      # of children.
      left_depth = @left.nil? ? 0 : @left.max_depth
      right_depth = @right.nil? ? 0 : @right.max_depth
      if left_depth > right_depth
        left_depth + 1
      else
        right_depth + 1
      end
    end
  end

  # Determines if this tree is balanced or not. 
  # Expensive; explores the entire tree. 
  def balanced?
    if @value.nil? or leaf? then
      true # An empty tree/leaf node is already balanced
    else
      left_depth = @left.nil? ? 0 : @left.max_depth
      right_depth = @right.nil? ? 0 : @right.max_depth
      # The left/right max depths cannot differ by more than one if this tree is balanced
      (left_depth - right_depth).abs <= 1
    end
  end

  # Rebuilds the entire tree, balancing it in the process.
  # Returns the new KDTree.
  def rebuild
    points = []
    each { |pt| points << pt }
    KDTree.new(points, @dimension)      
  end

  # Behaves as #rebuild indicates, but allows the exclusion of points
  # in the rebuilt tree using the +exclude+ array.  Also allows
  # exclusion of just the root node through +exclude_root+.
  def _rebuild(exclude, exclude_root=false)
    exclude = [] if exclude.nil?
    points = []
    points << @value unless exclude_root or exclude.include?(@value)
    @left.each { |pt| points << pt unless exclude.include?(pt) } unless @left.nil?
    @right.each { |pt| points << pt unless exclude.include?(pt) } unless @right.nil?
    KDTree.new(points, @dimension)
  end
  protected :_rebuild

  # Removes just the root node of this tree (that is, the "current value").  
  # After calling this method, the root value will change to one of the 
  # descendant nodes.
  # This is expensive; it will rebuild the entire tree rooted at this node.
  def remove!
    # Rebuild this tree without the root node.  
    tree = _rebuild(nil, true)

    # Replace ourself with the new tree
    @value = tree.value
    @left = tree.left
    @right = tree.right
  end

  # Inserts +point+ (a KDNode) into the tree.
  # Be aware that as you insert points, the tree may become increasingly
  # imbalanced.
  def insert_point(point)
    if @value.nil? then
      # Empty tree
      @value = point
      return
    end

    # Decide which side of the hyperplane this point goes on 
    # (for points lying on the hyperplane, the side is arbitrary).
    # After that, try to put the point there, or if it's already
    # occupied by another tree, try to put it into that tree.
    # TODO: You could use the first-three-dimensions compare here to 
    # potentially speed things up
    if point[@axis] >= @value[@axis] then
      if @right.nil? then
        @right = KDTree.new([point], @dimension, @axis + 1)
      else
        @right.insert_point(point)
      end
    else
      if @left.nil? then
        @left = KDTree.new([point], @dimension, @axis + 1)
      else
        @left.insert_point(point)
      end
    end
  end

  # Prints the tree out horizontally as if the tree were rotated
  # 90 degrees counter-clockwise (left of tree is at bottom, top of tree
  # is where text begins).
  def print_tree(offset=0)
    @right.print_tree(offset + 2) unless @right.nil?
    puts((" " * offset) + @value.to_s)
    @left.print_tree(offset + 2) unless @left.nil?
  end

  # Does an in-order (sorted) traversal of the tree, but yields only the
  # values
  def each(&block)
    @left.each(&block) unless @left.nil?
    block.call(@value) if @value and block_given?
    @right.each(&block) unless @right.nil?
  end

  # Does an pre-order traversal of the tree, yields the whole node
  def pre_order(&block)
    block.call(self) if block_given?
    @left.pre_order(&block) unless @left.nil?
    @right.pre_order(&block) unless @right.nil?
  end

  # Does an post-order traversal of the tree, yields the whole node
  def post_order(&block)
    @left.post_order(&block) unless @left.nil?
    @right.post_order(&block) unless @right.nil?
    block.call(self) if block_given?
  end

  # Does an in-order traversal of the tree, yields the whole node
  def in_order(&block)
    @left.in_order(&block) unless @left.nil?
    block.call(self) if block_given?
    @right.in_order(&block) unless @right.nil?
  end

  def leaf?
    @left.nil? and @right.nil?
  end

  # Finds the nearest point in receiver to target_point, or nil, if there
  # are no points in receiver.
  def nearest(target_point)
    nearest_k(target_point, 1)[0]
  end

  # Find the nearest +k+ points in receiver to +target_point+.  Returns an
  # array of at most k SearchResults. If this tree contains several
  # points at the same distance, at most k of them will be returned. 
  def nearest_k(target_point, k=1)
    bestk = BestK.new(k)
    _nearest_k(target_point, bestk)
    bestk.values
  end

  # Does not return a value, only modifies +bestk+
  def _nearest_k(target_point, bestk)
    my_result = SearchResult.new(@value, target_point.distance_sq(@value))
    if self.leaf?
      bestk.add(my_result)
      return
    end

    cmp = if @axis == 0
      target_point.x <=> @value.x
    elsif @axis == 1
      target_point.y <=> @value.y
    elsif @axis == 2
      target_point.z <=> @value.z
    else
      target_point[@axis] <=> @value[@axis]
    end

    case cmp
    when -1
      unsearched = @right
      @left._nearest_k(target_point, bestk) unless @left.nil?
    when 1
      unsearched = @left
      @right._nearest_k(target_point, bestk) unless @right.nil?
    when 0
      if @left
        unsearched = @right
        @left._nearest_k(target_point, bestk)
      else
        unsearched = @left
        @right._nearest_k(target_point, bestk)
      end
    end

    # We do not need to search the other child if
    # A: we don't have another child OR
    # B: we (a) already have enough candidates (bestk is full) and (b) we
    #    are too far from the axis.
    unless unsearched.nil? || (bestk.full? && axis_too_far_from(target_point, bestk))
      unsearched._nearest_k(target_point, bestk)
    end

    # Add ourself only after we check whether to search the unsearched
    # tree.  The reason is that:
    #    our_distance_to_target >= target_distance_to_axis
    # so, if we add ourself before we call axis_too_far_from,
    # then we will be in bestk, so bestk distance can't be smaller than
    # our distance, hence we will always search the other side (correct
    # results, but inefficient).
    bestk.add(my_result)
  end
  protected :_nearest_k

  # Do we need to search the other side of our axis?  Or is the target
  # node too far from the axis that we know there can't be anything
  # closer?  We need to check the other side if the best distance so far
  # is larger than the distance from target node to my splitting axis
  # (i.e., does a hypersphere of radius bestk cross the splitting axis or
  # not).
  def axis_too_far_from(target, bestk)
    target_to_axis_d = case @axis
      when 0 then @value.x - target.x
      when 1 then @value.y - target.y
      when 2 then @value.z - target.z
      else @value[@axis] - target[@axis]
    end

    target_to_axis_d_sq = target_to_axis_d * target_to_axis_d
    bestk.worst.distance < target_to_axis_d_sq
  end

  def eql?(other)
    @value.eql?(other.value) && @left.eql?(other.left) && @right.eql?(other.y)
  end

  def inspect
    "#{@dimension}DTree (inspect): value #{value.inspect} LEFT #{@left.to_s} RIGHT: #{@right.to_s}"
  end

  def to_s
    "#{@dimension}DTree (to_s): value #{value.inspect} LEFT #{@left.__id__} RIGHT: #{@right.__id__}"
  end
end

# A small class to hold a value and its distance from some other point.
# It implements > so that it can be used by the standard comparator in
# nearest.
class SearchResult
  include Comparable
  attr_reader :value, :distance
  def initialize(value, dist)
    @value = value
    @distance = dist
  end

  def <=>(other)
    other.distance <=> @distance
  end
end

# A KDNode contains K coordinates and may have some data
# associated with it.  It's assumed that the point lies
# in Euclidean space.
# This class is optimized for 1D, 2D, and 3D cases; it
# stores the first three coordinates in x, y, z fields.
class KDNode
  attr_reader :point, :data, :x, :y, :z

  # Initializes this point with a +point+ (vector or array) of coordinates
  # If the point is of type Array, it will convert it to a Vector.
  def initialize(point, options={})
    if point.kind_of? Array
      @point = Vector.elements(point)
    elsif point.kind_of? Vector
      @point = point
    else
      raise ArgumentError, "Invalid point #{point}. Must be Vector or Array."
    end
    @data = options.delete :data
    options.each do |k,v|
      instance_variable_set("@#{k.to_s}".to_sym, v)
    end
    @x, @y, @z = point[0], point[1], point[2]
  end

  def to_s
    "Point[#{@point.to_a.join(', ')}] #{self.instance_variables}"
  end

  # Returns the coordinate along the given axis (starting at 0).
  # For 1D, 2D, and 3D points, it is better to use the x/y/z accessors.
  def [](index)
    if index < 0 || index >= @point.size
      raise ArgumentError, "#{index} is out of range. Should be between 0 and #{@point.size-1}"
    end
    case index
    when 0 then @point.x
    when 1 then @point.y
    when 2 then @point.z
    else @point[index]
    end
  end

  def ==(other)
    eql?(other)
  end

  def eql?(other)
    @point.eql?(other.point) && @data.eql?(other.data)
  end

  def hash
    @point.hash ^ @data.hash
  end

  def distance(other)
    (other.point - @point).magnitude
  end

  def distance_sq(other)
    distance(other)**2
  end
end
