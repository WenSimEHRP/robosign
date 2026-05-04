#let required-params = (
  field-1: (
    type: "enum",
    default: (
      simple: (
        station-names: "阿鲁科尔沁旗 齐齐哈尔",
        departure-station-pinyin: "TOO LONG TO FIT IN",
      ),
    ),
    variations: (
      simple: (
        station-names: (
          type: "string",
          default: "阿鲁科尔沁旗 齐齐哈尔",
        ),
        departure-station-pinyin: (
          type: "string",
          default: "TOO LONG TO FIT IN",
        ),
      ),
      complex: (
        station-name-1: (
          type: "string",
          default: "温州",
        ),
        station-name-2: (
          type: "string",
          default: "都灵",
        ),
        class: (
          type: "string",
          default: "高速",
        ),
        trips-top: (
          type: "string",
          default: "G1234",
        ),
        trips-bottom: (
          type: "string",
          default: "G1235",
        ),
      ),
    ),
  ),
  field-2: (
    type: "enum",
    default: (
      complex: (
        station-name-1: "温州",
        station-name-2: "都灵",
        class: "高速",
        trips-top: "G1234",
        trips-bottom: "G1235",
      ),
    ),
    variations: (
      simple: (
        station-names: (
          type: "string",
          default: "北京北 太平洋中央车站",
        ),
        departure-station-pinyin: (
          type: "string",
          default: "TOO LONG TO FIT IN",
        ),
      ),
      complex: (
        station-name-1: (
          type: "string",
          default: "温州",
        ),
        station-name-2: (
          type: "string",
          default: "都灵",
        ),
        class: (
          type: "string",
          default: "高速",
        ),
        trips-top: (
          type: "string",
          default: "G1234",
        ),
        trips-bottom: (
          type: "string",
          default: "G1235",
        ),
      ),
    ),
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
  published: "2026-05-03",
)) <template_data>


#let insert-path(dict, path, value) = {
  let key = path.at(0)
  if path.len() == 1 {
    dict.insert(key, value)
  } else {
    let rest = path.slice(1)
    let sub-dict = if key in dict and dict.at(key) != none {
      dict.at(key)
    } else {
      (:)
    }
    if type(sub-dict) != dictionary {
      panic("Key collision: '" + key + "' is a value (" + str(sub-dict) + "), cannot become a branch.")
    }
    dict.insert(key, insert-path(sub-dict, rest, value))
  }
  return dict
}

#let params = {
  let res = sys.inputs.at("params", default: none)
  if res == none {
    required-params.pairs().map(((k, v)) => (k, v.default)).to-dict()
  } else {
    let new_tree = (:)
    for (key, val) in json(bytes(res)) {
      let hierarchy = key.split("::")
      new_tree = insert-path(new_tree, hierarchy, val)
    }
    new_tree
  }
}

#set page(
  fill: white,
  height: auto,
  width: auto,
  margin: 0cm,
)

#let serif-text = text.with(font: "Noto Serif SC")
#let sans-text = text.with(font: "Noto Sans CJK SC")

#let format-text(station-names) = context {
  let stations = station-names.split(regex("\s+"))
  grid(
    rows: (1fr,) * stations.len(),
    ..stations.map(it => layout(size => {
      let u = measure(serif-text(
        size: 2.8cm,
        weight: "black",
        it,
      ))
      scale(
        reflow: true,
        x: calc.min(100%, size.width / u.width * 100%),
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
    }))
  )
}

#let station-text(s) = context {
  grid(
    columns: (1fr,),
    rows: (1fr, 1.5cm, 4.4mm),
    {
      if s.at("simple", default: none) == none {
        let info = s.complex
        grid(
          rows: 1fr,
          columns: (1fr, auto, 1fr),
          place(center + bottom, dy: -.6cm, format-text(s.complex.station-name-1)),
          grid.cell(inset: .7cm)[
            #align(
              center + horizon,
              move(dy: .5cm, box(width: 2.5cm, stroke: 3pt, {
                place(center + bottom, dy: -.2cm, sans-text(size: .5cm, s.complex.trips-top))
                place(center + top, dy: .2cm, sans-text(size: .5cm, s.complex.trips-bottom))
              })),
            )
            #place(center + top, dy: .1cm, scale(reflow: true, y: 80%, box(width: 999em, sans-text(
              size: 0.8cm,
              tracking: .7cm,
              params.class,
            ))))
          ],
          place(center + bottom, dy: -.6cm, format-text(s.complex.station-name-2)),
        )
      } else {
        place(center + bottom, dy: -.6cm, box(height: 3cm, width: 9cm, format-text(s.simple.station-names)))
      }
    },
    grid.cell(align: center + horizon, fill: eval(params.color), {
      if s.at("simple", default: none) == none {} else {
        serif-text(
          weight: "black",
          size: 1cm,
          fill: white,
          s.simple.departure-station-pinyin,
        )
      }
    }),
    [],
  )
}

#let has-complex = (params.field-1.at("simple", default: none), params.field-2.at("simple", default: none)).any(it => (
  it == none
))
#let grid-width = if has-complex { 13cm } else { 11.5cm }

#box(inset: .5cm, grid(
  columns: (
    grid-width,
    7cm,
    grid-width,
  ),
  rows: (6cm,),
  station-text(params.field-1),
  {
    place(center + top, dy: .5cm, scale(y: 80%, sans-text(
      size: 1.1cm,
      tracking: 3.8cm,
      params.class,
    )))
    place(center + top, dy: .5cm, rect(stroke: none, width: 4cm, inset: 0cm, image("./logo.svg")))
    let trip-numbers = params.trips.trim().split(regex("\s+"))
    place(center + bottom, dy: -.2cm, box(
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
  },
  station-text(params.field-2),
))
