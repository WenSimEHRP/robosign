#let required-params = (
  departure-station: (
    type: "string",
    default: "阿鲁科尔沁旗 齐齐哈尔",
  ),
  departure-station-pinyin: (
    type: "string",
    default: "SHANGHAI",
  ),
  destination-station: (
    type: "string",
    default: "北京北 太平洋中央车站",
  ),
  destination-station-pinyin: (
    type: "string",
    default: "BEIJING",
  ),
  class: (
    type: "string",
    default: "动检",
  ),
  trips: (
    type: "string",
    default: "DJ1145 1919/20 6767 6969",
  ),
  color: (
    type: "string",
    default: "rgb(\"#DBB44B\")",
  ),
)

#metadata((
  fonts: ("Noto Sans CJK SC", "Noto Serif SC"),
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
  fill: white,
  height: 6cm,
  width: 30cm,
  margin: 0cm,
)

#let serif-text = text.with(font: "Noto Serif SC")
#let sans-text = text.with(font: "Noto Sans CJK SC")

#let station-text(s) = context {
  let stations = s.split(regex("\s+"))
  let max-height = 3cm
  place(center + bottom, dy: -.6cm, box(height: 3cm, width: 9cm, grid(
    rows: (1fr,) * stations.len(),
    ..stations.map(it => {
      let u = measure(serif-text(
        size: 2.8cm,
        weight: "black",
        it,
      ))
      scale(
        reflow: true,
        x: calc.min(100%, 9cm / u.width * 100%),
        y: 100% / stations.len(),
        it
          .clusters()
          .map(char => serif-text(
            size: 2.8cm,
            weight: "black",
            char,
          ))
          .intersperse(h(1fr))
          .join(),
      )
    })
  )))
}

#grid(
  columns: (1fr, 7cm, 1fr),
  rows: (1fr, 1.5cm, 4.5mm),
  station-text(params.departure-station),
  grid.cell(rowspan: 2)[
    #place(center + top, dy: .5cm, scale(y: 80%, sans-text(
      size: 1.1cm,
      tracking: 3.8cm,
      params.class,
    )))
    #place(center + top, dy: .5cm, rect(stroke: none, width: 4cm, inset: 0cm, image("./logo.svg")))
    #let trip-numbers = params.trips.trim().split(regex("\s+"))
    #place(center + bottom, dy: .1cm, box(
      width: 6cm,
      {
        set align(center)
        set par(leading: 2mm)
        trip-numbers
          .map(it => box(scale(reflow: true, y: 80%, sans-text(size: .7cm, it))))
          .intersperse(h(.8em, weak: true))
          .join()
      },
    ))
  ],
  station-text(params.destination-station),
  grid.cell(fill: eval(params.color), align: center + horizon, serif-text(
    weight: "black",
    size: 1cm,
    fill: white,
  )[
    #params.departure-station-pinyin
  ]),
  grid.cell(fill: eval(params.color), align: center + horizon, serif-text(
    weight: "black",
    size: 1cm,
    fill: white,
  )[
    #params.destination-station-pinyin
  ]),
)
