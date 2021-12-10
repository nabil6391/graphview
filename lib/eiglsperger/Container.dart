// class Container extends InsertionOrderSplayTree {
//
//   double measure = -1;
//   int pos = -1;
//   int index;
//
//   // static <V> Pair<Container<V>> split(Container<V> tree, Segment<V> key) {
//   // Container<V> right = tree.split(key);
//   // return Pair.of(tree, right);
//   // }
//   // static <V> Container<V> createSubContainer(Node<Segment<V>> root) {
//   //   Container<V> tree = new Container<>(root);
//   //   tree.validate();
//   //   return tree;
//   // }
//
//   Container() {}
//
//   Container(Node<Segment<V>> root) {
//     this.root = root;
//   }
//
//
//   Container<V> split(Segment<V> key) {
//     // split off the right side of key
//     Node<Segment<V>> node = find(key);
//     if (node != null) {
//       splay(node); // so node will be root
//       node.size -= size(node.right);
//       // root should be the found node
//       if (node.right != null) node.right.parent = null;
//
//       if (node.left != null) {
//         node.left.parent = null;
//       }
//       root = node.left;
//
//       Container<V> splitter = Container.createSubContainer(node.right);
//
//       // found should not be in either tree
//       splitter.validate();
//       validate();
//       return splitter;
//     } else {
//       return this;
//     }
//   }
//
//   static
//
//   <
//
//   V> Pair<Container<V>> split(Container<V> tree, int position) {
//
//   Container<V> right = tree.split(position);
//
//   return Pair.of(tree, right);
//   }
//
//   Container<V> split(int position) {
//   Node<Segment<V>> found = find(position);
//   if (found != null) {
//   splay(found);
//   // split off the right side of key
//   if (found.right != null) {
//   found.right.parent = null;
//   found.size -= found.right.size;
//   }
//   Container<V> splitter = Container.createSubContainer(found.right);
//   found.right = null;
//   splitter.validate();
//   validate();
//   // make sure that 'found' is still in this tree.
//   if (find(found) == null) {
//   throw new RuntimeException(
//   "Node " + found + " at position " + position + " was not still in tree");
//   }
//   return splitter;
//   }
//   return Container.createSubContainer();
//   }
//
//   void setRank(int rank) {}
//
//   int getRank() {
//   return 0;
//   }
//
//   void setIndex(int index) {
//   this.index = index;
//   }
//
//   int getIndex() {
//   return index;
//   }
//
//   Point getPoint() {
//   return null;
//   }
//
//   void setPoint(Point p) {}
//
//   int getPos() {
//   return pos;
//   }
//
//   void setPos(int pos) {
//   this.pos = pos;
//   if (measure == -1) {
//   measure = pos;
//   }
//   }
//
//   double getMeasure() {
//   return measure;
//   }
//
//   void setMeasure(double measure) {
//   this.measure = measure;
//   this.pos = (int) measure;
//   }
//
//   V getVertex() {
//   return null;
//   }
//
//   List<Segment<V>> segments() {
//   return super.nodes().stream().map(n -> n.key).collect(Collectors.toList());
//   }
//
//   String toString() {
//   StringBuilder buf = new StringBuilder("Container");
//   buf.append(" size:").append(this.size());
//   buf.append(" index:").append(this.getIndex());
//   buf.append(" pos:").append(this.getPos());
//   buf.append(" measure:").append(this.getMeasure());
//   buf.append(" {");
//   boolean first = true;
//   for (Iterator<Segment<V>> iterator = new Iterator<>(root); iterator.hasNext(); ) {
//   Node<Segment<V>> node = iterator.next();
//   if (!first) {
//   buf.append(", ");
//   }
//   first = false;
//   if (node != null) buf.append(node.key.toString());
//   }
//   buf.append('}');
//   return buf.toString();
//   }
// }
