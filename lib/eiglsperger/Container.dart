part of graphview;

/// Extension of the {@link InsertionOrderSplayTree} to hold Nodes of {@link Segment<V>}
///
/// @param <Node> the node type
class ContainerNode extends SplayTree<Node> {

  double measure = -1;
  int pos = -1;
  int index = 0;

  ContainerNode(CompareFunc compareFunc) : super(compareFunc);

  // static <Node> Pair<Container<V>> split(Container<Node> tree, Segment<Node> key) {
  // Container<Node> right = tree.split(key);
  // return Pair.of(tree, right);
  // }
  // static <Node> Container<Node> createSubContainer(Node<Segment<V>> root) {
  //   Container<Node> tree = new Container<>(root);
  //   tree.validate();
  //   return tree;
  // }

  // Container() {}
  //
  // Container(Node<Segment<V>> root) {
  //   this.root = root;
  // }
  //
  // Container<Node> split(Segment<Node> key) {
  //   // split off the right side of key
  //   Node<Segment<V>> node = find(key);
  //   if (node != null) {
  //     splay(node); // so node will be root
  //     node.size -= size(node.right);
  //     // root should be the found node
  //     if (node.right != null) node.right.parent = null;
  //
  //     if (node.left != null) {
  //       node.left.parent = null;
  //     }
  //     root = node.left;
  //
  //     Container<Node> splitter = Container.createSubContainer(node.right);
  //
  //     // found should not be in either tree
  //     splitter.validate();
  //     validate();
  //     return splitter;
  //   } else {
  //     return this;
  //   }
  // }
  //
  // void split(Container<Node> tree, int position) {
  //   Container<Node> right = tree.split(position);
  //
  //   return Pair.of(tree, right);
  // }
  //
  // Container<Node> split(int position) {
  //   Node<Segment<V>> found = find(position);
  //   if (found != null) {
  //     splay(found);
  //     // split off the right side of key
  //     if (found.right != null) {
  //       found.right.parent = null;
  //       found.size -= found.right.size;
  //     }
  //     Container<Node> splitter = Container.createSubContainer(found.right);
  //     found.right = null;
  //     splitter.validate();
  //     validate();
  //     // make sure that 'found' is still in this tree.
  //     if (find(found) == null) {
  //       throw new RuntimeException(
  //           "Node " + found + " at position " + position + " was not still in tree");
  //     }
  //     return splitter;
  //   }
  //   return Container.createSubContainer();
  // }

  void setRank(int rank) {}

  int getRank() {
    return 0;
  }

  void setIndex(int index) {
    this.index = index;
  }

  int getIndex() {
    return index;
  }

  Offset? getPoint() {
    return null;
  }

  void setPoint(Offset p) {}

  int getPos() {
    return pos;
  }

  void setPos(double pos) {
    this.pos = pos.toInt();
    if (measure == -1) {
      measure = pos;
    }
  }

  double getMeasure() {
    return measure;
  }

  void setMeasure(double measure) {
    this.measure = measure;
    this.pos = measure as int;
  }

  Node? getVertex() {
    return null;
  }

  // List<Segment<V>> segments() {
  //   return super.nodes().stream().map(n -> n.key).collect(Collectors.toList());
  // }

  @override
  String toString() {
    // StringBuilder buf = new StringBuilder("Container");
    // buf.append(" size:").append(this.size());
    // buf.append(" index:").append(this.getIndex());
    // buf.append(" pos:").append(this.getPos());
    // buf.append(" measure:").append(this.getMeasure());
    // buf.append(" {");
    // boolean first = true;
    // for (Iterator<Segment<V>> iterator = new Iterator<>(root); iterator.hasNext();) {
    //   Node<Segment<V>> node = iterator.next();
    //   if (!first) {
    //     buf.append(", ");
    //   }
    //   first = false;
    //   if (node != null) buf.append(node.key.toString());
    // }
    // buf.append('}');
    // return buf.toString();
    return "";
  }

}
