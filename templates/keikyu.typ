// This is the Keikyu template.
#let required-params = (
  station-name: (
    type: "string",
    default: "笑川海岸",
  ),
  hiragana: (
    type: "string",
    default: "わらかわかいがん",
  ),
  romaji: (
    type: "string",
    default: "Warakawakaigan",
  ),
  station-id: (
    type: "string",
    default: "07",
  ),
  chinese: (
    type: "string",
    default: "笑川海岸",
  ),
  korean: (
    type: "string",
    default: "오모리카이간역",
  ),
  previous-station-name: (
    type: "string",
    default: "平和島",
  ),
  previous-station-romaji: (
    type: "string",
    default: "Heiwajima",
  ),
  next-station-name: (
    type: "string",
    default: "笑会川",
  ),
  next-station-romaji: (
    type: "string",
    default: "Waraaigawa",
  ),
  next-station-id: (
    type: "string",
    default: "06",
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

#let kk-bg-fill = blue.mix(navy)
#let kk-fill = aqua.mix((blue, 30%))
#let kk-sign(index: 11, width: 10em) = {
  let factor = .85
  set text(fill: kk-bg-fill)
  box(radius: 99999em, width: width, height: width, fill: kk-fill, place(
    center + horizon,
    box(
      radius: 99999em,
      fill: white,
      width: width * factor,
      height: width * factor,
      layout(size => {
        let u = size.width
        place(center + horizon, dy: -u / 4, text(
          size: u / 3,
          weight: "medium",
        )[KK])
        place(center + horizon, dy: u / 6, text(
          size: u / 1.9,
          weight: "semibold",
        )[#index])
      }),
    ),
  ))
}

#set page(
  width: 10cm * 2,
  height: 3cm * 2,
  fill: kk-bg-fill,
  margin: 0cm,
)

#set text(fill: white, font: "Noto Sans CJK JP", weight: "black")

#place(
  top,
  dx: .4cm,
  dy: .4cm,
  text(font: "Inria Sans", size: .5cm, stroke: 1pt + white)[PUMP ELEPHANT],
)

#grid(
  stroke: white + .1pt,
  columns: 1fr,
  rows: (1fr, 4.2%, 2.9%, 25%),
  {
    grid(
      rows: (1cm, 1fr, 1cm),
      columns: 1fr,
      align: center + horizon,
      text(size: .7cm, tracking: .1cm)[#params.hiragana],
      {
        place(center + horizon, dx: -6.4cm, kk-sign(index: params.station-id, width: 2cm))
        text(size: 2cm)[#params.station-name]
      },
      {
        set text(size: .7cm)
        text()[#params.romaji]
        h(.5cm)
        text(font: "Noto Sans CJK SC", weight: "medium")[#params.chinese]
        h(.5cm)
        text(font: "Noto Sans CJK KR", weight: "medium")[#params.korean]
      }
    )
  },
  grid.cell(fill: kk-fill)[],
  grid.cell(fill: white)[],
  {
    place(left + horizon, dx: .7cm, grid(
      rows: 2,
      gutter: .2cm,
      text(size: .55cm)[#params.previous-station-name],
      text(size: .45cm)[#params.previous-station-romaji],
    ))
    place(right + horizon, dx: -.5cm, {
      grid(
        rows: 2,
        columns: 2,
        gutter: .2cm,
        align: left,
        grid.cell(rowspan: 2, place(right + horizon, kk-sign(
          width: 1.1cm,
          index: params.next-station-id,
        ))),
        text(size: .55cm)[#params.next-station-name],
        text(size: .45cm)[#params.next-station-romaji],
      )
    })
    let dot(unit, ..args) = args.pos().map(it => it * unit)
    let u = dot.with(.18cm)
    place(center + horizon, curve(
      fill: white,
      curve.line(u(.3 + 1, 0)),
      curve.line(u(.3 + 3.5, 2.5)),
      curve.line(u(.3 + 1, 5)),
      curve.line(u(0, 5)),
      curve.line(u(2, 3)),
      curve.line(u(-2, 3)),
      curve.line(u(-2, 2)),
      curve.line(u(2, 2)),
    ))
  }
)
