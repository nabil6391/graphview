part of graphview;

/**
 * A splay tree for items that are not Comparable. There is no 'insert' method, any new item is
 * appended to the right side of the SplayTree by first finding the 'max' (farthest right), splaying
 * to it, and adding the new Node as its right child
 *
 * @param  key type that is stored in the tree
 */
// class InsertionOrderSplayTreeWithSize {
//
//   static int nodeSize(Node node) {
//     return node == null ? 0 : node.size;
//   }
//
//   static class Node {
//     T key;
//     Node parent;
//     Node left;
//     Node right;
//     int size = 1;
//
//     Node(T key) {
//       this.key = key;
//     }
//
//     int size() {
//       return this.size;
//     }
//
//     int count() {
//       int leftCount = left != null ? left.count() : 0;
//       int rightCount = right != null ? right.count() : 0;
//       int count = 1 + leftCount + rightCount;
//       return count;
//     }
//
//     void validate() {
//       if (this == left) {
//         throw new RuntimeException("this == left");
//       }
//       if (left != null && left == right) {
//         throw new RuntimeException("children match");
//       }
//       if (this == this.parent) {
//         throw new RuntimeException("node is its own parent");
//       }
//     }
//   }
//
//   Node root;
//
//   static  InsertionOrderSplayTreeWithSize create() {
//     return new InsertionOrderSplayTreeWithSize<>();
//   }
//
//   static  InsertionOrderSplayTreeWithSize create(Node root) {
//     InsertionOrderSplayTreeWithSize tree = new InsertionOrderSplayTreeWithSize<>(root);
//     tree.validate();
//     return tree;
//   }
//
//   InsertionOrderSplayTreeWithSize() {}
//
//   InsertionOrderSplayTreeWithSize(Node root) {
//     this.root = root;
//   }
//
//   void leftRotate(Node x) {
//     Node y = x.right;
//     if (y != null) {
//       x.right = y.left;
//       if (y.left != null) y.left.parent = x;
//       y.parent = x.parent;
//     }
//
//     if (x.parent == null) root = y;
//     else if (x == x.parent.left) x.parent.left = y;
//     else x.parent.right = y;
//     if (y != null) y.left = x;
//
//     x.size = nodeSize(x.left) + nodeSize(x.right) + 1;
//
//     x.parent = y;
//   }
//
//   void rightRotate(Node x) {
//     Node y = x.left;
//     if (y != null) {
//       x.left = y.right;
//       if (y.right != null) y.right.parent = x;
//       y.parent = x.parent;
//     }
//     if (null == x.parent) root = y;
//     else if (x == x.parent.left) x.parent.left = y;
//     else x.parent.right = y;
//     if (y != null) y.right = x;
//
//     x.size = nodeSize(x.left) + nodeSize(x.right) + 1;
//
//     x.parent = y;
//   }
//
//   void splay(T element) {
//     Node node = find(element);
//     if (node != null) {
//       splay(node);
//     }
//   }
//
//   void splay(Node x) {
//     if (x == null) {
//       return;
//     }
//     int leftSize = 0;
//     int rightSize = 0;
//
//     while (x.parent != null) {
//       if (null == x.parent.parent) {
//         if (x.parent.left == x) rightRotate(x.parent);
//         else leftRotate(x.parent);
//       } else if (x.parent.left == x && x.parent.parent.left == x.parent) {
//         rightRotate(x.parent.parent);
//         rightRotate(x.parent);
//       } else if (x.parent.right == x && x.parent.parent.right == x.parent) {
//         leftRotate(x.parent.parent);
//         leftRotate(x.parent);
//       } else if (x.parent.left == x && x.parent.parent.right == x.parent) {
//         rightRotate(x.parent);
//         leftRotate(x.parent);
//       } else {
//         leftRotate(x.parent);
//         rightRotate(x.parent);
//       }
//     }
//
//     leftSize += nodeSize(root.left); /* Now l_size and r_size are the sizes of */
//     rightSize += nodeSize(root.right); /* the left and right trees we just built.*/
//     root.size = leftSize + rightSize + 1;
//     validate();
//   }
//
//   static  Node p(Node node) {
//     return node != null ? node.parent : node;
//   }
//
//   static  int size(Node node) {
//     return node != null ? node.size() : 0;
//   }
//
//   static  Node l(Node node) {
//     return node != null ? node.left : node;
//   }
//
//   static  Node r(Node node) {
//     return node != null ? node.right : node;
//   }
//
//   int pos(Node node) {
//     if (node == root) {
//       return size(l(node));
//     } else if (r(p(node)) == node) { // node is a right child
//       return pos(p(node)) + size(l(node)) + 1;
//     } else if (l(p(node)) == node) { // node is a left child
//       return pos(p(node)) - size(r(node)) - 1;
//     } else {
//       return -1;
//     }
//   }
//
//   void replace(Node u, Node v) {
//     if (null == u.parent) root = v;
//     else if (u == u.parent.left) u.parent.left = v;
//     else u.parent.right = v;
//     if (v != null) v.parent = u.parent;
//   }
//
//   Node subtree_minimum(Node u) {
//     while (u.left != null) u = u.left;
//     return u;
//   }
//
//   Node subtree_maximum(Node u) {
//     while (u.right != null) u = u.right;
//     return u;
//   }
//
//   Node max() {
//     if (root != null) {
//       return subtree_maximum(root);
//     } else {
//       return null;
//     }
//   }
//
//   Node min() {
//     if (root != null) {
//       return subtree_minimum(root);
//     } else {
//       return null;
//     }
//   }
//
//   void append(T key) {
//     Node z = new Node<>(key);
//     z.size = 1;
//     if (root == null) {
//       root = z;
//       return;
//     }
//     Node max = max();
//     splay(max);
//
//     max.right = z;
//     max.size += z.size;
//     z.parent = max;
//   }
//
//   static  InsertionOrderSplayTreeWithSize join(
//       Pair<InsertionOrderSplayTreeWithSize> trees) {
//     trees.first.join(trees.second);
//     return trees.first;
//   }
//
//   void join(InsertionOrderSplayTreeWithSize joiner) {
//     Node largest = max();
//     splay(largest);
//     if (root != null) {
//       root.right = joiner.root;
//       if (joiner.root != null) {
//         root.size += joiner.root.size;
//         joiner.root.parent = root;
//       }
//     } else {
//       root = joiner.root;
//     }
//   }
//
//   Node find(int k) {
//     return find(root, k);
//   }
//
//   Node find(Node node, int k) {
//     if (node == null) return null;
//     int pos = pos(node);
//
//     if (pos == k) {
//       return node;
//     }
//     if (pos < k) {
//       return find(node.right, k);
//     } else {
//       return find(node.left, k);
//     }
//   }
//
//   /**
//    * find key, make it the root, left children go in first tree, right children go in second tree.
//    * key is not in either tree
//    *
//    * @param tree
//    * @param key
//    * @param
//    * @return
//    */
//   static  Pair<InsertionOrderSplayTreeWithSize> split(
//       InsertionOrderSplayTreeWithSize tree, T key) {
//     InsertionOrderSplayTreeWithSize right = tree.split(key);
//     return Pair.of(tree, right);
//   }
//
//   InsertionOrderSplayTreeWithSize split(T key) {
//     // split off the right side of key
//     Node node = find(key);
//     if (node != null) {
//       splay(node); // so node will be root
//       System.err.println(printTree());
//       node.size -= size(node.right);
//       // root should be the found node
//       if (node.right != null) node.right.parent = null;
//
//       if (node.left != null) {
//         node.left.parent = null;
//       }
//       root = node.left;
//
//       InsertionOrderSplayTreeWithSize splitter =
//           InsertionOrderSplayTreeWithSize.create(node.right);
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
//   /**
//    * first position elements go in left tree, the rest go in right tree. No elements are missin
//    *
//    * @param tree
//    * @param position
//    * @param
//    * @return
//    */
//   static  Pair<InsertionOrderSplayTreeWithSize> split(
//       InsertionOrderSplayTreeWithSize tree, int position) {
//
//     InsertionOrderSplayTreeWithSize right = tree.split(position);
//
//     return Pair.of(tree, right);
//   }
//
//   InsertionOrderSplayTreeWithSize split(int position) {
//     Node found = find(position);
//     if (found != null) {
//       splay(found);
//       // split off the right side of key
//       if (found.right != null) {
//         found.right.parent = null;
//         found.size -= found.right.size;
//       }
//       InsertionOrderSplayTreeWithSize splitter =
//           InsertionOrderSplayTreeWithSize.create(found.right);
//       found.right = null;
//       splitter.validate();
//       validate();
//       // make sure that 'found' is still in this tree.
//       if (find(found) == null) {
//         throw new RuntimeException(
//             "Node " + found + " at position " + position + " was not still in tree");
//       }
//       return splitter;
//     }
//     return InsertionOrderSplayTreeWithSize
//         .create(); // return empty 'right' tree and leave tree alone
//   }
//
//   Node find(Node node) {
//     return find(root, node);
//   }
//
//   Node find(Node from, Node node) {
//     if (from == null) return null;
//     if (from == node) return from;
//     Node found = find(from.left, node);
//     if (found != null) {
//       return found;
//     } else {
//       found = find(from.right, node);
//       if (found != null) {
//         return found;
//       } else {
//         return null;
//       }
//     }
//   }
//
//   Node find(T key) {
//     return find(root, key);
//   }
//
//   Node find(Node from, T node) {
//     if (from == null) return null;
//     if (from != null && from.key.equals(node)) return from;
//     Node found = find(from.left, node);
//     if (found != null) {
//       return found;
//     } else {
//       found = find(from.right, node);
//       if (found != null) {
//         return found;
//       } else {
//         return null;
//       }
//     }
//   }
//
//   void erase(T key) {
//     Node z = find(key);
//     if (null == z) return;
//
//     splay(z);
//
//     if (null == z.left) replace(z, z.right);
//     else if (null == z.right) replace(z, z.left);
//     else {
//       Node y = subtree_minimum(z.right);
//       if (y.parent != z) {
//         replace(y, y.right);
//         y.right = z.right;
//         y.right.parent = y;
//       }
//       replace(z, y);
//       y.left = z.left;
//       y.left.parent = y;
//     }
//   }
//
//   int size() {
//     return root != null ? root.size : 0;
//   }
//
//   int height() {
//     return height(root);
//   }
//
//   static  int height(Node node) {
//     return node != null ? 1 + Math.max(height(node.left), height(node.right)) : 0;
//   }
//
//   boolean contains(Node element) {
//     return contains(root, element);
//   }
//
//   boolean contains(Node from, Node segment) {
//     if (from == null) return false;
//     if (from == segment) return true;
//     return contains(from.left, segment) || contains(from.right, segment);
//   }
//
//   boolean contains(T value) {
//     return contains(root, value);
//   }
//
//   boolean contains(Node from, T value) {
//     if (from == null) return false;
//     if (from.key == value) return true;
//     return contains(from.left, value) || contains(from.right, value);
//   }
//
//   String printTree() {
//     return printTree(root, 0);
//   }
//
//   String printTree(Node node, int d) {
//     StringBuilder builder = new StringBuilder();
//     int i;
//     if (node == null) return "";
//     builder.append(printTree(node.right, d + 1));
//     for (i = 0; i < d; i++) builder.append("  ");
//     builder.append(node.key + "(" + node.size + ")\n");
//     builder.append(printTree(node.left, d + 1));
//     return builder.toString();
//   }
//
//   String printTree(String note) {
//     return note + "\n" + printTree(root, 0);
//   }
//
//   void validate() {
//     if (log.isTraceEnabled()) {
//       // root parent is null
//       if (root != null) {
//         if (root.parent != null) {
//           throw new RuntimeException("root parent is not null");
//         }
//         root.validate();
//         validateChild(root.left);
//         validateChild(root.right);
//       }
//     }
//   }
//
//   void validateChild(Node node) {
//     if (node != null) {
//       node.validate();
//       if (node.parent == null) {
//         throw new RuntimeException("child " + node.key + " has null parent");
//       }
//       if (node.size != node.count()) {
//         throw new RuntimeException("size of " + node.key + " does not match count");
//       }
//       validateChild(node.left);
//       validateChild(node.right);
//     }
//   }
//
//   static class Iterator<V> implements java.util.Iterator<Node<V>> {
//
//     Node<V> next;
//     Set<Node<V>> elements = new LinkedHashSet<>();
//
//     Iterator(Node<V> root) {
//       this.next = root;
//       if (next == null) return;
//
//       while (next.left != null) {
//         if (elements.contains(next.left)) {
//           throw new RuntimeException("duplicate elements");
//         }
//         elements.add(next.left);
//         next = next.left;
//       }
//     }
//
//     @Override
//     boolean hasNext() {
//       return next != null;
//     }
//
//     @Override
//     Node<V> next() {
//       if (!hasNext()) throw new NoSuchElementException();
//       Node<V> r = next;
//
//       // If you can walk right, walk right, then fully left.
//       // otherwise, walk up until you come from left.
//       if (next.right != null) {
//         next = next.right;
//         while (next.left != null) next = next.left;
//         return r;
//       }
//
//       while (true) {
//         if (next.parent == null) {
//           next = null;
//           return r;
//         }
//         if (next.parent.left == next) {
//           next = next.parent;
//           return r;
//         }
//         next = next.parent;
//       }
//     }
//   }
//
//   String toString() {
//     StringBuilder buf = new StringBuilder();
//     for (Iterator iterator = new Iterator(root); iterator.hasNext(); ) {
//       Node node = iterator.next();
//       buf.append(node.toString());
//       buf.append("\n");
//     }
//     return buf.toString();
//   }
// }

