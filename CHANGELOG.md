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
