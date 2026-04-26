// This is the minimal template.
#let required-params = (
  station-name: (
    type: "string",
    default: "Waterfront",
  ),
)
#context [#metadata((
  // Fonts are detect automatically via this line of code
  fonts: query(<font>).map(it => it.value).dedup(),
  // Authors. The ref field is optional
  authors: (
    (name: "Jeremy Gao", ref: "https://paiagram.com"),
  ),
  params: required-params,
  published: "2026-04-25",
)) <template_data>]

#let params = {
  let res = sys.inputs.at("params", default: none)
  if res == none {
    required-params.pairs().map(((k, v)) => (k, v.default)).to-dict()
  } else {
    json(bytes(res))
  }
}

#show text: it => context {
  [#metadata(text.font) <font>]
  it
}

#set page(
  width: 10in,
  height: 3in,
  fill: white,
)

#set text(size: .3in, lang: "en", font: "Fira Sans")

#place(top + center)[
  This is the minimal template

  Canada Line, Expo Line, SeaBus, \ West Coast Express

  #text(size: 2em, weight: "black", params.station-name)
]