/// node value type T
class _SplayTreeNode<T> {
  T value;
  int count = 0, weight;
  _SplayTreeNode<T>? parent, left, right;

  // _SplayTreeNode.empty();

  _SplayTreeNode(this.value, this.weight, [this.parent, this.left, this.right]);
}

/// node value type T
class SplayTreeIterator<T> extends Iterator<T> {
  _SplayTreeNode<T>? _current;

  SplayTreeIterator(this._current);

  @override
  bool moveNext() {
    if (_current == null) return false;
    if (_current!.right != null) {
      _current = _current!.right;
      while (_current!.left != null) {
        _current = _current!.left;
      }
      return true;
    }
    while (_current!.parent?.right == _current) {
      _current = _current!.parent;
    }
    _current = _current!.parent;
    return _current != null;
  }

  bool moveBack() {
    if (_current == null) return false;
    if (_current!.left != null) {
      _current = _current!.left;
      while (_current!.right != null) {
        _current = _current!.right;
      }
      return true;
    }
    while (_current!.parent?.left == _current) {
      _current = _current!.parent;
    }
    _current = _current!.parent;
    return _current != null;
  }

  @override
  T get current => _current!.value;

  set current(T value) {
    _current?.value = value;
  }

  int? get weight => _current?.weight;

  int? get count => _current?.count;
}

