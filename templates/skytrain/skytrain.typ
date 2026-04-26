#let required-params = (
  station-name: (
    type: "string",
    default: "YVR-Airport Station",
  ),
)
#metadata((
  fonts: ("fira sans",),
  authors: (
    (name: "Jeremy Gao", ref: "https://paiagram.com"),
  ),
  params: required-params,
  published: "2026-04-25",
)) <template_data>

#let params = {
  let res = sys.inputs.at("params", default: none)
  if res == none {
    required-params.pairs().map(((k, v)) => (k, v.default)).to-dict()
  } else {
    json(bytes(res))
  }
}

#set page(
  height: 1in,
  width: auto,
  margin: 0cm,
  fill: navy,
)

#set text(size: .7in, font: "fira sans", weight: "bold", fill: white)
#set align(center + horizon)
#stack(dir: ltr, square(height: 100%, stroke: none, fill: blue, inset: 0cm, image("./t.svg")), [
  #h(2em)
  #params.station-name
  #h(2em)
])

#place(
  right + bottom,
  dx: -5pt,
  dy: -5pt,
  {
    let img = image(bytes(read("./translink.svg").replace(regex("fill=\"#[0-9A-F]{6}\""), "fill=\"#FFFFFF\"")))
    box(width: .5in, img)
  },
)
