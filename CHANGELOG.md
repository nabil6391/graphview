## 1.5.1
- Fix Zoom To fit for hidden nodes
- Add Fade in Support for Edges

## 1.5.0

- **MAJOR UPDATE**: Added 5 new layout algorithms
    - BalloonLayoutAlgorithm: Radial tree layout with circular child arrangements around parents
    - CircleLayoutAlgorithm: Arranges nodes in circular formations with edge crossing reduction
    - RadialTreeLayoutAlgorithm: Converts tree structures to polar coordinate system
    - TidierTreeLayoutAlgorithm: Improved tree layout with better spacing and positioning
    - MindmapAlgorithm: Specialized layout for mindmap-style distributions
- **NEW**: Node expand/collapse functionality with GraphViewController
    - `collapseNode()`, `expandNode()`, `toggleNodeExpanded()` methods
    - Hierarchical visibility control with animated transitions
    - Initial collapsed state support via `setInitiallyCollapsedNodes()`
- **NEW**: Advanced animation system
    - Smooth expand/collapse animations with customizable duration
    - Node scaling and opacity transitions during state changes
    - `toggleAnimationDuration` parameter for fine-tuning animations
- **NEW**: Enhanced GraphView.builder constructor
    - `animated`: Enable/disable smooth animations (default: true)
    - `autoZoomToFit`: Automatically zoom to fit all nodes on initialization
    - `initialNode`: Jump to specific node on startup
    - `panAnimationDuration`: Customizable navigation movement timing
    - `centerGraph`: Center the graph within viewport having a fixed large size of 2000000
    - `controller`: GraphViewController for programmatic control
- **NEW**: Navigation and pan control features
    - `jumpToNode()` and `animateToNode()` for programmatic navigation
    - `zoomToFit()` for automatic viewport adjustment
    - `resetView()` for returning to origin
    - `forceRecalculation()` for layout updates
- **IMPROVED** TreeEdgeRenderer with curved/straight connection options
- **IMPROVED**: Better performance with caching for graphs
- **IMPROVED**: Sugiyama Algorithm with postStraighten and additional strategies

## 1.2.0

- Resolved Overlaping for Sugiyama Algorithm (#56, #93, #87)
- Added Enum for Coordinate Assignment in Sugiyama : DownRight, DownLeft, UpRight, UpLeft, Average(Default)

## 1.1.1

- Fixed bug for SugiyamaAlgorithm where horizontal placement was overlapping
- Buchheim Algorithm Performance Improvements

## 1.1.0

- Massive Sugiyama Algorithm Performance Improvements! (5x times faster)
- Encourage usage of Node.id(int) for better performance
- Added tests to better check regressions

## 1.0.0

- Full Null Safety Support
- Sugiyama Algorithm Performance Improvements
- Sugiyama Algorithm TOP_BOTTOM Height Issue Solved (#48)

## 1.0.0-nullsafety.0

- Null Safety Support

## 0.7.0

- Added methods for builder pattern and deprecated directly setting Widget Data in nodes.

## 0.6.7

- Fix rect value not being set in FruchtermanReingoldAlgorithm (#27)

## 0.6.6

- Fix Index out of range for Sugiyama Algorithm (#20)

## 0.6.5

- Fix edge coloring not picked up by TreeEdgeRenderer (#15)
- Added Orientation Support in Sugiyama Configuration (#6)

## 0.6.1

- Fix coloring not happening for the whole graphview
- Fix coloring for sugiyama and tree edge render
- Use interactive viewer correctly to make the view constrained

## 0.6.0

- Add coloring to individual edges. Applicable for ArrowEdgeRenderer
- Add example for focused node for Force Directed Graph. It also showcases dynamic update

## 0.5.1

- Fix a bug where the paint was not applied after setstate.
- Proper Key validation to match Nodes and Edges

## 0.5.0

- Minor Breaking change. We now pass edge renderers as part of Layout
- Added Layered Graph (SugiyamaAlgorithm)
- Added Paint Object to change color and stroke parameters of the edges easily
- Fixed a bug where by onTap in GestureDetector and Inkwell was not working

## 0.1.2

- Used part of library properly. Now we can only implement single graphview

## 0.1.0

- Initial release.