typedef CompareFunc = bool Function(int a, int b);

/// node value type T
/// update value type U
///
/// Custom Splay Tree for Piece Table
/// It can be used as normal
/// @see splay_tree_test.dart
abstract class SplayTree<T> {
  final CompareFunc _compareFunc;

  int _len = 0;

  int get length => _len;
  _SplayTreeNode<T>? _root;

  SplayTree(this._compareFunc) {
    _len = 0;
  }

  /// update the `update` value
  /// `n` can be null
  void _updateNode(_SplayTreeNode<T>? n) {
    n?.count =
        (n.left?.count ?? 0) + (n.right?.count ?? 0) + (n.weight);
  }

  /// Left Rotation
  ///
  ///   p            p
  ///   |            |
  ///   n            a
  ///  / \    =>    / \
  /// x   a        n   y
  ///    / \      / \
  ///   b   y    x   b
  ///
  /// Assertion: `a` is not null
  void _leftRotation(_SplayTreeNode<T>? n) {
    var a = n!.right, b = a!.left, p = n.parent;
    n.right = b;
    a.left = n;
    p?.left == n ? p?.left = a : p?.right = a;
    a.parent = p;
    n.parent = a;
    b?.parent = n;

    _updateNode(a);
    _updateNode(n);
  }

  /// Right Rotation
  ///
  ///     p        p
  ///     |        |
  ///     n        a
  ///    / \  =>  / \
  ///   a   y    x   n
  ///  / \          / \
  /// x   b        b   y
  ///
  /// Assertion: `a` is not null
  void _rightRotation(_SplayTreeNode<T>? n) {
    var a = n!.left, b = a!.right, p = n.parent;
    n.left = b;
    a.right = n;
    p?.left == n ? p?.left = a : p?.right = a;
    a.parent = p;
    n.parent = a;
    b?.parent = n;

    _updateNode(a);
    _updateNode(n);
  }

  /// Splay operation
  /// It makes the node to the root
  ///
  /// 1. Zig step
  ///
  ///     p        n     |   p            n
  ///    / \      / \    |  / \          / \
  ///   n   C => A   p   | A   n   =>   p   C
  ///  / \          / \  |    / \      / \
  /// A   B        B   C |   B   C    A   B
  ///
  ///
  /// 2. Zig-zig step
  ///
  ///       q        n       |   q                n
  ///      / \      / \      |  / \              / \
  ///     p   D    A   p     | A   p            p   D
  ///    / \    =>    / \    |    / \    =>    / \
  ///   n   C        B   q   |   B   n        q   C
  ///  / \              / \  |      / \      / \
  /// A   B            C   D |     C   D    A   B
  ///
  ///
  /// 3. Zig-zag step
  ///
  ///     q                    |   q
  ///    / \           n       |  / \             n
  ///   p   D        /   \     | A   p          /   \
  ///  / \    =>   p       q   |    / \  =>   q       p
  /// A   n       / \     / \  |   n   D     / \     / \
  ///    / \     A   B   C   D |  / \       A   B   C   D
  ///   B   C                  | B   C
  ///
  void _splay(_SplayTreeNode<T>? n) {
    while (n!.parent != null) {
      if (n.parent!.parent == null) {
        // Zig step
        n.parent!.left == n ? _rightRotation(n.parent) : null;
      } else if (n.parent!.left == n && n.parent!.parent!.left == n.parent) {
        // Zig-zig step (left)
        _rightRotation(n.parent!.parent);
        _rightRotation(n.parent);
      } else if (n.parent!.right == n && n.parent!.parent!.right == n.parent) {
        // Zig-zig step (right)
        _leftRotation(n.parent!.parent);
        _leftRotation(n.parent);
      } else if (n.parent!.right == n) {
        // Zig-zag step (left)
        _leftRotation(n.parent);
        _rightRotation(n.parent);
      } else {
        // Zig-zag step (right)
        _rightRotation(n.parent);
        _leftRotation(n.parent);
      }
    }
    _root = n;
  }

  _SplayTreeNode<T>? _minimum(_SplayTreeNode<T>? n) {
    while (n?.left != null) {
      n = n?.left;
    }
    return n;
  }

  _SplayTreeNode<T>? _maximum(_SplayTreeNode<T>? n) {
    while (n?.right != null) {
      n = n?.right;
    }
    return n;
  }

  /// max node that `node <= value`
  _SplayTreeNode<T>? _lowerBound(int value) {
    if (_len == 0) return null;
    var n = _root;
    _SplayTreeNode<T>? r;
    while (true) {
      if (_compareFunc(value, n!.left?.count ?? 0)) {
        if (n.left == null) break;
        n = n.left;
      } else {
        r = n;
        if (n.right == null) break;
        value -= (n.left?.count ?? 0) + n.count;
        n = n.right;
      }
    }
    return r;
  }

  /// min node that `node >= value`
  _SplayTreeNode<T>? _upperBound(int value) {
    if (_len == 0) return null;
    var n = _root;
    _SplayTreeNode<T>? r;
    while (true) {
      if (_compareFunc(n!.left?.count ?? 0, value)) {
        r = n;
        if (n.right == null) break;
        value -= (n.left?.count ?? 0) + n.count;
        n = n.right;
      } else {
        if (n.left == null) break;
        n = n.left;
      }
    }
    return r;
  }

  /// finds the value
  /// if not returns null
  _SplayTreeNode<T>? _find(int value) {
    if (_len == 0) return null;
    var n = _root;
    while (n != null) {
      if (n.count == value) {
        _splay(n);
        return n;
      }
      if (_compareFunc(value, n.left?.count ?? 0)) {
        n = n.left;
      } else {
        value -= (n.left?.count ?? 0) + n.count;
        n = n.right;
      }
    }
    return n;
  }

  /// This Splay tree finds the location to insert
  /// by position of tree (not comparing elements)
  SplayTreeIterator<T> insert(T value, int weight, int position) {
    if (_len == 0) {
      _len = 1;
      _root = _SplayTreeNode<T>(value, weight);
      _updateNode(_root);
      return SplayTreeIterator<T>(_root);
    }
    var n = _root;
    var a = _SplayTreeNode<T>(value, weight);
    while (true) {
      if (_compareFunc(position, n!.left?.count ?? 0)) {
        if (n.left == null) {
          n.left = a;
          break;
        }
        n = n.left;
      } else {
        if (n.right == null) {
          n.right = a;
          break;
        }
        position -= (n.left?.count ?? 0) + n.count;
        n = n.right;
      }
    }
    a.parent = n;
    for (var i = a; i != null; i = i.parent!) {
      _updateNode(i);
    }
    _splay(a);
    _len++;

    return SplayTreeIterator<T>(a);
  }

  void erase(SplayTreeIterator<T> iterator) {
    if (_len == 0) throw 'remove called when size is 0';
    if (iterator._current == null) throw 'removing null';
    if (_len == 1) {
      _len = 0;
      _root = null;
      return;
    }
    var n = iterator._current;
    _splay(n!);
    var t = _minimum(n.right);
    if (t == null) {
      _root = n.left;
      _root!.parent = null;
      n.left = null;
      _len--;
      return;
    }

    n.value = t.value;

    var p = t.parent;
    p?.left == t ? p?.left = t.right : p?.right = t.right;
    t.right?.parent = p;
    t.parent = null;
    t.right = null;

    for (var i = p; i != null; i = i.parent) {
      _updateNode(i);
    }
    _len--;
  }

  void append(T value) {
    if (_len == 0) {
      _len = 1;
      _root = _SplayTreeNode<T>(value, 1);
      _updateNode(_root);
      return;
    }

  }

  // /   void append(T key) {
//     Node z = new Node<>(key);
//     z.size = 1;
//     if (root == null) {
//       root = z;
//       return;
//     }
//     Node max = max();
//     splay(max);
//
//     max.right = z;
//     max.size += z.size;
//     z.parent = max;
//   }


  //   void erase(T key) {
//     Node z = find(key);
//     if (null == z) return;
//
//     splay(z);
//
//     if (null == z.left) replace(z, z.right);
//     else if (null == z.right) replace(z, z.left);
//     else {
//       Node y = subtree_minimum(z.right);
//       if (y.parent != z) {
//         replace(y, y.right);
//         y.right = z.right;
//         y.right.parent = y;
//       }
//       replace(z, y);
//       y.left = z.left;
//       y.left.parent = y;
//     }
//   }
//


  void updateNode(SplayTreeIterator<T> iterator, {T? value, int? weight}) {
    if (iterator._current == null) throw 'updating null';
    if (value == null && weight == null) throw 'new values are null';
    var n = iterator._current;
    if (value != null) {
      n!.value = value;
    }
    if (weight != null) {
      _splay(n);
      n!.weight = weight;
      _updateNode(n);
    }
  }

  int splayPosition(SplayTreeIterator<T> iterator) {
    if (iterator._current == null) throw 'removing null';
    var n = iterator._current;
    _splay(n);
    return n!.left?.count ?? 0;
  }

  SplayTreeIterator<T> lower_bound(int value) {
    return SplayTreeIterator<T>(_lowerBound(value));
  }

  SplayTreeIterator<T> upper_bound(int value) {
    return SplayTreeIterator<T>(_upperBound(value));
  }

  SplayTreeIterator<T> find(int value) {
    return SplayTreeIterator<T>(_find(value));
  }

  SplayTreeIterator<T> get begin => SplayTreeIterator<T>(_minimum(_root));

  SplayTreeIterator<T> get end => SplayTreeIterator<T>(null);

  SplayTreeIterator<T> get front => begin;

  SplayTreeIterator<T> get back => SplayTreeIterator<T>(_maximum(_root));
}